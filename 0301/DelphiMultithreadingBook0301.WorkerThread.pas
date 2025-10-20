unit DelphiMultithreadingBook0301.WorkerThread;

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
  // Importa a unit com o recurso compartilhado
  DelphiMultithreadingBook0301.SharedData,
  DelphiMultithreadingBook.Utils;

{ TWorkerThread }

constructor TWorkerThread.Create(ThreadId: Integer; ActionCount: Integer);
begin
  inherited Create(False);
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
    // A propriedade Terminated nos permite interromper a execução do
    // loop de forma segura e cooperativa, caso a thread precise ser terminada.
    if Terminated then
      Break;

    // Protege a escrita na SharedStringList com a Critical Section
    // --- Início da Seção Crítica ---
    SharedStringListCriticalSection.Enter;
    try
      // Apenas uma thread por vez pode executar o código aqui dentro
      ThreadMessage := Format('Thread %d: Adicionando item %d', [FThreadId, i]);
      SharedStringList.Add(ThreadMessage);
      // Opcional: para ver no Debug Output
      DebugLogWrite(ThreadMessage);
    finally
      SharedStringListCriticalSection.Leave;
    end;
    // --- Fim da Seção Crítica ---

    // Pequena pausa para simular trabalho real e permitir troca de contexto
    Sleep(10);
  end;

  DebugLogWrite('Thread %d: Trabalho concluído!', [FThreadId]);
end;

end.
