unit DelphiMultithreadingBook0305.ConsumerThread;

interface

uses
  System.Classes,
  DelphiMultithreadingBook0305.Shared,
  DelphiMultithreadingBook.Utils;

type
  TConsumerThread = class(TBaseThread)
  protected
    procedure Execute; override;
  public
    constructor Create(CallbackLogWrite: TLogWriteCallback); reintroduce;
  end;

implementation

uses
  System.SyncObjs;

{ TConsumerThread }

constructor TConsumerThread.Create(CallbackLogWrite: TLogWriteCallback);
begin
  inherited Create(False, CallbackLogWrite);
  // Alterado para False para gerenciamento manual seguro com WaitFor
  FreeOnTerminate := False;
end;

procedure TConsumerThread.Execute;
var
  Mensagem: string;
  ProcessedCount: Integer;
begin
  ProcessedCount := 0;
  CallbackLogWrite('Consumidor: Iniciando consumo de mensagens...');

  while not Terminated do
  begin
    // Espera pelo evento de novos itens. Se o evento estiver sinalizado continua.
    // Se n�o, bloqueia at� que SetEvent seja chamado pelo produtor.
    // Um timeout � usado para permitir que a thread verifique Terminated e
    // evite bloqueio eterno.
    // Espera por 500ms
    if NovosItensEvent.WaitFor(500) = TWaitResult.wrTimeout then
    begin
      // Se deu timeout, verifica se deve terminar e continua o loop
      if Terminated then Break;
      Continue;
    end;

    // Se chegou aqui, o evento foi sinalizado (ou j� estava sinalizado)

    // Protege o acesso � fila
    FilaCriticalSection.Enter;
    try
      // O evento � auto-reset, ent�o um �nico sinal do produtor nos acorda.
      // Em vez de processar apenas um item, otimizamos processando todos os
      // itens que o produtor possa ter enfileirado antes de voltarmos a esperar.
      while MensagensFila.Count > 0 do
      begin
        // Remove da fila
        Mensagem := MensagensFila.Dequeue;
        Inc(ProcessedCount);
        CallbackLogWrite('Consumidor: Processando "%s" (Total processado: %d)',
          [Mensagem, ProcessedCount]);
        // Simula processamento da mensagem com uma pequena pausa
        Sleep(50 + Random(200));
      end;
    finally
      FilaCriticalSection.Leave;
    end;

    // Como NovosItensEvent foi criado como AutoReset, ele j� se resetou
    // automaticamente ap�s o WaitFor.
    // Se fosse ManualReset, ter�amos que chamar NovosItensEvent.ResetEvent aqui.
  end;

  CallbackLogWrite('Consumidor: Terminado. Total processado: %d',
    [ProcessedCount]);
end;

end.
