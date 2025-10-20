unit DelphiMultithreadingBook0305.MainForm;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  DelphiMultithreadingBook0305.Shared,
  DelphiMultithreadingBook0305.ProducerThread,
  DelphiMultithreadingBook0305.ConsumerThread;

type
  TMainForm = class(TForm)
    IniciarProdutorConsumidorButton: TButton;
    LogMemo: TMemo;
    PararConsumidorButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure IniciarProdutorConsumidorButtonClick(Sender: TObject);
    procedure PararConsumidorButtonClick(Sender: TObject);
  private
    // Vari�veis para manter a refer�ncia �s threads Produtor e Consumidor
    FProducerThread: TProducerThread;
    FConsumerThread: TConsumerThread;
    procedure ProducerThreadTerminate(Sender: TObject);
    procedure ConsumerThreadTerminate(Sender: TObject);
    procedure FinalizeConsumer;
    procedure FinalizeProducer;
    procedure InitializeConsumer;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.SyncObjs,
  DelphiMultithreadingBook.Utils;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplica��o iniciada. Clique nos bot�es para iniciar as threads.');
  LogMemo.ScrollBars := ssVertical;
  PararConsumidorButton.Enabled := False;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  // Termina a thread Produtor, se ainda ativa
  FinalizeProducer;
  // Termina a thread Consumidor, se ainda ativa
  FinalizeConsumer;
  UnregisterLogger;
end;

procedure TMainForm.IniciarProdutorConsumidorButtonClick(Sender: TObject);
begin
  IniciarProdutorConsumidorButton.Enabled := False;
  LogWrite('> Iniciando produ��o de novas mensagens...');
  InitializeConsumer;
  FinalizeProducer;

  // Assegura que o evento e a fila estejam limpos para uma nova produ��o
  FilaCriticalSection.Enter;
  try
    MensagensFila.Clear;
  finally
    FilaCriticalSection.Leave;
  end;

  // Garante que o evento comece n�o sinalizado
  NovosItensEvent.ResetEvent;

  // Cria e inicia uma nova thread Produtor
  FProducerThread := TProducerThread.Create(LogWrite);
  FProducerThread.OnTerminate := ProducerThreadTerminate;

  LogWrite('Nova produ��o iniciada. Acompanhe no Debug Output e LogMemo.');
end;

procedure TMainForm.PararConsumidorButtonClick(Sender: TObject);
begin
  if Assigned(FConsumerThread) then
  begin
    LogWrite('Solicitando encerramento da Thread Consumidor...');
    FConsumerThread.Terminate;
    // Sinaliza para garantir que o consumidor saia do WaitFor
    NovosItensEvent.SetEvent;
    // O WaitFor e Free ser�o feitos no FormDestroy ou no pr�prio OnTerminate
    // se o consumidor n�o tiver mais nada para processar e terminar sozinho.
    // Para este caso, OnTerminate do consumidor j� lida com a limpeza da
    // refer�ncia.
    FinalizeConsumer;
    LogWrite('Novas mensagens produzidas n�o mais ser�o consumidas.');
  end;
end;

procedure TMainForm.ProducerThreadTerminate(Sender: TObject);
begin
  // Sincroniza com a thread principal para atualizar a UI
  TThread.ForceQueue(nil,
    procedure
    begin
      LogWrite('Thread Produtor finalizada. Produ��o conclu�da.');
      // Reabilita o bot�o de iniciar para nova produ��o.
      IniciarProdutorConsumidorButton.Enabled := True;
      // Se para o consumidor, somente ir� gerar novas mensagens sem consumo.
    end
  );
end;

// Handler para OnTerminate do Consumidor
procedure TMainForm.ConsumerThreadTerminate(Sender: TObject);
begin
  // Sincroniza com a thread principal para atualizar a UI
  TThread.ForceQueue(nil,
    procedure
    begin
      LogWrite('Thread Consumidor finalizada.');
      // Limpa a refer�ncia
      PararConsumidorButton.Enabled := False;
      IniciarProdutorConsumidorButton.Enabled := True;
    end
  );
end;

procedure TMainForm.InitializeConsumer;
begin
  if not Assigned(FConsumerThread) then
  begin
    LogWrite('Consumidor inativo. Recriando a thread consumidora...');
    FConsumerThread := TConsumerThread.Create(LogWrite);
    FConsumerThread.OnTerminate := ConsumerThreadTerminate;
    PararConsumidorButton.Enabled := True;
  end;
end;

procedure TMainForm.FinalizeConsumer;
begin
  if Assigned(FConsumerThread) then
  begin
    FConsumerThread.Terminate;
    // Sinaliza para o consumidor sair do WaitFor
    NovosItensEvent.SetEvent;
    FConsumerThread.WaitFor;
    FConsumerThread.Free;
    FConsumerThread := nil;
  end;
end;

procedure TMainForm.FinalizeProducer;
begin
  if Assigned(FProducerThread) then
  begin
    FProducerThread.Terminate;
    FProducerThread.WaitFor;
    FProducerThread.Free;
    FProducerThread := nil;
  end;
end;

end.
