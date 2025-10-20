unit DelphiMultithreadingBook0504.MainForm;

interface

uses
   System.Classes, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  DelphiMultithreadingBook.Utils;

type
  // Thread de trabalho simples para o nosso novo exemplo
  TWorkerThread = class(TThread)
  protected
    procedure Execute; override;
  end;

  TMainForm = class(TForm)
    StartWorkerButton: TButton;
    LogMemo: TMemo;
    LoadDataButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure LoadDataButtonClick(Sender: TObject);
    procedure StartWorkerButtonClick(Sender: TObject);
  private
    FWorkerThread: TWorkerThread;
    procedure AfterFormShowAsync;
    procedure LoadDataFromDatabase;
    procedure FinalizeThread;
    procedure SetButtonStates(RunningState: TRunningState);
    procedure WorkerTerminated(Sender: TObject);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  Winapi.Windows,
  DelphiMultithreadingBook0504.AsyncHelpers; // Helpers RunAsync

{ TWorkerThread }

procedure TWorkerThread.Execute;
var
  i: Integer;
begin
  for i := 1 to 5 do
  begin
    if Terminated then Break;

    // A thread de trabalho usa RunAsync para enfileirar uma atualiza��o na UI
    RunAsync(
      procedure
      begin
        LogWrite('Worker Thread: Progresso %d de 5', [i]);
      end);

    Sleep(1000);
  end;
end;

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplica��o iniciada.');
  SetButtonStates(IsStopped);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  UnregisterLogger;
  FinalizeThread;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
 LogWrite('Formul�rio exibido. Agendando carregamento de dados...');

  // Exemplo 1: Agendando uma tarefa a partir da MainThread
  RunAsync(AfterFormShowAsync);
end;

procedure TMainForm.AfterFormShowAsync;
begin
  SetButtonStates(IsRunning);
  try
    LogWrite('Executando AfterFormShowAsync na Main Thread...');
    Self.Repaint;
    // Agora, dentro deste m�todo, voc� pode chamar sua consulta
    LoadDataFromDatabase;
    StartWorkerButton.Enabled := True;
    StartWorkerButton.SetFocus;
  finally
    SetButtonStates(IsStopped);
  end;
end;

procedure TMainForm.LoadDataButtonClick(Sender: TObject);
begin
  LogWrite('> Bot�o Clicado: Agendando carregamento de dados...');
  // Tamb�m demonstra o agendamento a partir de um evento de clique
  RunAsync(LoadDataFromDatabase);
end;


procedure TMainForm.StartWorkerButtonClick(Sender: TObject);
begin
  FinalizeThread;
  LogWrite('> Iniciando Worker Thread que usar� o Dispatcher...');

  // Exemplo 2: Recebendo comunica��o de uma Worker Thread
  FWorkerThread := TWorkerThread.Create(True); // Cria suspensa
  FWorkerThread.OnTerminate := WorkerTerminated;
  FWorkerThread.FreeOnTerminate := False; // Gerenciamento manual
  FWorkerThread.Start;
  SetButtonStates(IsRunning);
end;

procedure TMainForm.FinalizeThread;
begin
  if Assigned(FWorkerThread) then
  begin
    FWorkerThread.Terminate;
    FWorkerThread.WaitFor;
    FWorkerThread.Free;
    FWorkerThread := nil;
  end;
end;

procedure TMainForm.LoadDataFromDatabase;
begin
  LogWrite('LoadDataFromDatabase: Iniciando opera��o BLOQUEANTE na MainThread...');
  SetButtonStates(IsRunning);

  // AVISO DID�TICO: Este Sleep(3000) ir� congelar a UI.
  // Ele est� aqui para demonstrar que o trabalho agendado pelo
  // dispatcher ainda executa na MainThread.
  Sleep(3000);

  LogWrite('LoadDataFromDatabase: Opera��o conclu�da.');
  SetButtonStates(IsStopped);
end;

procedure TMainForm.WorkerTerminated(Sender: TObject);
begin
  if csDestroying in ComponentState then
    Exit;

  // OnTerminate j� executa na MainThread, podemos atualizar a UI diretamente.
  LogWrite('Worker Thread: Processamento finalizado');
  SetButtonStates(IsStopped);
end;

procedure TMainForm.SetButtonStates(RunningState: TRunningState);
begin
  if csDestroying in ComponentState then
    Exit;

  StartWorkerButton.Enabled := RunningState = IsStopped;

  if RunningState = IsRunning then
    Screen.Cursor := crHourGlass
  else
    Screen.Cursor := crDefault;
end;

end.
