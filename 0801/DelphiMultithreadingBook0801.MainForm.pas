unit DelphiMultithreadingBook0801.MainForm;

interface

uses
  System.Classes, Vcl.ComCtrls, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  // Importa a worker thread e o worker processor para acesso aos types
  DelphiMultithreadingBook0801.WorkerThread,
  DelphiMultithreadingBook0801.WorkerProcessor,
  DelphiMultithreadingBook.Utils;

type
  TMainForm = class(TForm)
    IniciarCalculoButton: TButton;
    CancelarCalculoButton: TButton;
    ProgressBar: TProgressBar;
    LogMemo: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure IniciarCalculoButtonClick(Sender: TObject);
    procedure CancelarCalculoButtonClick(Sender: TObject);
  private
    // Nossa instância da thread de trabalho
    FWorkerThread: TWorkerThread;

    // Callbacks a serem passados para o WorkerProcessor
    procedure UpdateProgress(const Text: string; Progress: Integer);
    procedure ReportThreadError(const Text: string);
    // Handler para OnTerminate da thread
    procedure WorkerThreadTerminate(Sender: TObject);

    // Controla o estado dos botões
    procedure SetButtonStates(RunningState: TRunningState);
    procedure FinalizeThread;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.SysUtils,
  Vcl.Dialogs;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplicação iniciada.');
  // Estado inicial: nada rodando
  SetButtonStates(IsStopped);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FinalizeThread;
  UnregisterLogger;
end;

procedure TMainForm.SetButtonStates(RunningState: TRunningState);
begin
  IniciarCalculoButton.Enabled := RunningState = IsStopped;
  CancelarCalculoButton.Enabled := RunningState = IsRunning;
end;

procedure TMainForm.FinalizeThread;
begin
  // Garante que a thread seja terminada e liberada ao fechar o formulário
  if Assigned(FWorkerThread) then
  begin
    FWorkerThread.RequestCancel;
    // Solicita o cancelamento
    FWorkerThread.WaitFor;
    // Espera a thread terminar
    FWorkerThread.Free;
    // Libera o objeto thread
    FWorkerThread := nil;
  end;
end;

procedure TMainForm.UpdateProgress(const Text: string; Progress: Integer);
var
  Cancelled: Boolean;
begin
  Cancelled := Assigned(FWorkerThread)
    and FWorkerThread.Processor.CancelRequested
    and not Text.Contains('Progresso');

  if not Cancelled then
  begin
    LogWrite('[%d%%] %s', [Progress, Text]);
    ProgressBar.Position := Progress;
  end
  else
    LogWrite('%s', [Text]);
end;

procedure TMainForm.ReportThreadError(const Text: string);
begin
  LogWrite('ERRO REPORTADO: %s', [Text]);
  // Exemplo de notificação de erro
  ShowMessage(Text);
end;

procedure TMainForm.WorkerThreadTerminate(Sender: TObject);
var
  WorkerThread: TWorkerThread;
begin
  // Este evento é executado na thread principal (UI Thread)!
  WorkerThread := Sender as TWorkerThread;
  LogWrite('Cálculo finalizado na Thread (ID: %d).', [WorkerThread.ThreadID]);

  // Reabilita os botões para iniciar novo cálculo
  SetButtonStates(IsStopped);
end;


procedure TMainForm.IniciarCalculoButtonClick(Sender: TObject);
var
  Processor: TWorkerProcessor;
begin
  // Garante que qualquer thread anterior esteja finalizada e limpa
  FinalizeThread;

  LogWrite('> Iniciando cálculo na thread de trabalho...');
  // Desabilita iniciar, habilita cancelar
  SetButtonStates(IsRunning);
  ProgressBar.Max := 100;
  ProgressBar.Position := 0;

  // 1. Cria a instância do Processor e configura seus callbacks
  Processor := TWorkerProcessor.Create(UpdateProgress, ReportThreadError);

  // 2. Cria a WorkerThread, passando a instância do Processor
  FWorkerThread := TWorkerThread.Create(Processor);
  // Associa o handler de término
  FWorkerThread.OnTerminate := WorkerThreadTerminate;
  // Inicia a thread
  FWorkerThread.Start;
end;

procedure TMainForm.CancelarCalculoButtonClick(Sender: TObject);
begin
  if Assigned(FWorkerThread) and (not FWorkerThread.Finished) then
  begin
    LogWrite('Solicitando cancelamento do cálculo...');
    // Sinaliza o cancelamento para a thread
    FWorkerThread.RequestCancel;
    // O WorkerThreadTerminate cuidará de reabilitar os botões
    // após a thread finalizar
  end;
end;

end.
