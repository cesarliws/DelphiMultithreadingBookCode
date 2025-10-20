unit DelphiMultithreadingBook0201.MainForm;

interface

uses
  System.Classes, Vcl.Controls, Vcl.ComCtrls, Vcl.Forms, Vcl.StdCtrls,
  DelphiMultithreadingBook0201.WorkerThread,
  DelphiMultithreadingBook.Utils;

type
  TMainForm = class(TForm)
    IniciarThreadButton: TButton;
    PararThreadButton: TButton;
    ProgressBar: TProgressBar;
    LogMemo: TMemo;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure IniciarThreadButtonClick(Sender: TObject);
    procedure PararThreadButtonClick(Sender: TObject);
  private
    FWorkerThread: TWorkerThread;
    procedure FinalizeThread;
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
  LogWrite('Aplicação iniciada. Clique em "Iniciar Thread".');
  ProgressBar.Min := 0;
  ProgressBar.Max := 100;
  ProgressBar.Position := 0;
  SetButtonStates(IsStopped);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  // Garante que a thread seja terminada e liberada ao fechar o formulário
  FinalizeThread;
  UnregisterLogger;
end;

procedure TMainForm.IniciarThreadButtonClick(Sender: TObject);
begin
  FinalizeThread;
  LogWrite('> Iniciando thread de trabalho...');
  LogWrite('A interface continua responsiva.');
  ProgressBar.Position := 0;

  // Criamos uma instância da nossa thread
  FWorkerThread := TWorkerThread.Create(ProgressBar);
  FWorkerThread.OnTerminate := WorkerThreadTerminated;
  // Inicia a thread
  FWorkerThread.Start;

  SetButtonStates(IsRunning);
end;

procedure TMainForm.PararThreadButtonClick(Sender: TObject);
begin
  if Assigned(FWorkerThread) then
  begin
    LogWrite('Solicitando término da thread...');
    FinalizeThread;

    LogWrite('Thread finalizada e liberada.');
    SetButtonStates(IsStopped);
  end;
end;

procedure TMainForm.FinalizeThread;
begin
  if Assigned(FWorkerThread) then
  begin
    // Sinaliza para terminar
    FWorkerThread.Terminate;
    // Espera a thread realmente terminar
    FWorkerThread.WaitFor;
    // Libera o objeto thread
    FWorkerThread.Free;
    // Remove a referência da instância liberada
    FWorkerThread := nil;
  end;
end;

procedure TMainForm.SetButtonStates(RunningState: TRunningState);
begin
  IniciarThreadButton.Enabled := RunningState = IsStopped;
  PararThreadButton.Enabled := RunningState = IsRunning;
end;

procedure TMainForm.WorkerThreadTerminated(Sender: TObject);
begin
  SetButtonStates(IsStopped);
end;

end.
