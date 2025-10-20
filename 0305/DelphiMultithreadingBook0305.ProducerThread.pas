unit DelphiMultithreadingBook0305.ProducerThread;

interface

uses
  System.Classes,
  DelphiMultithreadingBook0305.Shared,
  DelphiMultithreadingBook.Utils;

type
  TProducerThread = class(TBaseThread)
  protected
    procedure Execute; override;
  public
    constructor Create(CallbackLogWrite: TLogWriteCallback); reintroduce;
  end;

implementation

uses
  System.SyncObjs, // Inline TCriticalSection.Enter/Leave
  System.SysUtils;

{ TProducerThread }

constructor TProducerThread.Create(CallbackLogWrite: TLogWriteCallback);
begin
  inherited Create(False, CallbackLogWrite);
  // FreeOnTerminate = False para gerenciamento manual seguro com WaitFor
  FreeOnTerminate := False;
end;

procedure TProducerThread.Execute;
var
  i: Integer;
  Mensagem: string;
begin
  CallbackLogWrite('Produtor: Iniciando produção de mensagens...');
  // Produz 10 mensagens
  for i := 1 to 10 do
  begin
    if Terminated then Break;

    Mensagem := Format('Mensagem %d', [i]);

    // Protege o acesso à fila
    FilaCriticalSection.Enter;
    try
       // Adiciona mensagem à fila
      MensagensFila.Enqueue(Mensagem);
      CallbackLogWrite('Produtor: Adicionou "%s" na fila. (Tamanho: %d)',
        [Mensagem, MensagensFila.Count]);
    finally
      FilaCriticalSection.Leave;
    end;

    // Sinaliza que há novos itens na fila
    NovosItensEvent.SetEvent;
    // Simula tempo de produção (entre 100ms e 600ms)
    Sleep(100 + Random(500));
  end;

  CallbackLogWrite('Produtor: Produção concluída.');
  // Sinaliza uma última vez para garantir que o consumidor processe tudo
  NovosItensEvent.SetEvent;
end;

end.
