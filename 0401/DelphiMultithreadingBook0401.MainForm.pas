unit DelphiMultithreadingBook0401.MainForm;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  DelphiMultithreadingBook0401.PausableWorkerThread,
  DelphiMultithreadingBook.Utils;

type
  TMainForm = class(TForm)
    IniciarThreadButton: TButton;
    LogMemo: TMemo;
    PausarThreadButton: TButton;
    RetomarThreadButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure IniciarThreadButtonClick(Sender: TObject);
    procedure PausarThreadButtonClick(Sender: TObject);
    procedure RetomarThreadButtonClick(Sender: TObject);
  private
    FPausableThread: TPausableWorkerThread;
    procedure FinalizeThread;
    procedure PausableThreadTerminated(Sender: TObject);
    procedure SetButtonStates(RunningState: TRunningState);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  DelphiMultithreadingBook0401.SharedData;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplicação iniciada. Clique no botão para iniciar a thread.');
  SetButtonStates(IsStopped);
  LogMemo.ScrollBars := ssVertical;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  UnregisterLogger;
  FinalizeThread;
end;

procedure TMainForm.IniciarThreadButtonClick(Sender: TObject);
begin
  SetButtonStates(IsRunning);
  FinalizeThread;
  LogWrite('> Iniciando Thread Pausável...');
  // Garante que o evento comece sinalizado (não pausado)
  PauseEvent.SetEvent;
  FPausableThread := TPausableWorkerThread.Create(1, LogWrite);
  FPausableThread.OnTerminate := PausableThreadTerminated;
end;

procedure TMainForm.PausarThreadButtonClick(Sender: TObject);
begin
  if Assigned(FPausableThread) then
  begin
    SetButtonStates(IsPaused);
    LogWrite('Solicitando PAUSA da Thread...');
    // Coloca o evento em estado não sinalizado
    PauseEvent.ResetEvent;
  end;
end;

procedure TMainForm.RetomarThreadButtonClick(Sender: TObject);
begin
  if Assigned(FPausableThread) then
  begin
    SetButtonStates(IsRunning);
    LogWrite('Solicitando RETOMADA da Thread...');
    // Coloca o evento em estado sinalizado
    PauseEvent.SetEvent;
  end;
end;

procedure TMainForm.FinalizeThread;
begin
  if Assigned(FPausableThread) then
  begin
    // TerminatedSet é invocado e sinaliza o evento para garantir que
    // a thread saia do estado de espera (WaitFor) caso esteja pausada,
    // permitindo seu término.
    FPausableThread.Terminate;
    // Aguarda a Thread finalizar antes de destruir
    FPausableThread.WaitFor;
    FPausableThread.Free;
    FPausableThread := nil;
  end;
end;

procedure TMainForm.PausableThreadTerminated(Sender: TObject);
begin
  LogWrite('Processamento da Thread Pausável Concluído.');
  SetButtonStates(IsStopped);
end;

procedure TMainForm.SetButtonStates(RunningState: TRunningState);
begin
  IniciarThreadButton.Enabled := RunningState = IsStopped;
  PausarThreadButton .Enabled := RunningState = IsRunning;
  RetomarThreadButton.Enabled := RunningState = IsPaused;
end;

end.

