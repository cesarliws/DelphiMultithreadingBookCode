unit DelphiMultithreadingBook0406.WorkerWithRetryOnErrorThread;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  System.Threading, // EAggregateException
  DelphiMultithreadingBook.Utils;

type
  TWorkerWithRetryOnErrorThread = class(TThread)
  private
    FCurrentRetry: Integer;
    FDelayMs: Integer;
    FError: EAggregateException;
    FErrors: TObjectList<Exception>;
    FInitialDelayMs: Integer;
    FMaxRetries: Integer;
  protected
    procedure Execute; override;
    procedure ExecuteWorkWithRetryOnError; virtual;
    // Método que tenta a operação
    function RunDivisionCalculation: Boolean;

  public
    constructor Create(MaxRetries: Integer = 3; InitialDelayMs: Integer = 500);
    destructor Destroy; override;
    property Error: EAggregateException read FError;
  end;

implementation

{ TWorkerWithErrorThread }

constructor TWorkerWithRetryOnErrorThread.Create(MaxRetries: Integer = 3;
  InitialDelayMs: Integer = 500);
begin
  inherited Create(False);
  // Gerenciamento manual (FreeOnTerminate = False) para garantir que
  // podemos chamar WaitFor de forma segura no MainForm.
  FreeOnTerminate := False;
  FMaxRetries := MaxRetries;
  FInitialDelayMs := InitialDelayMs;
  FCurrentRetry := 0;
  // AOwnsObjects = False, Error: EAggregateException irá liberar as exceptions
  FErrors := TObjectList<Exception>.Create(False);
end;

destructor TWorkerWithRetryOnErrorThread.Destroy;
begin
  // Libera a lista de exceções coletadas
  FErrors.Free;
  // Libera o objeto EAggregateException se ele foi criado
  if Assigned(FError) then
    FError.Free;
  inherited;
end;

procedure TWorkerWithRetryOnErrorThread.Execute;
var
  ExceptionObject: TObject;
begin
  try
    LogWrite('Thread com retry: Iniciando trabalho...');
    Sleep(100); // Pequena pausa inicial
    FCurrentRetry := 0;
    FDelayMs := FInitialDelayMs;

    // Chama o método com o loop de retry
    ExecuteWorkWithRetryOnError;

    // Após o loop, se houver erros coletados, cria a exceção agregada.
    if FErrors.Count > 0 then
    begin
      // A EAggregateException assume a propriedade das exceções
      FError := EAggregateException.Create(FErrors.ToArray);
      // A lista FErrors não deve mais ser dona dos objetos.
      FErrors.OwnsObjects := False;
    end;
  except
    on E: Exception do
    begin
      LogWrite('Thread com retry: Exceção fatal no Execute: %s', [E.Message]);
      // Captura uma exceção inesperada no próprio Execute
      ExceptionObject := AcquireExceptionObject;
      if ExceptionObject is EAggregateException then
        FError := EAggregateException(ExceptionObject)
      else
        FError := EAggregateException.Create([Exception(ExceptionObject)]);
    end;
  end;
  LogWrite('Thread com retry: Fim do ciclo de trabalho.');
end;

procedure TWorkerWithRetryOnErrorThread.ExecuteWorkWithRetryOnError;
begin
  while (not Terminated) and (FCurrentRetry <= FMaxRetries) do
  begin
    Inc(FCurrentRetry);
    LogWrite('Thread com retry: Tentativa %d de %d',
      [FCurrentRetry, FMaxRetries]);

    // Tenta executar a operação
    if RunDivisionCalculation then
    begin
      LogWrite('Thread com retry: Operação finalizada com sucesso!');
      // Sai do loop se a operação foi bem-sucedida
      Break;
    end
    else // A operação falhou
    begin
      // Verifica cancelamento antes da próxima iteração
      if Terminated then
        Break;

      // Se ainda há tentativas restantes
      if FCurrentRetry <= FMaxRetries then
      begin
        LogWrite('Thread com retry: Falha na tentativa %d. ' +
          'Esperando %d ms para reprocessar...', [FCurrentRetry, FDelayMs]);

        // Simula o Backoff Exponencial
        Sleep(FDelayMs);
        // Dobra o tempo de espera para a próxima tentativa
        FDelayMs := FDelayMs * 2;
        // Opcional: Adicionar um limite máximo para FDelayMs, e um jitter
        // (Random(FDelayMs div 10)) para evitar picos
      end
      else // Todas as tentativas esgotadas
      begin
        LogWrite('Thread com retry: Todas as %d tentativas falharam.',
          [FMaxRetries]);
        // O erro FError já está preenchido pela última falha
      end;
    end;
  end;
end;

function TWorkerWithRetryOnErrorThread.RunDivisionCalculation: Boolean;
var
  Divisor: Integer;
  Valor: Integer;
begin
  // Assume falha
  Result := False;
  try
    // Random(2) retorna 0, 1. Se for 0, causa a divisão por zero.
    Divisor := Random(2);
    if Divisor = 0 then
    begin
      LogWrite('Thread com erro (Retry %d): Tentando dividir por zero...',
        [FCurrentRetry]);
      // Força uma exceção EDivByZero
      Valor := 100 div Divisor;
      // A próxima linha nunca será executada,
      // o fluxo é interrompido na divisão por zero
      LogWrite('Thread com erro (Retry %d): Resultado = %d', [Valor]);
    end
    else
    begin
      LogWrite('Thread com erro (Retry %d): Operação realizada com sucesso.',
        [FCurrentRetry]);
      // Operação bem-sucedida
      Result := True;
    end;
  except
    on E: Exception do
    begin
      LogWrite('Thread com erro (Retry %d): Exceção capturada: %s.',
        [FCurrentRetry, E.Message]);

      // **CRÍTICO:** Usamos AcquireExceptionObject para armazenar a exceção
      // com segurança, garantindo que o objeto não seja liberado pela RTL
      // ao sair do except e que possamos liberá-lo depois com a FErrors.
      FErrors.Add(AcquireExceptionObject as Exception);
      Result := False;
    end;
  end;
end;

end.

