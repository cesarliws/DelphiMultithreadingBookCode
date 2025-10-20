unit DelphiMultithreadingBook0406.MainForm;

interface

uses
  System.Classes, System.SysUtils, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  DelphiMultithreadingBook0406.WorkerWithRetryOnErrorThread;

type
  TMainForm = class(TForm)
    IniciarThreadComRetryButton: TButton;
    ExecutarAteFalharCheckBox: TCheckBox;
    LogMemo: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure IniciarThreadComRetryButtonClick(Sender: TObject);
  private
    FWorkerWithRetryOnErrorThread: TWorkerWithRetryOnErrorThread;
    procedure FinalizeThread;
    procedure WorkerThreadTerminate(Sender: TObject);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.Threading,
  WinApi.Messages,
  WinApi.Windows,
  DelphiMultithreadingBook.ExceptionUtils,
  DelphiMultithreadingBook.Utils;

procedure TMainForm.FinalizeThread;
begin
  if Assigned(FWorkerWithRetryOnErrorThread) then
  begin
    FWorkerWithRetryOnErrorThread.OnTerminate := nil;
    FWorkerWithRetryOnErrorThread.Terminate;
    FWorkerWithRetryOnErrorThread.WaitFor;
    FWorkerWithRetryOnErrorThread.Free;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogMemo.ScrollBars := ssVertical;
  ExecutarAteFalharCheckBox.Checked := True;
  LogWrite('Aplicação iniciada.');
  LogWrite('Clique em "Iniciar Thread com Retry" para testar o reprocessamento.');
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  UnregisterLogger;
  FinalizeThread;
end;

procedure TMainForm.IniciarThreadComRetryButtonClick(Sender: TObject);
const
  MAX_RETRIES = 3;
  INITIAL_DELAY_MS = 500;
begin
  FinalizeThread;
  LogWrite('> Iniciando Thread com Reprocessamento e Retry...');
  FWorkerWithRetryOnErrorThread := TWorkerWithRetryOnErrorThread.Create(
    MAX_RETRIES, INITIAL_DELAY_MS);
  FWorkerWithRetryOnErrorThread.OnTerminate := WorkerThreadTerminate;
end;

procedure TMainForm.WorkerThreadTerminate(Sender: TObject);
var
  RunAgain: Boolean;
  WorkerThread: TWorkerWithRetryOnErrorThread;
begin
  // Este método é executado na thread principal (UI thread)
  WorkerThread := Sender as TWorkerWithRetryOnErrorThread;
  RunAgain := False;
  LogWrite('Thread %d TERMINOU.', [WorkerThread.ThreadID]);

  // Verifica se a thread coletou erros
  if Assigned(WorkerThread.Error) then
  begin
    // Usa o procedimento HandlePotentialAggregateException para exibir o erro
    // (que pode ser EAggregateException) na Events Window
    HandlePotentialAggregateException(WorkerThread.Error);

    LogWrite('--- Exceção Agregada capturada! ---');
    LogWrite('Total de falhas registradas: %d', [WorkerThread.Error.Count]);
    LogWrite('----------------------------------------');
    LogWrite('');
  end
  else
  begin
    LogWrite('Thread concluída sem erros reportados.');
    RunAgain := ExecutarAteFalharCheckBox.Checked
      and not (csDestroying in ComponentState);
  end;

  if RunAgain then
  begin
    TThread.ForceQueue(nil,
      procedure
      begin
        if (csDestroying in ComponentState) then
          Exit;
        LogWrite('');
        LogWrite('Executando novamente...');
        IniciarThreadComRetryButton.Click;
        SendMessage(LogMemo.Handle, EM_LINESCROLL, 0,LogMemo.Lines.Count);
      end);
  end;
end;

end.

