unit DelphiMultithreadingBook0302.WorkerThread;

interface

uses
  System.Classes;

type
  TWorkerThread = class(TThread)
  private
    FActionCount: Integer;
    FThreadId: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ThreadId: Integer; ActionCount: Integer);
  end;

implementation

uses
  System.SyncObjs,
  System.SysUtils,
  WinApi.Windows,
  // Importa a unit com o recurso compartilhado
  DelphiMultithreadingBook0302.SharedData,
  DelphiMultithreadingBook.Utils;

{ TWorkerThread }

constructor TWorkerThread.Create(ThreadId: Integer; ActionCount: Integer);
begin
  inherited Create(False);
  // Pode ser controlado pelo form principal se preferir
  FreeOnTerminate := True;
  FThreadId := ThreadId;
  FActionCount := ActionCount;
end;

procedure TWorkerThread.Execute;
var
  i: Integer;
  ThreadMessage: string;
begin
  DebugLogWrite('Thread %d: Iniciando trabalho...', [FThreadId]);

  for i := 1 to FActionCount do
  begin
    if Terminated then
      Break;

    // --- Início da Proteção com TMonitor ---
    // Protege a instância de SharedSimpleList
    TMonitor.Enter(SharedSimpleList);
    try
      ThreadMessage := Format('Thread %d (Monitor): Adicionando item %d',
        [FThreadId, i]);
      SharedSimpleList.Add(ThreadMessage);
      // Opcional: para ver no Debug Output
      DebugLogWrite(ThreadMessage);
    finally
      TMonitor.Exit(SharedSimpleList);
    end;
    // --- Fim da Proteção com TMonitor ---

    // Pequena pausa
    Sleep(10);
  end;

  DebugLogWrite('Thread %d: Trabalho concluído!', [FThreadId]);
end;

end.
