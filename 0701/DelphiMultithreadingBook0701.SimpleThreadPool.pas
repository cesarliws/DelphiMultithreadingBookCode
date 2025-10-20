unit DelphiMultithreadingBook0701.SimpleThreadPool;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SyncObjs,
  System.SysUtils;

type
  // Define o tipo de "tarefa" que o pool vai executar
  TThreadPoolTask = TProc;

  // Classe interna para as threads do pool
  TThreadPoolWorker = class(TThread)
  private
    // Referência ao pool pai (TSimpleThreadPool)
    FThreadPool: TObject;
    // Flag para terminação gentil
    FShouldTerminate: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(Pool: TObject);
    // Método para sinalizar terminação
    procedure SignalTerminate;
  end;

  // O nosso Thread Pool simples
  TSimpleThreadPool = class(TObject)
  private
    FTaskQueue: TQueue<TThreadPoolTask>; // Fila de tarefas
    FQueueLock: TCriticalSection;        // Proteção da fila
    FNewTaskEvent: TEvent;               // Sinaliza novas tarefas
    FWorkerThreads: TObjectList<TThreadPoolWorker>; // Lista de threads no pool
    FActiveTaskCount: NativeInt;
    FMaxWorkers: Integer;                // Número máximo de workers
    FLastTaskId: Integer;

    function GetWorkerCount: Integer;
  public
    constructor Create(MaxWorkers: Integer = 0);
    destructor Destroy; override;

    function QueueTask(const Task: TThreadPoolTask): NativeInt;
    // Shutdown encerra o pool gentilmente
    procedure Shutdown;

    property WorkerCount: Integer read GetWorkerCount;
    property ActiveTaskCount: Integer read FActiveTaskCount;
  end;

implementation

uses
  DelphiMultithreadingBook.Utils;

{ TThreadPoolWorker }

constructor TThreadPoolWorker.Create(Pool: TObject);
begin
  // Cria suspensa
  inherited Create(True);
  // IMPORTANTE: FreeOnTerminate := False para que o pool gerencie a liberação
  FreeOnTerminate := False;
  FThreadPool := Pool;
  FShouldTerminate := False;
end;

procedure TThreadPoolWorker.SignalTerminate;
begin
  FShouldTerminate := True;
end;

procedure TThreadPoolWorker.Execute;
var
  Pool: TSimpleThreadPool;
  Task: TThreadPoolTask;
  TaskAvailable: Boolean;
begin
  Pool := FThreadPool as TSimpleThreadPool;
  DebugLogWrite('Worker Thread %d: Iniciada.', [ThreadID]);

  // Loop principal da thread do pool
  while not FShouldTerminate do
  begin
    TaskAvailable := False;
    Task := nil;

    Pool.FQueueLock.Enter;
    try
      if Pool.FTaskQueue.Count > 0 then
      begin
        // Workaround compiler error - E2010 Incompatible types:
        // 'TProc' and 'Procedure of object'
        // Task := Pool.FTaskQueue.Dequeue;
        var TempTask := Pool.FTaskQueue.Dequeue;
        Task := TempTask;
        TaskAvailable := True;

        // Se a fila zera, reseta o evento para esperar novamente (ManualReset)
        if Pool.FTaskQueue.Count = 0 then
          Pool.FNewTaskEvent.ResetEvent;
      end
    finally
      Pool.FQueueLock.Leave;
    end;

    if TaskAvailable then
    begin
      // Incrementa contador de tarefas ativas (ver **Tópico 7.2**)
      TInterlocked.Increment(Pool.FActiveTaskCount);
      DebugLogWrite('Worker Thread %d: Executando tarefa...', [ThreadID]);
      try
        Task(); // Executa a tarefa!
      except
        on E: Exception do
        begin
          DebugLogWrite('Worker Thread %d: Erro na tarefa: %s',
            [ThreadID, E.Message]);
          // Reportar o erro para a UI seria feito aqui (TThread.Queue)
          // Ex: TThread.Queue(nil, procedure begin ShowMessage('Erro!'); end);
        end;
      end;
      DebugLogWrite('Worker Thread %d: Tarefa concluída.', [ThreadID]);
      // Decrementa contador de tarefas ativas (ver **Tópico 7.2**)
      TInterlocked.Decrement(Pool.FActiveTaskCount);
    end
    else
    begin
      // Nenhuma tarefa na fila, espera por uma nova tarefa
      DebugLogWrite('Worker Thread %d: Aguardando por tarefas...', [ThreadID]);
      // Bloqueia até que um novo item seja sinalizado
      Pool.FNewTaskEvent.WaitFor(INFINITE);
    end;
  end; // FShouldTerminate loop

  DebugLogWrite('Worker Thread %d: Terminada gentilmente.', [ThreadID]);
end;

{ TSimpleThreadPool }

constructor TSimpleThreadPool.Create(MaxWorkers: Integer);
var
  i: Integer;
  Worker: TThreadPoolWorker;
begin
  inherited Create;
  FMaxWorkers := MaxWorkers;
  if FMaxWorkers <= 0 then
    // Pelo menos o número de núcleos
    FMaxWorkers := TThread.ProcessorCount;

  FTaskQueue := TQueue<TThreadPoolTask>.Create;
  FQueueLock := TCriticalSection.Create;
  // ManualReset, Inicia Não Sinalizado
  FNewTaskEvent := TEvent.Create(nil, True, False, '');
  // TObjectList<TThreadPoolWorker>.Create(True) para que a lista
  // libere os objetos ao ser liberada
  FWorkerThreads := TObjectList<TThreadPoolWorker>.Create(True);
  FActiveTaskCount := 0;
  FLastTaskId := 0;

  // Cria as threads do pool e as inicia (agora elas não se auto-liberam)
  for i := 1 to FMaxWorkers do
  begin
    Worker := TThreadPoolWorker.Create(Self);
    FWorkerThreads.Add(Worker);
    // Inicia a thread
    Worker.Start;
  end;

  DebugLogWrite('ThreadPool criado com %d workers.', [FMaxWorkers]);
end;

destructor TSimpleThreadPool.Destroy;
begin
  // Garante que o pool seja encerrado ao ser destruído
  Shutdown;
  FWorkerThreads.Free;
  FNewTaskEvent.Free;
  FQueueLock.Free;
  FTaskQueue.Free;
  inherited;
end;

function TSimpleThreadPool.GetWorkerCount: Integer;
begin
  Result := FWorkerThreads.Count;
end;

function TSimpleThreadPool.QueueTask(const Task: TThreadPoolTask): NativeInt;
begin
  // Gera um ID de tarefa único e thread-safe (ver **Tópico 7.2**)
  Result := TInterlocked.Increment(FLastTaskId);

  FQueueLock.Enter;
  try
    // Adiciona a tarefa à fila
    FTaskQueue.Enqueue(Task);
  finally
    FQueueLock.Leave;
  end;
  // Sinaliza que há uma nova tarefa
  FNewTaskEvent.SetEvent;
end;

procedure TSimpleThreadPool.Shutdown;
var
  Worker: TThreadPoolWorker;
begin
  DebugLogWrite('ThreadPool: Iniciando Shutdown...');
  // Sinaliza para todas as threads que devem terminar
  for Worker in FWorkerThreads do
  begin
    Worker.SignalTerminate;
    // Assegura que threads que estão no WaitFor sejam acordadas
    FNewTaskEvent.SetEvent;
  end;

  // Espera todas as threads terminarem (bloqueante)
  for Worker in FWorkerThreads do
  begin
    // Se a thread ainda não terminou, espera por ela.
    // Worker.Finished verifica se o Execute terminou.
    if not Worker.Finished then
      Worker.WaitFor;
  end;
  DebugLogWrite('ThreadPool: Shutdown concluído. Todas as threads terminadas.');
end;

end.
