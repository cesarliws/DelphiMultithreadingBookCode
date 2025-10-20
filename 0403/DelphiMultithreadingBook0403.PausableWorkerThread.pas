unit DelphiMultithreadingBook0403.PausableWorkerThread;

interface

uses
  System.Classes,
  DelphiMultithreadingBook.CancellationToken;

type
  TPausableWorkerThread = class(TThread)
  private
    FThreadId: Integer;
    // O token de cancelamento
    FCancellationToken: ICancellationToken;
  protected
    procedure Execute; override;
  public
    constructor Create(ThreadId: Integer; CancellationToken: ICancellationToken);
  end;

implementation

uses
  System.SyncObjs,
  System.SysUtils,
  WinApi.Windows,
  DelphiMultithreadingBook0403.SharedData,
  DelphiMultithreadingBook.Utils;

{ TPausableWorkerThread }

constructor TPausableWorkerThread.Create(ThreadId: Integer;
  CancellationToken: ICancellationToken);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FThreadId := ThreadId;
  FCancellationToken := CancellationToken;
end;

procedure TPausableWorkerThread.Execute;
var
  i: Integer;
begin
  DebugLogWrite('PausableThread %d: Iniciando trabalho...', [FThreadId]);

  // Protege todo o bloco de execu��o para capturar a exce��o de cancelamento
  try
    // Primeira verifica��o de cancelamento antes de come�ar o loop principal
    FCancellationToken.ThrowIfCancellationRequested;

    for i := 1 to 15 do // Simula 15 passos de trabalho
    begin
      // --- Ponto de Verifica��o de Pausa (mantido do 4.1) ---
      // A thread tamb�m pode ser pausada e ainda verificar o cancelamento
      DebugLogWrite('PausableThread %d: Aguardando sinal de PAUSA/RETOMADA...',
        [FThreadId]);

      // Usa o WaitForCancellation do ICancellationToken
      if PauseEvent.WaitFor(100) = TWaitResult.wrTimeout then
      begin
        while (PauseEvent.WaitFor(100) = TWaitResult.wrTimeout) and
          // Verifica o token de cancelamento aqui
          (not FCancellationToken.IsCancellationRequested) do
        begin
          DebugLogWrite('PausableThread %d: Pausada...', [FThreadId]);
        end;

        // Se saiu do loop de pausa porque o cancelamento foi solicitado
        if FCancellationToken.IsCancellationRequested then Break;
      end;
      // --- Fim do Ponto de Verifica��o de Pausa ---

      // --- Ponto de Verifica��o de Cancelamento ---
      // Verifica o token de cancelamento em pontos seguros do trabalho
      // A chamada ThrowIfCancellationRequested lan�ar� uma exce��o se cancelado.
      // Isso simplifica a l�gica de sa�da do loop.
      FCancellationToken.ThrowIfCancellationRequested;

      DebugLogWrite('PausableThread %d: Executando passo %d...', [FThreadId, i]);
      // Simula trabalho
      Sleep(500);
    end;

    DebugLogWrite('PausableThread %d: Trabalho conclu�do!', [FThreadId]);
  except
    // Captura a exce��o de cancelamento
    on E: EOperationCancelled do
    begin
      DebugLogWrite('PausableThread %d: Opera��o CANCELADA: %s',
        [FThreadId, E.Message]);
      // A��es de limpeza espec�ficas para o cancelamento podem ir aqui
    end;

    // Captura outras exce��es inesperadas
    on E: Exception do
    begin
      DebugLogWrite('PausableThread %d: ERRO INESPERADO: %s',
        [FThreadId, E.Message]);
      // L�gica de tratamento de erro para outras exce��es (t�pico 4.4)
    end;
  end;
end;

end.
