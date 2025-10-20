unit DelphiMultithreadingBook0705.MainForm;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  DelphiMultithreadingBook.Utils;

type
  TMainForm = class(TForm)
    StartButton: TButton;
    LogMemo: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure StartButtonClick(Sender: TObject);
  private
    FConsumer: TThread;
    FProducer: TThread;
    procedure FinalizeThreads;
    procedure ProducerThreadTerminated(Sender: TObject);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.SysUtils,
  DelphiMultithreadingBook0705.SharedData,
  DelphiMultithreadingBook0705.WorkerThreads;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplica��o iniciada.');
  // Cria e inicia o Consumidor, que ficar� esperando por trabalho.
  FConsumer := TConsumerThread.Create(False);
  // Gerenciamento manual
  FConsumer.FreeOnTerminate := False;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FinalizeThreads;
  UnregisterLogger;
end;

procedure TMainForm.FinalizeThreads;
begin
  // Finaliza o Produtor primeiro, se ele existir
  if Assigned(FProducer) then
  begin
    FProducer.Terminate;
  end;

  // Em seguida, finaliza o Consumidor
  if Assigned(FConsumer) then
  begin
    FConsumer.Terminate;
    // Acorda o consumidor para que ele possa verificar a flag Terminated
    QueueNotEmpty.Release;
    FConsumer.WaitFor;
    FConsumer.Free;
  end;
end;

procedure TMainForm.StartButtonClick(Sender: TObject);
begin
  if Assigned(FProducer) and (not FProducer.Finished) then
  begin
    LogWrite('Aguarde a produ��o anterior terminar.');
    Exit;
  end;

  StartButton.Enabled := False;
  LogWrite('> Iniciando nova produ��o de tarefas...');
  // Cria um novo produtor para este ciclo
  FProducer := TProducerThread.Create(False);
  // Produtor � "dispare e esque�a"
  FProducer.FreeOnTerminate := True;
  FProducer.OnTerminate := ProducerThreadTerminated;
end;

procedure TMainForm.ProducerThreadTerminated(Sender: TObject);
begin
  // Quando o produtor termina, limpamos a refer�ncia
  FProducer := nil;
  LogWrite('Produ��o conclu�da. Pode iniciar uma nova.');
  StartButton.Enabled := True;
end;

end.
