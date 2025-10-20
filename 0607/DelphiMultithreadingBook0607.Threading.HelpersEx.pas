unit DelphiMultithreadingBook0607.Threading.HelpersEx;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  System.Threading,
  Winapi.Windows,
  DelphiMultithreadingBook0403.CancellationToken;

type
  /// <summary>
  /// Exceção customizada para operações que excedem o tempo limite
  /// </summary>
  ETimeoutException = class(Exception)
  public
    /// <summary>
    /// Cria uma nova instância de ETimeoutException com mensagem padrão
    /// </summary>
    constructor Create; reintroduce;
  end;

  /// <summary>
  /// Opções para execução de continuações
  /// </summary>
  TContinuationOption = (
    /// <summary>Executa apenas quando NÃO completado</summary>
    NotOnCompleted,
    /// <summary>Executa apenas quando completado com sucesso</summary>
    OnlyOnCompleted,
    /// <summary>Executa apenas quando falhou</summary>
    OnlyOnFaulted,
    /// <summary>Executa apenas quando cancelado</summary>
    OnlyOnCanceled
  );

  // Forward declarations
  TFutureEx<T> = class;
  TTaskEx = class;

  /// <summary>
  /// Delegate para manipular conclusão de Future com valor
  /// </summary>
  /// <typeparam name="T">Tipo do valor retornado</typeparam>
  /// <param name="Value">Valor resultante</param>
  TFutureCompleteHandler<T> = reference to procedure(const Value: T);

  /// <summary>
  /// Delegate para manipular conclusão de Task sem valor
  /// </summary>
  TTaskCompleteHandler = reference to procedure();

  /// <summary>
  /// Delegate para manipular exceções
  /// </summary>
  /// <param name="Exception">Objeto de exceção</param>
  TExceptionHandler = reference to procedure(const Exception: Exception);

  /// <summary>
  /// Delegate para continuação de Future
  /// </summary>
  /// <typeparam name="T">Tipo do valor</typeparam>
  /// <param name="Future">Instância da Future completada</param>
  TFutureContinuationProc<T> = reference to procedure(const Future: TFutureEx<T>);

  /// <summary>
  /// Delegate para continuação de Task
  /// </summary>
  /// <param name="Task">Instância da Task completada</param>
  TTaskContinuationProc = reference to procedure(const Task: TTaskEx);

  /// <summary>
  /// Delegate para transformação de valores
  /// </summary>
  /// <typeparam name="T">Tipo de entrada</typeparam>
  /// <typeparam name="TResult">Tipo de resultado</typeparam>
  /// <param name="Value">Valor a ser transformado</param>
  /// <returns>Valor transformado</returns>
  TTransformFunc<T, TResult> = reference to function(const Value: T): TResult;

  /// <summary>
  /// Classe base abstrata para operações assíncronas com suporte a sincronização
  /// </summary>
  TAsyncOperation = class abstract
  private
    FSyncThread: TThread;
  protected
    /// <summary>
    /// Enfileira um procedimento para execução na thread de sincronização
    /// </summary>
    procedure QueueSync(Proc: TThreadProcedure);
  public
    /// <summary>
    /// Cria uma nova instância capturando a thread atual como thread de sincronização
    /// </summary>
    constructor Create; virtual;

    /// <summary>
    /// Define a thread para sincronização de callbacks
    /// </summary>
    /// <param name="AThread">Thread alvo para sincronização (nil para main thread)</param>
    /// <returns>Self para encadeamento</returns>
    function WithSyncThread(AThread: TThread): TAsyncOperation;
  end;

  /// <summary>
  /// Classe extendida para operações assíncronas sem retorno de valor (Task)
  /// </summary>
  TTaskEx = class(TAsyncOperation)
  private
    FTask: ITask;
    FOnComplete: TTaskCompleteHandler;
    FOnException: TExceptionHandler;
    FTimeout: Cardinal;
    FCancellationToken: ICancellationToken;
    FError: Exception;
    function GetStatus: TTaskStatus;
    procedure HandleCompletion;
    procedure CaptureException;
  public
    /// <summary>
    /// Cria uma nova instância de TTaskEx
    /// </summary>
    /// <param name="ATask">Task a ser encapsulada</param>
    /// <param name="ATimeout">Tempo limite em milissegundos (INFINITE para sem timeout)</param>
    /// <param name="AToken">Token para cancelamento cooperativo</param>
    constructor Create(const ATask: ITask; ATimeout: Cardinal = INFINITE;
      const AToken: ICancellationToken = nil); reintroduce;

    /// <summary>
    /// Destruidor que libera recursos
    /// </summary>
    destructor Destroy; override;

    /// <summary>
    /// Define o callback para conclusão bem-sucedida
    /// </summary>
    /// <param name="AHandler">Procedimento a ser executado</param>
    /// <returns>Self para encadeamento</returns>
    function OnComplete(AHandler: TTaskCompleteHandler): TTaskEx;

    /// <summary>
    /// Define o callback para tratamento de exceções
    /// </summary>
    /// <param name="AHandler">Procedimento a ser executado</param>
    /// <returns>Self para encadeamento</returns>
    function OnException(AHandler: TExceptionHandler): TTaskEx;

    /// <summary>
    /// Adiciona uma continuação que será executada quando a task completar
    /// </summary>
    /// <param name="AProc">Procedimento de continuação</param>
    /// <param name="AOption">Condição para execução</param>
    /// <returns>Nova task que representa a continuação</returns>
    function ContinueWith(AProc: TTaskContinuationProc;
      AOption: TContinuationOption = OnlyOnCompleted): TTaskEx;

    /// <summary>
    /// Define um tempo limite para a operação
    /// </summary>
    /// <param name="ATimeout">Tempo em milissegundos</param>
    /// <returns>Self para encadeamento</returns>
    function WithTimeout(ATimeout: Cardinal): TTaskEx;

    /// <summary>
    /// Define um token para cancelamento cooperativo
    /// </summary>
    /// <param name="AToken">Token de cancelamento</param>
    /// <returns>Self para encadeamento</returns>
    function WithCancellation(const AToken: ICancellationToken): TTaskEx;

    /// <summary>
    /// Status atual da task
    /// </summary>
    property Status: TTaskStatus read GetStatus;
  end;

  /// <summary>
  /// Classe extendida para operações assíncronas com retorno de valor (Future)
  /// </summary>
  /// <typeparam name="T">Tipo do valor retornado</typeparam>
  TFutureEx<T> = class(TAsyncOperation)
  private
    FFuture: IFuture<T>;
    FOnComplete: TFutureCompleteHandler<T>;
    FOnException: TExceptionHandler;
    FTimeout: Cardinal;
    FCancellationToken: ICancellationToken;
    FError: Exception;
    function GetValue: T;
    function GetStatus: TTaskStatus;
    procedure HandleCompletion;
    procedure CaptureException;
  public
    /// <summary>
    /// Cria uma nova instância de TFutureEx
    /// </summary>
    /// <param name="AFuture">Future a ser encapsulada</param>
    /// <param name="ATimeout">Tempo limite em milissegundos (INFINITE para sem timeout)</param>
    /// <param name="AToken">Token para cancelamento cooperativo</param>
    constructor Create(const AFuture: IFuture<T>; ATimeout: Cardinal = INFINITE;
      const AToken: ICancellationToken = nil); reintroduce;

    /// <summary>
    /// Destruidor que libera recursos
    /// </summary>
    destructor Destroy; override;

    /// <summary>
    /// Define o callback para conclusão bem-sucedida
    /// </summary>
    /// <param name="AHandler">Procedimento a ser executado</param>
    /// <returns>Self para encadeamento</returns>
    function OnComplete(AHandler: TFutureCompleteHandler<T>): TFutureEx<T>;

    /// <summary>
    /// Define o callback para tratamento de exceções
    /// </summary>
    /// <param name="AHandler">Procedimento a ser executado</param>
    /// <returns>Self para encadeamento</returns>
    function OnException(AHandler: TExceptionHandler): TFutureEx<T>;

    /// <summary>
    /// Adiciona uma continuação que será executada quando a future completar
    /// </summary>
    /// <param name="AProc">Procedimento de continuação</param>
    /// <param name="AOption">Condição para execução</param>
    /// <returns>Nova future que representa a continuação</returns>
    function ContinueWith(AProc: TFutureContinuationProc<T>;
      AOption: TContinuationOption = OnlyOnCompleted): TFutureEx<T>;

    /// <summary>
    /// Transforma o resultado em outro tipo
    /// </summary>
    /// <typeparam name="TResult">Tipo do resultado transformado</typeparam>
    /// <param name="AFunc">Função de transformação</param>
    /// <returns>Nova future com o tipo transformado</returns>
    function ThenBy<TResult>(AFunc: TTransformFunc<T, TResult>): TFutureEx<TResult>;

    /// <summary>
    /// Define um tempo limite para a operação
    /// </summary>
    /// <param name="ATimeout">Tempo em milissegundos</param>
    /// <returns>Self para encadeamento</returns>
    function WithTimeout(ATimeout: Cardinal): TFutureEx<T>;

    /// <summary>
    /// Define um token para cancelamento cooperativo
    /// </summary>
    /// <param name="AToken">Token de cancelamento</param>
    /// <returns>Self para encadeamento</returns>
    function WithCancellation(const AToken: ICancellationToken): TFutureEx<T>;

    /// <summary>
    /// Valor retornado pela Future (bloqueante se não estiver pronto)
    /// </summary>
    property Value: T read GetValue;

    /// <summary>
    /// Status atual da Future
    /// </summary>
    property Status: TTaskStatus read GetStatus;
  end;

  /// <summary>
  /// Factory para criação de Tasks e Futures extendidas
  /// </summary>
  TAsync = class
  public
    /// <summary>
    /// Cria uma nova Task extendida
    /// </summary>
    /// <param name="Proc">Procedimento a ser executado</param>
    /// <param name="ATimeout">Tempo limite em milissegundos</param>
    /// <param name="AToken">Token para cancelamento</param>
    /// <returns>Instância de TTaskEx</returns>
    class function Run(const Proc: TProc; ATimeout: Cardinal = INFINITE;
      const AToken: ICancellationToken = nil): TTaskEx; static;

    /// <summary>
    /// Cria uma nova Future extendida
    /// </summary>
    /// <typeparam name="T">Tipo do valor retornado</typeparam>
    /// <param name="Func">Função a ser executada</param>
    /// <param name="ATimeout">Tempo limite em milissegundos</param>
    /// <param name="AToken">Token para cancelamento</param>
    /// <returns>Instância de TFutureEx</returns>
    class function Future<T>(Func: TFunc<T>; ATimeout: Cardinal = INFINITE;
      const AToken: ICancellationToken = nil): TFutureEx<T>; static;
  end;

  // Alternativa a TAsync usando class helper para TTask
  /// <summary>
  /// Factory para criação de Tasks e Futures extendidas
  /// </summary>
  TTaskHelper = class helper for TTask
  public
    /// <summary>
    /// Cria uma nova Task extendida
    /// </summary>
    /// <param name="Proc">Procedimento a ser executado</param>
    /// <param name="ATimeout">Tempo limite em milissegundos</param>
    /// <param name="AToken">Token para cancelamento</param>
    /// <returns>Instância de TTaskEx</returns>
    class function RunEx(const Proc: TProc; ATimeout: Cardinal = INFINITE;
      const AToken: ICancellationToken = nil): TTaskEx; static;

    /// <summary>
    /// Cria uma nova Future extendida
    /// </summary>
    /// <typeparam name="T">Tipo do valor retornado</typeparam>
    /// <param name="Func">Função a ser executada</param>
    /// <param name="ATimeout">Tempo limite em milissegundos</param>
    /// <param name="AToken">Token para cancelamento</param>
    /// <returns>Instância de TFutureEx</returns>
    class function FutureEx<T>(Func: TFunc<T>; ATimeout: Cardinal = INFINITE;
      const AToken: ICancellationToken = nil): TFutureEx<T>; static;

    class function Async(const Proc: TProc; ATimeout: Cardinal = INFINITE;
      const AToken: ICancellationToken = nil): TTaskEx; overload; static;

    class function Async<T>(Func: TFunc<T>; ATimeout: Cardinal = INFINITE;
      const AToken: ICancellationToken = nil): TFutureEx<T>; overload; static;
  end;


implementation

type
  TTaskAccess = class(TTask)
  end;

{ ETimeoutException }

constructor ETimeoutException.Create;
begin
  inherited Create('Operation timed out');
end;

{ TAsyncOperation }

constructor TAsyncOperation.Create;
begin
  inherited;
  FSyncThread := TThread.CurrentThread;
end;

function TAsyncOperation.WithSyncThread(AThread: TThread): TAsyncOperation;
begin
  FSyncThread := AThread;
  Result := Self;
end;

procedure TAsyncOperation.QueueSync(Proc: TThreadProcedure);
begin
  if Assigned(FSyncThread) then
    TThread.Queue(FSyncThread, Proc)
  else
    TThread.Synchronize(nil, Proc);
end;

{ TTaskEx }

constructor TTaskEx.Create(const ATask: ITask; ATimeout: Cardinal;
  const AToken: ICancellationToken);
begin
  inherited Create;
  FTask := ATask;
  FTimeout := ATimeout;
  FCancellationToken := AToken;
  TTask.Run(procedure begin HandleCompletion end);
end;

destructor TTaskEx.Destroy;
begin
  FError.Free;
  inherited;
end;

procedure TTaskEx.CaptureException;
//var
//TaskObj: TTask;
begin
  try
    if FTask.Status = TTaskStatus.Exception then
    begin
      // Acessa o objeto TTask subjacente para obter a exceção
//    if Supports(FTask, TTask, TaskObj) then
//      raise TaskObj.GetExceptionObject;
//    raise Exception.Create('Task failed');
      raise TTaskAccess(FTask as TObject).GetExceptionObject;
    end;
  except
    FError := AcquireExceptionObject as Exception;
  end;
end;

function TTaskEx.OnComplete(AHandler: TTaskCompleteHandler): TTaskEx;
begin
  FOnComplete := AHandler;
  Result := Self;
end;

function TTaskEx.OnException(AHandler: TExceptionHandler): TTaskEx;
begin
  FOnException := AHandler;
  Result := Self;
end;

function TTaskEx.ContinueWith(AProc: TTaskContinuationProc;
  AOption: TContinuationOption): TTaskEx;
begin
  Result := TTaskEx.Create(
    TTask.Run(
      procedure
      var
        DoContinue: Boolean;
      begin
        // Verifica cancelamento antes de aguardar
        if Assigned(FCancellationToken) and FCancellationToken.IsCancellationRequested then
          Exit;

        // Aguarda conclusão da task original
        if not FTask.Wait(FTimeout) then
          raise ETimeoutException.Create;

        // Verifica cancelamento após aguardar
        if Assigned(FCancellationToken) and FCancellationToken.IsCancellationRequested then
          Exit;

        // Verifica condições para execução da continuação
        case AOption of
          OnlyOnCompleted: DoContinue := FTask.Status = TTaskStatus.Completed;
          OnlyOnFaulted:   DoContinue := FTask.Status = TTaskStatus.Exception;
          OnlyOnCanceled:  DoContinue := FTask.Status = TTaskStatus.Canceled;
          NotOnCompleted:  DoContinue := FTask.Status <> TTaskStatus.Completed;
          else DoContinue := True;
        end;

        if DoContinue then
          AProc(Self);
      end
    ),
    FTimeout,
    FCancellationToken
  ).WithSyncThread(FSyncThread) as TTaskEx;
end;

function TTaskEx.WithTimeout(ATimeout: Cardinal): TTaskEx;
begin
  FTimeout := ATimeout;
  Result := Self;
end;

function TTaskEx.WithCancellation(const AToken: ICancellationToken): TTaskEx;
begin
  FCancellationToken := AToken;
  Result := Self;
end;

function TTaskEx.GetStatus: TTaskStatus;
begin
  Result := FTask.Status;
end;

procedure TTaskEx.HandleCompletion;
begin
  try
    // Verifica cancelamento antes de aguardar
    if Assigned(FCancellationToken) and FCancellationToken.IsCancellationRequested then
    begin
      QueueSync(procedure
        begin
          if Assigned(FOnException) then
            FOnException(EAbort.Create('Operation cancelled'));
        end);
      Exit;
    end;

    // Aguarda a conclusão com timeout
    if not FTask.Wait(FTimeout) then
    begin
      QueueSync(procedure
        begin
          if Assigned(FOnException) then
            FOnException(ETimeoutException.Create);
        end);
      Exit;
    end;

    // Verifica cancelamento após aguardar
    if Assigned(FCancellationToken) and FCancellationToken.IsCancellationRequested then
    begin
      QueueSync(procedure
        begin
          if Assigned(FOnException) then
            FOnException(EAbort.Create('Operation cancelled after wait'));
        end);
      Exit;
    end;

    // Trata resultado
    if FTask.Status = TTaskStatus.Completed then
    begin
      QueueSync(procedure
        begin
          if Assigned(FOnComplete) then
            FOnComplete();
        end);
    end
    else if FTask.Status = TTaskStatus.Exception then
    begin
      CaptureException;
      QueueSync(procedure
        begin
          if Assigned(FOnException) then
            FOnException(FError)
          else
            FError.Free;
          FError := nil;
        end);
    end;
  except
    on E: Exception do
    begin
      FError := AcquireExceptionObject as Exception;
      QueueSync(procedure
        begin
          if Assigned(FOnException) then
            FOnException(FError)
          else
            FError.Free;
          FError := nil;
        end);
    end;
  end;
end;

{ TFutureEx<T> }

constructor TFutureEx<T>.Create(const AFuture: IFuture<T>; ATimeout: Cardinal;
  const AToken: ICancellationToken);
begin
  inherited Create;
  FFuture := AFuture;
  FTimeout := ATimeout;
  FCancellationToken := AToken;
  TTask.Run(procedure begin HandleCompletion end);
end;

destructor TFutureEx<T>.Destroy;
begin
  FError.Free;
  inherited;
end;

procedure TFutureEx<T>.CaptureException;
//var
//TaskObj: TTask;
begin
  try
    if FFuture.Status = TTaskStatus.Exception then
    begin
      // Acessa o objeto TTask subjacente para obter a exceção
//    if Supports(FFuture, TTask, TaskObj) then
//      raise TaskObj.GetExceptionObject;
      raise Exception.Create('Future failed');
//    raise TTaskAccess((FFuture as IInterface) as TObject).GetExceptionObject;
    end;
  except
    FError := AcquireExceptionObject as Exception;
  end;
end;

function TFutureEx<T>.OnComplete(AHandler: TFutureCompleteHandler<T>): TFutureEx<T>;
begin
  FOnComplete := AHandler;
  Result := Self;
end;

function TFutureEx<T>.OnException(AHandler: TExceptionHandler): TFutureEx<T>;
begin
  FOnException := AHandler;
  Result := Self;
end;

function TFutureEx<T>.ContinueWith(AProc: TFutureContinuationProc<T>;
  AOption: TContinuationOption): TFutureEx<T>;
begin
  Result := TFutureEx<T>.Create(
    TTask.Future<T>(
      function: T
      var
        DoContinue: Boolean;
      begin
        // Verifica cancelamento antes de aguardar
        if Assigned(FCancellationToken) and FCancellationToken.IsCancellationRequested then
          Exit(Default(T));

        // Aguarda conclusão da future original
        if not FFuture.Wait(FTimeout) then
          raise ETimeoutException.Create;

        // Verifica cancelamento após aguardar
        if Assigned(FCancellationToken) and FCancellationToken.IsCancellationRequested then
          Exit(Default(T));

        // Verifica condições para execução da continuação
        case AOption of
          OnlyOnCompleted: DoContinue := FFuture.Status = TTaskStatus.Completed;
          OnlyOnFaulted:   DoContinue := FFuture.Status = TTaskStatus.Exception;
          OnlyOnCanceled:  DoContinue := FFuture.Status = TTaskStatus.Canceled;
          NotOnCompleted:  DoContinue := FFuture.Status <> TTaskStatus.Completed;
          else DoContinue := True;
        end;

        if DoContinue then
          AProc(Self);

        Result := FFuture.Value;
      end
    ),
    FTimeout,
    FCancellationToken
  ).WithSyncThread(FSyncThread) as TFutureEx<T>;
end;

function TFutureEx<T>.ThenBy<TResult>(AFunc: TTransformFunc<T, TResult>): TFutureEx<TResult>;
begin
  Result := TFutureEx<TResult>.Create(
    TTask.Future<TResult>(
      function: TResult
      begin
        // Verifica cancelamento antes de aguardar
        if Assigned(FCancellationToken) and FCancellationToken.IsCancellationRequested then
          Exit(Default(TResult));

        // Aguarda conclusão da future original
        if not FFuture.Wait(FTimeout) then
          raise ETimeoutException.Create;

        // Verifica cancelamento após aguardar
        if Assigned(FCancellationToken) and FCancellationToken.IsCancellationRequested then
          Exit(Default(TResult));

        Result := AFunc(FFuture.Value);
      end
    ),
    FTimeout,
    FCancellationToken
  ).WithSyncThread(FSyncThread) as TFutureEx<TResult>;
end;

function TFutureEx<T>.WithTimeout(ATimeout: Cardinal): TFutureEx<T>;
begin
  FTimeout := ATimeout;
  Result := Self;
end;

function TFutureEx<T>.WithCancellation(const AToken: ICancellationToken): TFutureEx<T>;
begin
  FCancellationToken := AToken;
  Result := Self;
end;

function TFutureEx<T>.GetValue: T;
begin
  Result := FFuture.Value;
end;

function TFutureEx<T>.GetStatus: TTaskStatus;
begin
  Result := FFuture.Status;
end;

procedure TFutureEx<T>.HandleCompletion;
begin
  try
    // Verifica cancelamento antes de aguardar
    if Assigned(FCancellationToken) and FCancellationToken.IsCancellationRequested then
    begin
      QueueSync(procedure
        begin
          if Assigned(FOnException) then
            FOnException(EAbort.Create('Operation cancelled'));
        end);
      Exit;
    end;

    // Aguarda a conclusão com timeout
    if not FFuture.Wait(FTimeout) then
    begin
      QueueSync(procedure
        begin
          if Assigned(FOnException) then
            FOnException(ETimeoutException.Create);
        end);
      Exit;
    end;

    // Verifica cancelamento após aguardar
    if Assigned(FCancellationToken) and FCancellationToken.IsCancellationRequested then
    begin
      QueueSync(procedure
        begin
          if Assigned(FOnException) then
            FOnException(EAbort.Create('Operation cancelled after wait'));
        end);
      Exit;
    end;

    // Trata resultado
    if FFuture.Status = TTaskStatus.Completed then
    begin
      QueueSync(procedure
        begin
          if Assigned(FOnComplete) then
            FOnComplete(FFuture.Value);
        end);
    end
    else if FFuture.Status = TTaskStatus.Exception then
    begin
      CaptureException;
      QueueSync(procedure
        begin
          if Assigned(FOnException) then
            FOnException(FError)
          else
            FError.Free;
          FError := nil;
        end);
    end;
  except
    on E: Exception do
    begin
      FError := AcquireExceptionObject as Exception;
      QueueSync(procedure
        begin
          if Assigned(FOnException) then
            FOnException(FError)
          else
            FError.Free;
          FError := nil;
        end);
    end;
  end;
end;

{ TAsync }

class function TAsync.Run(const Proc: TProc; ATimeout: Cardinal;
  const AToken: ICancellationToken): TTaskEx;
begin
  Result := TTaskEx.Create(
    TTask.Run(Proc),
    ATimeout,
    AToken
  );
end;

class function TAsync.Future<T>(Func: TFunc<T>; ATimeout: Cardinal;
  const AToken: ICancellationToken): TFutureEx<T>;
begin
  Result := TFutureEx<T>.Create(
    TTask.Future<T>(Func),
    ATimeout,
    AToken
  );
end;

class function TTaskHelper.Async(const Proc: TProc; ATimeout: Cardinal;
  const AToken: ICancellationToken): TTaskEx;
begin
  Result := TTaskEx.Create(
    TTask.Run(Proc),
    ATimeout,
    AToken
  );
end;

class function TTaskHelper.Async<T>(Func: TFunc<T>; ATimeout: Cardinal;
  const AToken: ICancellationToken): TFutureEx<T>;
begin
  Result := TFutureEx<T>.Create(
    TTask.Future<T>(Func),
    ATimeout,
    AToken
  );
end;

{ TTask }

class function TTaskHelper.FutureEx<T>(Func: TFunc<T>; ATimeout: Cardinal;
  const AToken: ICancellationToken): TFutureEx<T>;
begin
  Result := TFutureEx<T>.Create(
    TTask.Future<T>(Func),
    ATimeout,
    AToken
  );
end;

class function TTaskHelper.RunEx(const Proc: TProc; ATimeout: Cardinal;
  const AToken: ICancellationToken): TTaskEx;
begin
  Result := TTaskEx.Create(
    TTask.Run(Proc),
    ATimeout,
    AToken
  );
end;

end.
