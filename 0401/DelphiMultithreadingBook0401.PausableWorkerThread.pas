unit DelphiMultithreadingBook0401.PausableWorkerThread;

interface

uses
  System.Classes,
  DelphiMultithreadingBook0401.SharedData,
  DelphiMultithreadingBook.Utils;

type
  TPausableWorkerThread = class(TThread)
  private
    FLogWriteCallback: TLogWriteCallback;
    FThreadId: Integer;
  protected
    procedure Execute; override;
    procedure TerminatedSet; override;
  public
    constructor Create(ThreadId: Integer; LogWriteCallback: TLogWriteCallback);
      reintroduce;
  end;

implementation

uses
  System.SyncObjs,
  System.SysUtils;

{ TPausableWorkerThread }

constructor TPausableWorkerThread.Create(ThreadId: Integer;
  LogWriteCallback: TLogWriteCallback);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FThreadId := ThreadId;
  FLogWriteCallback := LogWriteCallback;
end;

procedure TPausableWorkerThread.Execute;
var
  i: Integer;
  DebugMessage: string;
begin
  DebugLogWrite('PausableThread %d: Iniciando trabalho...', [FThreadId]);

  // Simula 15 passos de trabalho
  for i := 1 to 15 do
  begin
    // --- Ponto de Verifica��o de Pausa (Ponto Seguro) ---
    DebugLogWrite('PausableThread %d: Aguardando sinal de PAUSA/RETOMADA...',
      [FThreadId]);

    // WaitFor aguarda o evento estar sinalizado. Se o PauseEvent estiver
    // Resetado (n�o sinalizado), a thread pausa aqui.
    // Usamos um timeout curto para poder verificar 'Terminated' e
    // evitar bloqueio eterno.
    // Se deu timeout, significa que o evento est� resetado (pediu para pausar).
    // Entra em um loop de espera at� o evento ser Setado novamente,
    // mas ainda verifica a condi��o de Terminate para poder parar gentilmente.
    while (PauseEvent.WaitFor(100) = TWaitResult.wrTimeout)
      and (not Terminated) do
    begin
      DebugLogWrite('PausableThread %d: Pausada...', [FThreadId]);
      // A thread est� pausada, mas ainda pode ser terminada
    end;
    // --- Fim do Ponto de Verifica��o de Pausa ---

    // Verifica Terminated ap�s a pausa
    if Terminated then
      Break;

    DebugMessage := Format('PausableThread %d: Executando passo %d...',
      [FThreadId, i]);

    // Callback adicionado a esta thread apenas para o usu�rio
    // ter um retorno visual da thread sendo executada.
    if Assigned(FLogWriteCallback) then
      FLogWriteCallback(DebugMessage);

    DebugLogWrite(DebugMessage);

    // Simula trabalho do passo
    Sleep(500);
  end;

  DebugLogWrite('PausableThread %d: Trabalho conclu�do!', [FThreadId]);
end;

procedure TPausableWorkerThread.TerminatedSet;
begin
  inherited;
  PauseEvent.SetEvent;
end;

end.
