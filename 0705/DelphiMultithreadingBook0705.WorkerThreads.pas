unit DelphiMultithreadingBook0705.WorkerThreads;

interface

uses
  System.Classes;

type
  TProducerThread = class(TThread)
  protected
    procedure Execute; override;
  end;

  TConsumerThread = class(TThread)
  protected
    procedure Execute; override;
  end;

implementation

uses
  System.SyncObjs,
  System.SysUtils,
  DelphiMultithreadingBook0705.SharedData,
  DelphiMultithreadingBook.Utils;

{ TProducerThread }

procedure TProducerThread.Execute;
var
  i: Integer;
  TaskName: string;
begin
  for i := 1 to 5 do
  begin
    if Terminated then Break;

    TaskName := Format('Tarefa %d', [i]);
    QueueLock.Enter;
    try
      WorkQueue.Enqueue(TaskName);
      LogWrite('Produtor: Adicionou "%s" � fila.', [TaskName]);
      // Usa Release para acordar UMA thread consumidora que pode estar esperando
      QueueNotEmpty.Release;
    finally
      QueueLock.Leave;
    end;
    // Simula tempo para gerar a pr�xima tarefa
    Sleep(500 + Random(1000));
  end;

  LogWrite('Produtor: Finalizou a produ��o.');
end;

{ TConsumerThread }

procedure TConsumerThread.Execute;
var
  TaskName: string;
begin
  LogWrite('Consumidor: Aguardando por tarefas...');
  while not Terminated do
  begin
    QueueLock.Enter;
    try
      // O loop while � essencial para prote��o contra "despertares esp�rios"
      while (WorkQueue.Count = 0) and (not Terminated) do
      begin
        // Fila est� vazia. Libera o lock e dorme at� ser sinalizada.
        // O lock � passado como par�metro para o WaitFor.
        QueueNotEmpty.WaitFor(QueueLock);
      end;

      if Terminated then Break;

      // Ao acordar, o lock j� foi re-adquirido automaticamente.
      TaskName := WorkQueue.Dequeue;
    finally
      QueueLock.Leave;
    end;

    // O trabalho de processamento � feito fora do lock
    LogWrite('Consumidor: Processando "%s"...', [TaskName]);
    // Simula trabalho de processamento
    Sleep(1000);
    LogWrite('Consumidor: "%s" conclu�da.', [TaskName]);
  end;

  LogWrite('Consumidor: Encerrado.');
end;

end.
