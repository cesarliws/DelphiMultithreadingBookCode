unit DelphiMultithreadingBook0403.MainForm;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  DelphiMultithreadingBook0403.PausableWorkerThread,
  DelphiMultithreadingBook.CancellationToken,
  DelphiMultithreadingBook.Utils;

type
  TMainForm = class(TForm)
    IniciarThreadButton: TButton;
    PararThreadButton: TButton;
    PausarThreadButton: TButton;
    RetomarThreadButton: TButton;
    LogMemo: TMemo;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

    procedure IniciarThreadButtonClick(Sender: TObject);
    procedure PararThreadButtonClick(Sender: TObject);
    procedure PausarThreadButtonClick(Sender: TObject);
    procedure RetomarThreadButtonClick(Sender: TObject);
  private
    // A fonte do token de cancelamento
    FCancellationTokenSource: TCancellationTokenSource;
    FPausableThread: TPausableWorkerThread;

    procedure PausableThreadTerminate(Sender: TObject);
    procedure SetButtonStates(RunningState: TRunningState);

    procedure CreateThread;
    procedure FinalizeThread;
    procedure InicializarSourceToken;
    procedure StopThread;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  DelphiMultithreadingBook0403.SharedData;

procedure TMainForm.CreateThread;
begin
  // Finaliza inst�ncia anterior da thread
  FinalizeThread;
  // Passa o token para a thread
  FPausableThread := TPausableWorkerThread.Create(1, FCancellationTokenSource.Token);
  FPausableThread.OnTerminate := PausableThreadTerminate;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplica��o iniciada. Clique no bot�o para iniciar a thread.');
  SetButtonStates(IsStopped);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  // StopThread ir� enviar o Cancelamento da(s) thread(s) e aguardar a sua
  // finaliza��o cooperativa para destruir a inst�ncia da thread antes de
  // continuar
  StopThread;

  // Libera a fonte do token de cancelamento
  if Assigned(FCancellationTokenSource) then
  begin
    // ATEN��O: o token source s� deve ser destru�do depois que as threads que
    // usam esta inst�ncia estiverem finalizadas.
    FCancellationTokenSource.Free;
  end;
  UnregisterLogger;
end;

procedure TMainForm.StopThread;
begin
  // Terminar a thread paus�vel gentilmente
  if Assigned(FPausableThread) then
  begin
    // Se a thread ainda estiver rodando, solicitamos o cancelamento
    if Assigned(FCancellationTokenSource) then
    begin
      // PASSO 1: Solicita o cancelamento
      FCancellationTokenSource.Cancel;
      // Assegura que a thread saia do WaitFor se estiver pausada
      PauseEvent.SetEvent;
    end;

    // PASSO 2: Espera a thread de trabalho realmente finalizar sua execu��o
    // Isso � importante para que o MainThread n�o tente acessar a thread
    // enquanto ela est� terminando.
    FPausableThread.WaitFor;
    FinalizeThread;
  end;
end;

procedure TMainForm.FinalizeThread;
begin
  if Assigned(FPausableThread) then
  begin
    // Se a thread terminou todos os passos normalmente limpar a referencia
    FPausableThread.Free;
    FPausableThread := nil;
  end;
end;

procedure TMainForm.InicializarSourceToken;
begin
  if not Assigned(FCancellationTokenSource) then
    // Cria a fonte do token de cancelamento
    FCancellationTokenSource := TCancellationTokenSource.Create
  else
    // Se a fonte j� existir reinicia o token
    FCancellationTokenSource.Reset;
end;

procedure TMainForm.SetButtonStates(RunningState: TRunningState);
begin
  if csDestroying in ComponentState then
    Exit;

  IniciarThreadButton.Enabled := RunningState = IsStopped;
  PausarThreadButton.Enabled := RunningState = IsRunning;
  RetomarThreadButton.Enabled := RunningState = IsPaused;
  PararThreadButton.Enabled := RunningState in [IsRunning, IsPaused];

  if not Visible then
    Exit;

  case RunningState of
    IsRunning: PausarThreadButton.SetFocus;
    IsPaused: RetomarThreadButton.SetFocus;
    IsStopped: IniciarThreadButton.SetFocus;
  end;
end;

procedure TMainForm.PausableThreadTerminate(Sender: TObject);
begin
  SetButtonStates(IsStopped);
end;

procedure TMainForm.IniciarThreadButtonClick(Sender: TObject);
begin
  SetButtonStates(IsRunning);
  LogWrite('> Iniciando Thread Paus�vel (com CancellationToken)...');
  StopThread;
  InicializarSourceToken;
  CreateThread;
end;

procedure TMainForm.PararThreadButtonClick(Sender: TObject);
begin
  if Assigned(FPausableThread) then
  begin
    LogWrite('Solicitando TERMINAR Thread Paus�vel (com CancellationToken)...');
    StopThread;
    LogWrite('Thread Paus�vel terminada.');
  end;
end;

procedure TMainForm.PausarThreadButtonClick(Sender: TObject);
begin
  if Assigned(FPausableThread) then
  begin
    LogWrite('Solicitando PAUSA da Thread...');
    PauseEvent.ResetEvent;
    SetButtonStates(IsPaused);
  end;
end;

procedure TMainForm.RetomarThreadButtonClick(Sender: TObject);
begin
  if Assigned(FPausableThread) then
  begin
    LogWrite('Solicitando RETOMADA da Thread...');
    PauseEvent.SetEvent;
    SetButtonStates(IsRunning);
  end;
end;

end.
