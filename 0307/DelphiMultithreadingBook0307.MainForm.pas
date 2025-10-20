unit DelphiMultithreadingBook0307.MainForm;

interface

uses
  System.Classes, System.SyncObjs,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  DelphiMultithreadingBook.Utils;

type
  TMainForm = class(TForm)
    StartWorkersButton: TButton;
    LogMemo: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure StartWorkersButtonClick(Sender: TObject);
  private
    FOrchestrator: TThread;
    procedure RunTask(Countdown: TCountdownEvent; TaskNumber: Integer);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.Diagnostics,
  System.SysUtils;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplicação Iniciada.');
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  UnregisterLogger;
  if Assigned(FOrchestrator) then
  begin
    FOrchestrator.Terminate;
  end;
end;

procedure TMainForm.RunTask(Countdown: TCountdownEvent; TaskNumber: Integer);
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      WorkTime: Integer;
    begin
      // Simula trabalho de 1 a 4 segundos
      WorkTime := Random(3000) + 1000;
      // Usa a variável 'TaskNumber' que foi capturada do escopo externo
      LogWrite(Format('..Worker %d: iniciando trabalho de %d ms.',
        [TaskNumber, WorkTime]));
      Sleep(WorkTime);
      LogWrite(Format('..Worker %d: finalizou.', [TaskNumber]));

      // Cada worker, ao terminar, decrementa a contagem
      Countdown.Signal;
    end
  ).Start;
end;

procedure TMainForm.StartWorkersButtonClick(Sender: TObject);
const
  WORKER_COUNT = 5;
var
  Countdown: TCountdownEvent;
  Stopwatch: TStopwatch;
  i: Integer;
begin
  LogMemo.Lines.Clear;
  LogWrite(Format('> Iniciando %d workers...', [WORKER_COUNT]));
  StartWorkersButton.Enabled := False;

  // 1. Inicializa o evento com a contagem de workers
  Countdown := TCountdownEvent.Create(WORKER_COUNT);
  Stopwatch := TStopwatch.StartNew;

  for i := 1 to WORKER_COUNT do
  begin
    RunTask(Countdown, i);
  end;

  LogWrite('Todas as tarefas foram disparadas. UI continua responsiva.');
  LogWrite('Aguardando a conclusão de todas...');

  // 3. CRIA UMA TAREFA ORQUESTRADORA PARA ESPERAR SEM BLOQUEAR A UI
  FOrchestrator := TThread.CreateAnonymousThread(
    procedure
    begin
      // 4. A thread orquestradora bloqueia aqui, não a thread principal
      Countdown.WaitFor;
      Stopwatch.Stop;

      // 5. Após a conclusão, notifica a UI de forma segura
      TThread.Queue(nil,
        procedure
        begin
          LogWrite('------------------------------------');
          LogWrite(Format('TODAS AS TAREFAS FINALIZARAM em %d ms.',
            [Stopwatch.ElapsedMilliseconds]));
          StartWorkersButton.Enabled := True;
          Countdown.Free;
          FOrchestrator := nil;
        end);
    end
  );
  FOrchestrator.Start;
end;

end.
