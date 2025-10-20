unit DelphiMultithreadingBook0604.MainForm;

interface

uses
  System.Classes, System.Threading,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  DelphiMultithreadingBook.Utils;

type
  TMainForm = class(TForm)
    WaitForAllButton: TButton;
    WaitForAnyButton: TButton;
    ParallelJoinButton: TButton;
    LogMemo: TMemo;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure WaitForAllButtonClick(Sender: TObject);
    procedure WaitForAnyButtonClick(Sender: TObject);
    procedure ParallelJoinButtonClick(Sender: TObject);
  private
    FOrchestrator: ITask;
    procedure SetButtonsState(RunningState: TRunningState);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.Diagnostics,
  System.SyncObjs,
  System.SysUtils;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplica��o iniciada.');
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not Assigned(FOrchestrator);
  if not CanClose then
  begin
    LogWrite('* Aguarde a Tarefa finalizar para fechar esta Janela!')
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  UnregisterLogger;
end;

procedure TMainForm.WaitForAllButtonClick(Sender: TObject);
var
  Stopwatch: TStopwatch;
  Tasks: array of ITask;
  TotalValue: Integer;
begin
  LogWrite('--- Teste TTask.WaitForAll ---');

  SetButtonsState(IsRunning);
  Stopwatch := TStopwatch.StartNew;
  TotalValue := 0;

  // Cria duas tasks que simulam trabalho e modificam uma vari�vel compartilhada
  SetLength(Tasks, 2);
  Tasks[0] := TTask.Run(
    procedure
    begin
      DebugLogWrite('Task 1: Iniciando (3 segundos)...');
      // 3 segundos
      Sleep(3000);
      // Adiciona valor (simulado, ver T�pico 7.2)
      TInterlocked.Add(TotalValue, 3000);
      DebugLogWrite('Task 1: Conclu�da.');
    end
  );

  Tasks[1] := TTask.Run(
    procedure
    begin
      DebugLogWrite('Task 2: Iniciando (5 segundos)...');
      // 5 segundos
      Sleep(5000);
      // Adiciona valor (simulado, ver T�pico 7.2)
      TInterlocked.Add(TotalValue, 5000);
      DebugLogWrite('Task 2: Conclu�da.');
    end
  );

  FOrchestrator := TTask.Run(
    procedure
    var
      ExceptionMessage: string;
    begin
      try
        // Espera todas as tasks terminarem sem bloquear a UI
        TTask.WaitForAll(Tasks);
        Stopwatch.Stop;

        // O resultado � enfileirado para a UI
        TThread.Queue(nil,
          procedure
          begin
            LogWrite('WaitForAll conclu�do em %d ms. Valor total: %d.',
              [Stopwatch.ElapsedMilliseconds, TotalValue]);
            SetButtonsState(IsStopped);
          end);
      except
        on E: Exception do
        begin
          Stopwatch.Stop;
          ExceptionMessage := E.ToString;
          TThread.Queue(nil,
            procedure
            begin
              LogWrite('WaitForAll falhou: %s', [ExceptionMessage]);
              SetButtonsState(IsStopped);
            end);
        end;
      end;
      SetLength(Tasks, 0);
      FOrchestrator := nil;
    end);

  LogWrite('Tarefas disparadas. A UI continua responsiva enquanto aguarda...');
end;

procedure TMainForm.WaitForAnyButtonClick(Sender: TObject);

  function CreateTask(TaskIndex: Integer): ITask;
  begin
    Result := TTask.Run(
      procedure
      begin
        LogWrite('Task %d: Iniciando...', [TaskIndex]);

        // Dura��o aleat�ria (0.5s a 1.5s)
        Sleep(Random(1000) + 500);

        // Simula falha na Task 1 (50% de chance)
        if (TaskIndex = 1) and (Random(2) = 0) then
        begin
          LogWrite('Task %d: Lan�ando exce��o simulada!', [TaskIndex]);
          raise Exception.CreateFmt('Erro simulado na Task %d', [TaskIndex]);
        end;

        LogWrite('Task %d: Conclu�da.', [TaskIndex]);
      end
    );
  end;
var
  CompletedIndex: Integer;
  i: Integer;
  Stopwatch: TStopwatch;
  Tasks: array of ITask;
begin
  LogWrite('--- Teste TTask.WaitForAny ---');
  SetButtonsState(IsRunning);
  Stopwatch := TStopwatch.StartNew;

  SetLength(Tasks, 3);
  for i := 0 to High(Tasks) do
  begin
    // A ITask � criada em uma function, para garantir que o m�todo an�nimo de
    // cada task capture o valor correto (0, 1, 2), em vez de todas verem o
    // valor final de 'i'.
    Tasks[i] := CreateTask(i);
  end;

  FOrchestrator := TTask.Run(
    procedure
    var
      ExceptionMessage: string;
    begin
      // Espera qualquer task terminar
      try
        // Aguarda por qualquer tarefa sem bloquear a UI
        CompletedIndex := TTask.WaitForAny(Tasks);
        Stopwatch.Stop;

        TThread.Queue(nil,
          procedure
          begin
            if CompletedIndex <> -1 then
            begin
              LogWrite('WaitForAny: Task %d conclu�da em %d ms.',
                [CompletedIndex, Stopwatch.ElapsedMilliseconds]);
            end
            else
            begin
              LogWrite(
                'WaitForAny: Nenhuma task conclu�da dentro do timeout em %d ms.',
                [Stopwatch.ElapsedMilliseconds]);
            end;
          end);
      except
        on E: Exception do
        begin
          Stopwatch.Stop;
          ExceptionMessage := E.ToString;

          TThread.Queue(nil,
            procedure
            begin
              LogWrite('WaitForAny falhou em %d ms: %s',
                [Stopwatch.ElapsedMilliseconds, ExceptionMessage]);
            end);
        end;
      end;

      try
        // Espera por todas as tarefas restantes para garantir a limpeza
        TTask.WaitForAll(Tasks);
      except on
        E: Exception do
        begin
          ExceptionMessage := E.ToString;

          TThread.Queue(nil,
            procedure
            begin
              LogWrite('WaitForAny falhou em %d ms: %s',
                [Stopwatch.ElapsedMilliseconds, ExceptionMessage]);
            end);
        end;
      end;

      TThread.Queue(nil,
        procedure
        begin
          SetButtonsState(IsStopped);
        end);

      SetLength(Tasks, 0);
      FOrchestrator := nil;
    end);

  LogWrite('Tarefas disparadas. A UI continua responsiva enquanto aguarda...');
end;

procedure TMainForm.ParallelJoinButtonClick(Sender: TObject);
var
  JoinTask: ITask;
  Stopwatch: TStopwatch;
begin
  LogWrite('--- Teste TParallel.Join ---');
  SetButtonsState(IsRunning);
  Stopwatch := TStopwatch.StartNew;

  // Cria e inicia uma tarefa que agrupa tr�s procedimentos em paralelo
  JoinTask := TParallel.Join([
    // Procedimento 1
    procedure
    begin
      DebugLogWrite('Join Task 1: Iniciando (2 segundos)...');
      Sleep(2000);
      DebugLogWrite('Join Task 1: Conclu�da.');
    end,
    // Procedimento 2
    procedure
    begin
      DebugLogWrite('Join Task 2: Iniciando (4 segundos)...');
      Sleep(4000);
      DebugLogWrite('Join Task 2: Conclu�da.');
    end,
    // Procedimento 3
    procedure
    begin
      DebugLogWrite('Join Task 3: Iniciando (1 segundo)...');
      Sleep(1000);
      DebugLogWrite('Join Task 3: Conclu�da.');
    end
  ]);

  FOrchestrator := TTask.Run(
    procedure
    var
      ExceptionMessage: string;
    begin
      // Espera pela conclus�o da JoinTask
      // (que s� termina quando todos os procedimentos internos terminarem)
      try
        // Bloqueia esta thread (UI thread) at� todas as join tasks terminarem
        JoinTask.Wait;
        Stopwatch.Stop;

        TThread.Queue(nil,
          procedure
          begin
            LogWrite('TParallel.Join conclu�do em %d ms. (Esperado: ~4000ms)',
              [Stopwatch.ElapsedMilliseconds]);
          end);
      except
        on E: EAggregateException do
        begin
          Stopwatch.Stop;
          ExceptionMessage := E.ToString;
          TThread.Queue(nil,
            procedure
            begin
              LogWrite('TParallel.Join falhou com exce��o agregada em %d ms: %s',
                [Stopwatch.ElapsedMilliseconds, ExceptionMessage]);
            end);
        end;
      end;

      TThread.Queue(nil,
        procedure
        begin
          SetButtonsState(IsStopped);
        end);

      JoinTask := nil;
      FOrchestrator := nil;
    end);

  // A Thread principal pode fazer outras coisas aqui.
  LogWrite('TParallel.Join disparado!');
end;

procedure TMainForm.SetButtonsState(RunningState: TRunningState);
begin
  if csDestroying in ComponentState then
    Exit;

  WaitForAllButton.Enabled := RunningState = IsStopped;
  WaitForAnyButton.Enabled := RunningState = IsStopped;
  ParallelJoinButton.Enabled := RunningState = IsStopped;
end;

end.

