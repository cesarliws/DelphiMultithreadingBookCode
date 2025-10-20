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

  // Protege todo o bloco de execução para capturar a exceção de cancelamento
  try
    // Primeira verificação de cancelamento antes de começar o loop principal
    FCancellationToken.ThrowIfCancellationRequested;

    for i := 1 to 15 do // Simula 15 passos de trabalho
    begin
      // --- Ponto de Verificação de Pausa (mantido do 4.1) ---
      // A thread também pode ser pausada e ainda verificar o cancelamento
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
      // --- Fim do Ponto de Verificação de Pausa ---

      // --- Ponto de Verificação de Cancelamento ---
      // Verifica o token de cancelamento em pontos seguros do trabalho
      // A chamada ThrowIfCancellationRequested lançará uma exceção se cancelado.
      // Isso simplifica a lógica de saída do loop.
      FCancellationToken.ThrowIfCancellationRequested;

      DebugLogWrite('PausableThread %d: Executando passo %d...', [FThreadId, i]);
      // Simula trabalho
      Sleep(500);
    end;

    DebugLogWrite('PausableThread %d: Trabalho concluído!', [FThreadId]);
  except
    // Captura a exceção de cancelamento
    on E: EOperationCancelled do
    begin
      DebugLogWrite('PausableThread %d: Operação CANCELADA: %s',
        [FThreadId, E.Message]);
      // Ações de limpeza específicas para o cancelamento podem ir aqui
    end;

    // Captura outras exceções inesperadas
    on E: Exception do
    begin
      DebugLogWrite('PausableThread %d: ERRO INESPERADO: %s',
        [FThreadId, E.Message]);
      // Lógica de tratamento de erro para outras exceções (tópico 4.4)
    end;
  end;
end;

end.
