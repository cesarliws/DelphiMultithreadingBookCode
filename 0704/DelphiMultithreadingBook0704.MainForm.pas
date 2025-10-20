unit DelphiMultithreadingBook0704.MainForm;

interface

uses
  System.Classes, System.SysUtils, System.Threading,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls,
  DelphiMultithreadingBook.Utils;

type
  TMainForm = class(TForm)
    StartDefaultPoolButton: TButton;
    StartCustomPoolButton: TButton;
    CancelButton: TButton;
    LogMemo: TMemo;
    StatsLabel: TLabel;
    StatsTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

    procedure StartDefaultPoolButtonClick(Sender: TObject);
    procedure StartCustomPoolButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
    procedure StatsTimerTimer(Sender: TObject);
  private
    FCurrentMonitoringPool: TThreadPool;
    FCustomPool: TThreadPool;
    FProcessingTask: ITask;

    procedure RunTest(Pool: TThreadPool; const Title: string);
    procedure SetButtonsEnabled(RunningState: TRunningState);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.Diagnostics,
  System.SyncObjs;

const
  NUM_FILES = 50;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite(
    'Execute os testes mais de uma vez, na primeira vez o pool será criado.');
  SetButtonsEnabled(IsStopped);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  UnregisterLogger;

  if Assigned(FProcessingTask) then
    FProcessingTask.Cancel;
  // O pool padrão é gerenciado pela RTL. Liberamos apenas o nosso.
  if Assigned(FCustomPool) then
    FCustomPool.Free;
end;

procedure TMainForm.StartCustomPoolButtonClick(Sender: TObject);
begin
  if not Assigned(FCustomPool) then
  begin
    LogWrite('Criando pool de threads personalizado com 2 workers...');
    FCustomPool := TThreadPool.Create;
    FCustomPool.SetMinWorkerThreads(2);
    FCustomPool.SetMaxWorkerThreads(2);
  end;
  RunTest(FCustomPool, '> Iniciando teste com Pool Limitado (2 Threads)');
end;

procedure TMainForm.StartDefaultPoolButtonClick(Sender: TObject);
begin
  RunTest(TThreadPool.Default, '> Iniciando teste com Pool Padrão');
end;

procedure TMainForm.CancelButtonClick(Sender: TObject);
begin
  if Assigned(FProcessingTask) then
  begin
    LogWrite('Solicitando cancelamento...');
    FProcessingTask.Cancel;
  end;
end;

procedure TMainForm.StatsTimerTimer(Sender: TObject);
var
  ActiveThreads: Integer;
  Stats: TThreadPoolStats;
begin
  if Assigned(FCurrentMonitoringPool) then
  begin
    Stats := TThreadPoolStats.Get(FCurrentMonitoringPool);
    ActiveThreads := Stats.WorkerThreadCount - Stats.IdleWorkerThreadCount;
    StatsLabel.Caption := Format(
      'Pool Stats | Ativas: %d | Ociosas: %d | Em Fila: %d | Total: %d', [
      ActiveThreads,
      Stats.IdleWorkerThreadCount,
      Stats.QueuedRequestCount,
      Stats.WorkerThreadCount]);
  end;
end;

procedure TMainForm.RunTest(Pool: TThreadPool; const Title: string);
var
  Stopwatch: TStopwatch;
  ProcessedCount: Integer;
begin
  if Assigned(FProcessingTask) then
    Exit;

  LogWrite(Title);
  SetButtonsEnabled(IsRunning);

  FCurrentMonitoringPool := Pool;
  StatsTimer.Enabled := True;
  Stopwatch := TStopwatch.StartNew;
  ProcessedCount := 0;

  FProcessingTask := TTask.Run(
    procedure
    begin
      try
        // Bloco de trabalho principal
        TParallel.For(1, NUM_FILES,
          procedure(Index: Integer; State: TParallel.TLoopState)
          begin
            // Permite o cancelamento
            FProcessingTask.CheckCanceled;
            Sleep(100 + Random(200));
            TInterlocked.Increment(ProcessedCount);
          end);
      finally
        // Este bloco SEMPRE será executado, garantindo a atualização da UI.
        Stopwatch.Stop;
        TThread.Queue(nil,
          procedure
          begin
            // Verifica o status final da tarefa para logar o resultado correto
            if FProcessingTask.Status = TTaskStatus.Canceled then
              LogWrite('Cancelado após processar %d arquivos.', [ProcessedCount])
            else if FProcessingTask.Status = TTaskStatus.Exception then
              LogWrite('Tarefa falhou após %d ms.', [Stopwatch.ElapsedMilliseconds])
            else
              LogWrite('Concluído! Processados %d arquivos em %d ms.',
                [ProcessedCount, Stopwatch.ElapsedMilliseconds]);

            // Limpeza final da UI
            SetButtonsEnabled(IsStopped);
            StatsTimer.Enabled := False;
            StatsLabel.Caption := 'Estatísticas do Pool: -';
            FProcessingTask := nil;
          end);
      end;
    end, Pool);
end;

procedure TMainForm.SetButtonsEnabled(RunningState: TRunningState);
begin
  StartDefaultPoolButton.Enabled := RunningState = IsStopped;
  StartCustomPoolButton.Enabled := RunningState = IsStopped;
  CancelButton.Enabled := RunningState = IsRunning;
end;

end.
