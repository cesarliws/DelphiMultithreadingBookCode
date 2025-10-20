unit DelphiMultithreadingBook0402.MainForm;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  DelphiMultithreadingBook0402.WorkerThread,
  DelphiMultithreadingBook.Utils;

type
  TMainForm = class(TForm)
    IniciarThreadButton: TButton;
    PararThreadButton: TButton;
    LogMemo: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure IniciarThreadButtonClick(Sender: TObject);
    procedure PararThreadButtonClick(Sender: TObject);
  private
    FWorkerThread: TWorkerThread;
    procedure FinalizarThread;
    procedure SetButtonStates(RunningState: TRunningState);
    procedure WorkerThreadTerminated(Sender: TObject);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplicação iniciada. Clique em "Iniciar Thread" para começar.');
  SetButtonStates(IsStopped);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  // Garante que a thread seja terminada e liberada ao fechar o formulário
  FinalizarThread;
  UnregisterLogger;
end;

procedure TMainForm.IniciarThreadButtonClick(Sender: TObject);
begin
  // Finaliza qualquer instância de processamento anterior
  FinalizarThread;
  LogWrite('> Iniciando thread de trabalho (para terminação gentil)...');

  // Cria a thread
  FWorkerThread := TWorkerThread.Create(1);
  FWorkerThread.OnTerminate := WorkerThreadTerminated;
  FWorkerThread.Start;
  LogWrite('Aguarde Processamento ou clique em "Parar Thread" para encerrar...');

  SetButtonStates(IsRunning);
  PararThreadButton.SetFocus;
end;

procedure TMainForm.PararThreadButtonClick(Sender: TObject);
begin
  LogWrite('Solicitando término gentil da thread...');
  FinalizarThread;
  LogWrite('Thread terminada e liberada com sucesso.');
end;

procedure TMainForm.SetButtonStates(RunningState: TRunningState);
begin
  if csDestroying in ComponentState then
    Exit;
  IniciarThreadButton.Enabled := RunningState = IsStopped;
  PararThreadButton.Enabled := RunningState = IsRunning;
end;

procedure TMainForm.WorkerThreadTerminated(Sender: TObject);
begin
  if csDestroying in ComponentState then
    Exit;

  LogWrite('A thread concluiu seu trabalho...');
  SetButtonStates(IsStopped);
  IniciarThreadButton.SetFocus;
end;

procedure TMainForm.FinalizarThread;
begin
  if Assigned(FWorkerThread) then
  begin
    // Sinaliza para a thread terminar cooperativamente
    FWorkerThread.Terminate;
    // Espera a thread realmente terminar
    FWorkerThread.WaitFor;
    // Libera o objeto thread
    FWorkerThread.Free;
    // Limpa a referência;
    FWorkerThread := nil;
  end;
end;

end.
