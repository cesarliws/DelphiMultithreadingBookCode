unit DelphiMultithreadingBook0701.MainForm;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  DelphiMultithreadingBook0701.SimpleThreadPool,
  DelphiMultithreadingBook.Utils;

type
  TMainForm = class(TForm)
    IniciarThreadPoolButton: TButton;
    PararThreadPoolButton: TButton;
    QueueTaskThreadPoolButton: TButton;
    LogMemo: TMemo;
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure IniciarThreadPoolButtonClick(Sender: TObject);
    procedure PararThreadPoolButtonClick(Sender: TObject);
    procedure QueueTaskThreadPoolButtonClick(Sender: TObject);
  private
    // Nossa instância do Thread Pool
    FThreadPool: TSimpleThreadPool;
    procedure SetButtonStates(RunningState: TRunningState);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.SysUtils;

const
  // Para versões Unicode do Delphi
  EnviandoParaFila = #$2192; // seta direita
  TarefaAgendada = #$25CF;   // círculo cheio
  TarefaFinalizada = #$2713; // check mark
  TodasTarefasConcluídas = #$2705; // heavy check mark

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplicação iniciada.');
  SetButtonStates(IsStopped);
  LogMemo.ScrollBars := ssVertical;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  UnregisterLogger;
  if Assigned(FThreadPool) then
  begin
    // O destrutor do pool cuidará do Shutdown
    FThreadPool.Free;
    FThreadPool := nil;
  end;
end;

procedure TMainForm.IniciarThreadPoolButtonClick(Sender: TObject);
begin
  if not Assigned(FThreadPool) then
  begin
   LogWrite('Criando Thread Pool...');

    // Cria um pool com 3 threads worker
    FThreadPool := TSimpleThreadPool.Create(3);
    LogWrite('Thread Pool criado. Queuing tasks...');
    LogWrite('Clique em "QueueTaskThreadPoolButton" várias vezes para ver as ' +
      'tarefas serem executadas.');
    SetButtonStates(IsRunning);
    QueueTaskThreadPoolButton.SetFocus;
  end
  else
  begin
    LogMemo.Lines.Add('Thread Pool já está ativo.');
  end;
end;

procedure TMainForm.PararThreadPoolButtonClick(Sender: TObject);
begin
  if Assigned(FThreadPool) then
  begin
    LogWrite('> Requisitando Shutdown do Thread Pool...');

    // Libera o objeto pool
    FThreadPool.Free;
    FThreadPool := nil;
    LogWrite('Thread Pool encerrado.');

    SetButtonStates(IsStopped);
    IniciarThreadPoolButton.SetFocus;
  end;
end;

procedure TMainForm.QueueTaskThreadPoolButtonClick(Sender: TObject);
var
  TaskId: Integer;
begin
  if not Assigned(FThreadPool) then
    Exit;

  QueueTaskThreadPoolButton.Enabled := False;
  try
    LogWrite(EnviandoParaFila + ' Enviando Tarefa para enfileiramento no Thread Pool...');
    TaskId := FThreadPool.QueueTask(
      // Esta é a tarefa que será executada por um worker do pool
      procedure
      begin
        DebugLogWrite('Task %d (Worker %d): Iniciando processamento...',
          [TaskId, TThread.CurrentThread.ThreadID]);

        // Simula trabalho variável
        Sleep(500 + Random(2000));

        TThread.Queue(nil,
          procedure
          begin
            LogWrite(TarefaFinalizada + ' Tarefa %d: Processamento concluído.', [TaskId]);

            if FThreadPool.ActiveTaskCount = 0 then
            begin
              LogWrite(TodasTarefasConcluídas + ' Todas tarefas processadas.');
            end;
          end);

        DebugLogWrite('Task %d (Worker %d): Processamento concluído.',
          [TaskId, TThread.CurrentThread.ThreadID]);
      end
    );
    LogWrite(TarefaAgendada + ' Tarefa %d adicionada ao Thread Pool.', [TaskId]);
  finally
    QueueTaskThreadPoolButton.Enabled := True;
  end;
end;

procedure TMainForm.SetButtonStates(RunningState: TRunningState);
begin
  if csDestroying in ComponentState then
    Exit;

  IniciarThreadPoolButton.Enabled := RunningState = IsStopped;
  PararThreadPoolButton.Enabled := RunningState = IsRunning;
  QueueTaskThreadPoolButton.Enabled := RunningState = IsRunning;
end;

end.

