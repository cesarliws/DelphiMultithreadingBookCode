unit DelphiMultithreadingBook0402.WorkerThread;

interface

uses
  System.Classes;

type
  TWorkerThread = class(TThread)
  private
    FThreadId: Integer;
    FWorkPerformed: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ThreadId: Integer);
    property WorkPerformed: Integer read FWorkPerformed;
  end;

implementation

uses
  DelphiMultithreadingBook.Utils;

{ TWorkerThread }

constructor TWorkerThread.Create(ThreadId: Integer);
begin
  inherited Create(True);
  // IMPORTANTE: Gerenciamento manual da liberação do objeto
  FreeOnTerminate := False;
  FThreadId := ThreadId;
  FWorkPerformed := 0;
end;

procedure TWorkerThread.Execute;
var
  i: Integer;
begin
  DebugLogWrite('WorkerThread %d: Iniciando trabalho...', [FThreadId]);

  // Loop longo para simular trabalho contínuo
  for i := 1 to 1000 do
  begin
    // Verifica se a thread foi solicitada para terminar
    if Terminated then
      // Sai do loop cooperativamente
      Break;

    // Simula progresso do trabalho
    Inc(FWorkPerformed);
    // Pequena pausa para permitir troca de contexto
    Sleep(1);
  end;

  DebugLogWrite('WorkerThread %d: Trabalho concluído (passos: %d)!',
    [FThreadId, FWorkPerformed]);
end;

end.
