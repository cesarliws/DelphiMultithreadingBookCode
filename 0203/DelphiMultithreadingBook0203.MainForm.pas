unit DelphiMultithreadingBook0203.MainForm;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  DelphiMultithreadingBook.Utils;

type
  TMainForm = class(TForm)
    LogMemo: TMemo;
    IniciarSemSincronizacaoButton: TButton;
    IniciarComSincronizacaoButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure IniciarSemSincronizacaoButtonClick(Sender: TObject);
    procedure IniciarComSincronizacaoButtonClick(Sender: TObject);
  private
    FOrchestratorThread: TThread;
    procedure FinalizeThread;
    procedure IniciarTeste(UseLocking: Boolean);
    procedure SetButtonStates(RunningState: TRunningState);
  end;

var
  MainForm: TMainForm;

implementation

uses
  System.Diagnostics,
  System.SysUtils,
  DelphiMultithreadingBook0203.SharedData,
  DelphiMultithreadingBook0203.WorkerThread;

{$R *.dfm}

type
  // Definição da Thread Orquestradora
  TTestOrchestratorThread = class(TThread)
  private
    FUseLocking: Boolean;
  public
    constructor Create(UseLocking: Boolean);
    procedure Execute; override;
  end;

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplicação iniciada.');
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FinalizeThread;
  UnregisterLogger;
end;

procedure TMainForm.FinalizeThread;
begin
  if Assigned(FOrchestratorThread) then
  begin
    FOrchestratorThread.Terminate;
    FOrchestratorThread.WaitFor;
    FOrchestratorThread.Free;
    FOrchestratorThread := nil;
  end;
end;

procedure TMainForm.IniciarTeste(UseLocking: Boolean);
begin
  FinalizeThread;
  SetButtonStates(IsRunning);
  ContadorGlobal := 0;

  if UseLocking then
    LogWrite('--- Iniciando Teste COM Sincronização ---')
  else
    LogWrite('--- Iniciando Teste SEM Sincronização (Esperado Falhar) ---');

  // Cria e inicia a thread orquestradora
  FOrchestratorThread := TTestOrchestratorThread.Create(UseLocking);
end;

procedure TMainForm.IniciarComSincronizacaoButtonClick(Sender: TObject);
begin
  IniciarTeste(True);
end;

procedure TMainForm.IniciarSemSincronizacaoButtonClick(Sender: TObject);
begin
  IniciarTeste(False);
end;

procedure TMainForm.SetButtonStates(RunningState: TRunningState);
begin
  IniciarComSincronizacaoButton.Enabled := RunningState = IsStopped;
  IniciarSemSincronizacaoButton.Enabled := RunningState = IsStopped;
  Repaint;
end;

{ TTestOrchestratorThread }

constructor TTestOrchestratorThread.Create(UseLocking: Boolean);
begin
  // Inicia imediatamente
  inherited Create(False);
  FreeOnTerminate := False;
  FUseLocking := UseLocking;
end;

procedure TTestOrchestratorThread.Execute;
const
  NUM_THREADS = 10;
  INCREMENTS_PER_THREAD = 100000;
var
  i: Integer;
  Stopwatch: TStopwatch;
  Threads: TArray<TWorkerThread>;
begin
  Stopwatch := TStopwatch.StartNew;
  SetLength(Threads, NUM_THREADS);

  try
    // Cria e inicia todas as threads de trabalho
    for i := 0 to High(Threads) do
    begin
      if Terminated then Exit;
      Threads[i] := TWorkerThread.Create(FUseLocking, INCREMENTS_PER_THREAD);
      Threads[i].Start;
    end;

    // Espera todas as threads terminarem
    for i := 0 to High(Threads) do
    begin
      // Permite que a própria orquestradora seja cancelada
      if Terminated then
        Exit;
      Threads[i].WaitFor;
    end;

  finally
    // Garante a liberação das threads de trabalho
    for i := 0 to High(Threads) do
      Threads[i].Free;
  end;

  Stopwatch.Stop;

  // Envia o resultado final para a UI de forma segura
  TThread.Queue(nil,
    procedure
    var
      ResultadoEsperado: Integer;
    begin
      ResultadoEsperado := NUM_THREADS * INCREMENTS_PER_THREAD;
      LogWrite('Concluído. Valor final: %d (Esperado: %d)',
        [ContadorGlobal, ResultadoEsperado]);

      if ContadorGlobal <> ResultadoEsperado then
        LogWrite('>>> OCORREU UMA RACE CONDITION! <<<')
      else
        LogWrite('>>> Resultado correto! <<<');

      LogWrite('Tempo de execução: %s ms',
        [Stopwatch.ElapsedMilliseconds.ToString]);

      MainForm.SetButtonStates(IsStopped);
    end);
end;

end.
