unit DelphiMultithreadingBook0607.Threading.BasicHelpers;

interface

uses
  System.Classes, // Para TProc
  System.SysUtils, // Para Exception, Format
  System.Threading; // Para ITask, IFuture, TTaskStatus

type
  // Tipos de Delegados para Callbacks
  TTaskCompleteHandler = reference to procedure();
  TFutureCompleteHandler<T> = reference to procedure(const AResult: T);
  TExceptionHandler = reference to procedure(const AException: Exception);

  // Op��es para TTaskExtensions.ContinueWith
  TContinuationOption = (
    /// <summary>Executa a continua��o se a tarefa precedente N�O completou (canceou ou falhou)</summary>
    NotOnCompleted,
    /// <summary>Executa a continua��o APENAS se a tarefa precedente completou com sucesso</summary>
    OnlyOnCompleted,
    /// <summary>Executa a continua��o APENAS se a tarefa precedente falhou</summary>
    OnlyOnFaulted,
    /// <summary>Executa a continua��o APENAS se a tarefa precedente foi cancelada</summary>
    OnlyOnCanceled
  );
  TContinuationOptions = set of TContinuationOption;

  /// <summary>
  /// M�todos auxiliares para estender a funcionalidade de TTask e IFuture.
  /// Implementa padr�es como OnComplete, OnException e ContinueWith.
  /// </summary>
  TTaskExtensions = class
  private
    // Fun��es auxiliares internas para lidar com a conclus�o de ITask e IFuture<T>
    class procedure DoHandleTaskCompletion(const TargetTask: ITask; const
      OnComplete: TTaskCompleteHandler; const OnError: TExceptionHandler; const
      OnCancel: TTaskCompleteHandler); overload; static;
    class procedure DoHandleFutureCompletion<T>(const TargetFuture: IFuture<T>;
      const OnComplete: TFutureCompleteHandler<T>; const OnError:
      TExceptionHandler; const OnCancel: TTaskCompleteHandler); overload; static;
  public
    /// <summary>
    /// Define um callback a ser executado na Main Thread quando a ITask for conclu�da com sucesso.
    /// </summary>
    /// <param name="ATask">A ITask a ser monitorada.</param>
    /// <param name="AHandler">O procedimento a ser executado na Main Thread em caso de sucesso.</param>
    class procedure OnComplete(const ATask: ITask; const AHandler: TTaskCompleteHandler); overload; static;

    /// <summary>
    /// Define um callback a ser executado na Main Thread quando a IFuture for conclu�da com sucesso.
    /// O resultado da Future � passado para o handler.
    /// </summary>
    /// <typeparam name="T">O tipo de resultado da Future.</typeparam>
    /// <param name="AFuture">A IFuture a ser monitorada.</param>
    /// <param name="AHandler">O procedimento a ser executado na Main Thread em caso de sucesso.</param>
    class procedure OnComplete<T>(const AFuture: IFuture<T>; const AHandler: TFutureCompleteHandler<T>); overload; static;

    /// <summary>
    /// Define um callback a ser executado na Main Thread quando a ITask falhar.
    /// A exce��o da Task � passada para o handler.
    /// </summary>
    /// <param name="ATask">A ITask a ser monitorada.</param>
    /// <param name="AHandler">O procedimento a ser executado na Main Thread em caso de exce��o.</param>
    class procedure OnException(const ATask: ITask; const AHandler: TExceptionHandler); overload; static;

    /// <summary>
    /// Define um callback a ser executado na Main Thread quando a IFuture falhar.
    /// A exce��o da Future � passada para o handler.
    /// </summary>
    /// <typeparam name="T">O tipo de resultado da Future.</typeparam>
    /// <param name="AFuture">A IFuture a ser monitorada.</param>
    /// <param name="AHandler">O procedimento a ser executado na Main Thread em caso de exce��o.</param>
    class procedure OnException<T>(const AFuture: IFuture<T>; const AHandler: TExceptionHandler); overload; static;

    /// <summary>
    /// Cria e retorna uma nova ITask (continua��o) que ser� executada ap�s a conclus�o da tarefa precedente.
    /// A execu��o da continua��o pode ser condicionada ao status da tarefa precedente.
    /// </summary>
    /// <param name="ATask">A tarefa precedente.</param>
    /// <param name="ContinuationAction">A��o a ser executada na continua��o.</param>
    /// <param name="Options">Condi��es para a execu��o da continua��o.</param>
    /// <returns>A nova ITask que representa a continua��o.</returns>
    class function ContinueWith(const ATask: ITask; const ContinuationAction:
      TTaskCompleteHandler; Options: TContinuationOptions = []): ITask; overload; static;

    /// <summary>
    /// Cria e retorna uma nova IFuture<T> (continua��o) que ser� executada ap�s a conclus�o da Future precedente.
    /// A execu��o da continua��o pode ser condicionada ao status da Future precedente.
    /// O resultado da Future precedente � passado para a continua��o.
    /// </summary>
    /// <typeparam name="T">O tipo de resultado da Future precedente.</typeparam>
    /// <param name="AFuture">A Future precedente.</param>
    /// <param name="ContinuationAction">A��o a ser executada na continua��o (recebe o resultado da Future precedente).</param>
    /// <param name="Options">Condi��es para a execu��o da continua��o.</param>
    /// <returns>A nova IFuture<T> que representa a continua��o.</returns>
    class function ContinueWith<T>(const AFuture: IFuture<T>; const
      ContinuationAction: TFutureCompleteHandler<T>; Options:
      TContinuationOptions = []): IFuture<T>; overload; static;
  end;

implementation

uses
  WinApi.Windows;

var
  CapturedException: Exception; // Para adquirir a exce��o se Task.Wait falhar

{ TTaskExtensions }

// Implementa��o base para OnComplete, OnException, ContinueWith (reutilizando l�gica)
// Move para private class procedure para resolver problemas de escopo e tipagem
class procedure TTaskExtensions.DoHandleTaskCompletion(const TargetTask: ITask;
  const OnComplete: TTaskCompleteHandler; const OnError: TExceptionHandler;
  const OnCancel: TTaskCompleteHandler);
//var
//CapturedException: Exception; // Para adquirir a exce��o se Task.Wait falhar
begin
  try
    TargetTask.Wait; // Espera a task completar (bloqueia a thread do pool)
  except
    on E: Exception do // Captura a exce��o que Task.Wait poderia re-lan�ar
    begin
      CapturedException := AcquireExceptionObject as Exception; // Adquire a exce��o para que ela persista
    end;
  end;

  TThread.Queue(nil, // Enfileira o callback na Main Thread
    procedure
    begin
      try
        case TargetTask.Status of
          TTaskStatus.Completed:
            if Assigned(OnComplete) then
              OnComplete();
          TTaskStatus.Canceled:
            if Assigned(OnCancel) then
              OnCancel();
          TTaskStatus.Exception:
            begin
              if Assigned(OnError) then
                OnError(CapturedException) // Passa a exce��o adquirida
              else if Assigned(CapturedException) then
                CapturedException.Free; // Libera se n�o houver handler
            end;
        end;
      except
        on E: Exception do
          OutputDebugString(PChar(Format(
           'Erro inesperado no callback da UI: %s%s', [E.Message, sLineBreak])));
      end;
      // Garante que a exce��o capturada seja liberada se nenhum handler a pegou
      if Assigned(CapturedException) then
        CapturedException.Free;
    end
  );
end;

class procedure TTaskExtensions.DoHandleFutureCompletion<T>(const TargetFuture:
  IFuture<T>; const OnComplete: TFutureCompleteHandler<T>; const OnError:
  TExceptionHandler; const OnCancel: TTaskCompleteHandler);
var
  CapturedException: Exception; // Para adquirir a exce��o se Future.Wait falhar
begin
  try
    TargetFuture.Wait; // Espera a Future completar (bloqueia a thread do pool)
  except
    on E: Exception do // Captura a exce��o que Future.Wait poderia re-lan�ar
    begin
      CapturedException := AcquireExceptionObject as Exception; // Adquire a exce��o para que ela persista
    end;
  end;

  TThread.Queue(nil, // Enfileira o callback na Main Thread
    procedure
    begin
      try
        case TargetFuture.Status of
          TTaskStatus.Completed:
            if Assigned(OnComplete) then
              OnComplete(TargetFuture.Value); // Pega o valor da Future
          TTaskStatus.Canceled:
            if Assigned(OnCancel) then
              OnCancel();
          TTaskStatus.Exception:
            begin
              if Assigned(OnError) then
                OnError(CapturedException); // Passa a exce��o adquirida
//            else if Assigned(CapturedException) then
//              CapturedException.Free; // Libera se n�o houver handler
            end;
        end;
      except
        on E: Exception do
          OutputDebugString(PChar(Format('Erro inesperado no callback da UI (tipado): %s%s', [E.Message, sLineBreak])));
      end;
      // Garante que a exce��o capturada seja liberada se nenhum handler a pegou
      if Assigned(CapturedException) then
        CapturedException.Free;
    end
  );
end;


// OnComplete para ITask
class procedure TTaskExtensions.OnComplete(const ATask: ITask; const AHandler: TTaskCompleteHandler);
var
  TargetTask: ITask;
begin
  TargetTask := ATask; // Captura a refer�ncia
  TTask.Run(
    procedure
    begin
      DoHandleTaskCompletion(TargetTask, AHandler, nil, nil);
    end
  );
end;

// OnComplete para IFuture<T>
class procedure TTaskExtensions.OnComplete<T>(const AFuture: IFuture<T>; const AHandler: TFutureCompleteHandler<T>);
var
  TargetFuture: IFuture<T>;
begin
  TargetFuture := AFuture;
  TTask.Run(
    procedure
    begin
      DoHandleFutureCompletion<T>(TargetFuture, AHandler, nil, nil);
    end
  );
end;

// OnException para ITask
class procedure TTaskExtensions.OnException(const ATask: ITask; const AHandler: TExceptionHandler);
var
  TargetTask: ITask;
begin
  TargetTask := ATask;
  TTask.Run(
    procedure
    begin
      DoHandleTaskCompletion(TargetTask, nil, AHandler, nil);
    end
  );
end;

// OnException para IFuture<T>
class procedure TTaskExtensions.OnException<T>(const AFuture: IFuture<T>; const AHandler: TExceptionHandler);
var
  TargetFuture: IFuture<T>;
begin
  TargetFuture := AFuture;
  TTask.Run(
    procedure
    begin
      DoHandleFutureCompletion<T>(TargetFuture, nil, AHandler, nil);
    end
  );
end;

// ContinueWith para ITask
class function TTaskExtensions.ContinueWith(const ATask: ITask; const ContinuationAction: TTaskCompleteHandler;
                                           Options: TContinuationOptions): ITask;
var
  AntecedentTask: ITask;
begin
  AntecedentTask := ATask; // Captura a refer�ncia da tarefa precedente

  Result := TTask.Run( // A nova task de continua��o
    procedure
    var
      ShouldExecuteContinuation: Boolean;
      CapturedException: Exception; // Para adquirir a exce��o se AntecedentTask.Wait falhar
    begin
      try
        AntecedentTask.Wait; // Espera a tarefa precedente completar
      except
        on E: Exception do
        begin
          CapturedException := AcquireExceptionObject as Exception;
        end;
      end;

      ShouldExecuteContinuation := False;
      // L�gica para decidir se executa a continua��o com base nas op��es
      if Options = [] then // Se nenhuma op��o for especificada, executa sempre
        ShouldExecuteContinuation := True
      else if OnlyOnCompleted in Options then
        ShouldExecuteContinuation := AntecedentTask.Status = TTaskStatus.Completed
      else if OnlyOnFaulted in Options then
        ShouldExecuteContinuation := AntecedentTask.Status = TTaskStatus.Exception
      else if OnlyOnCanceled in Options then
        ShouldExecuteContinuation := AntecedentTask.Status = TTaskStatus.Canceled
      else if NotOnCompleted in Options then
        ShouldExecuteContinuation := AntecedentTask.Status <> TTaskStatus.Completed;

      if ShouldExecuteContinuation then
      begin
        TThread.Queue(nil, // Enfileira a a��o de continua��o na Main Thread
          procedure
          begin
            ContinuationAction();
            if Assigned(CapturedException) then // Se houve exce��o, liber�-la ap�s o uso
              CapturedException.Free;
          end
        );
      end
      else if Assigned(CapturedException) then // Se n�o executou a continua��o mas capturou exce��o, liberar
        CapturedException.Free;
    end
  );
end;

// ContinueWith para IFuture<T>
class function TTaskExtensions.ContinueWith<T>(const AFuture: IFuture<T>;
  const ContinuationAction: TFutureCompleteHandler<T>; Options:
  TContinuationOptions): IFuture<T>;
var
  AntecedentFuture: IFuture<T>;
begin
  AntecedentFuture := AFuture; // Captura a refer�ncia da Future precedente

  // Retorna uma nova Future que cont�m a l�gica de continua��o e o valor da precedente
  Result := TTask.Future<T>(
    function: T // A fun��o an�nima da nova Future de continua��o
    var
      ShouldExecuteContinuation: Boolean;
      CapturedException: Exception; // Para adquirir a exce��o se AntecedentFuture.Wait falhar
    begin
      try
        AntecedentFuture.Wait; // Espera a Future precedente completar
      except
        on E: Exception do
        begin
          CapturedException := AcquireExceptionObject as Exception;
        end;
      end;

      ShouldExecuteContinuation := False;
      if Options = [] then
        ShouldExecuteContinuation := True
      else if OnlyOnCompleted in Options then
        ShouldExecuteContinuation := AntecedentFuture.Status = TTaskStatus.Completed
      else if OnlyOnFaulted in Options then
        ShouldExecuteContinuation := AntecedentFuture.Status = TTaskStatus.Exception
      else if OnlyOnCanceled in Options then
        ShouldExecuteContinuation := AntecedentFuture.Status = TTaskStatus.Canceled
      else if NotOnCompleted in Options then
        ShouldExecuteContinuation := AntecedentFuture.Status <> TTaskStatus.Completed;

      if ShouldExecuteContinuation then
      begin
        TThread.Queue(nil, // Enfileira a a��o de continua��o na Main Thread
          procedure
          begin
            ContinuationAction(AntecedentFuture.Value); // Passa o valor da Future precedente
            if Assigned(CapturedException) then // Se houve exce��o, liber�-la ap�s o uso
              CapturedException.Free;
          end
        );
      end
      else if Assigned(CapturedException) then // Se n�o executou a continua��o mas capturou exce��o, liberar
        CapturedException.Free;

      Result := AntecedentFuture.Value; // Retorna o valor da Future precedente (pode lan�ar exce��o aqui)
    end
  );
end;

end.

