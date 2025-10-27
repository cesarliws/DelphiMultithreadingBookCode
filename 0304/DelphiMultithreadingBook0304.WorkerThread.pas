unit DelphiMultithreadingBook0304.WorkerThread;

interface

uses
  System.Classes,
  DelphiMultithreadingBook.Utils;

type
  TWorkerThread = class(TThread)
  private
    FLogWriteCallback: TLogWriteCallback;
    FThreadId: Integer;
  protected
    procedure Execute; override;
    procedure CallbackLogWrite(const Text: string); overload;
    procedure CallbackLogWrite(const Text: string;
      const Args: array of const); overload;
  public
    constructor Create(ThreadId: Integer; LogWriteCallback: TLogWriteCallback);
  end;

implementation

uses
  System.SyncObjs,
  System.SysUtils,
  WinApi.Windows,
  DelphiMultithreadingBook0304.SharedData;

{ TWorkerThread }

constructor TWorkerThread.Create(ThreadId: Integer;
  LogWriteCallback: TLogWriteCallback);
begin
  inherited Create(False);
  FreeOnTerminate := True;
  FThreadId := ThreadId;
  FLogWriteCallback := LogWriteCallback;
end;

procedure TWorkerThread.Execute;
var
  i: Integer;
begin
  CallbackLogWrite('Thread %d: Iniciando...', [FThreadId]);
  CallbackLogWrite('Thread %d: Tentando adquirir permiss�o do Sem�foro...',
    [FThreadId]);

  // Adquire uma permiss�o do Sem�foro
  // Bloqueia se n�o houver permiss�es
  WorkerSemaphore.Acquire;
  try
    CallbackLogWrite(
     'Thread %d: Permiss�o do Sem�foro adquirida! Iniciando processamento...',
     [FThreadId]);

    // Simula um processamento pesado real
    for i := 1 to 3 do
    begin
      if Terminated then
        Break;
      CallbackLogWrite('Thread %d: Processando etapa %d...', [FThreadId, i]);

      // Demora 1 segundo por etapa
      Sleep(1000);
    end;

    CallbackLogWrite('Thread %d: Processamento pesado conclu�do!', [FThreadId]);
  finally
    // Libera a permiss�o do Sem�foro
    WorkerSemaphore.Release;
    CallbackLogWrite('Thread %d: Permiss�o do Sem�foro liberada!', [FThreadId]);
  end;

  CallbackLogWrite('Thread %d: Fim do trabalho.', [FThreadId]);
end;

procedure TWorkerThread.CallbackLogWrite(const Text: string;
  const Args: array of const);
begin
  CallbackLogWrite(Format(Text, Args));
end;

procedure TWorkerThread.CallbackLogWrite(const Text: string);
var
  Callback: TLogWriteCallback;
begin
  DebugLogWrite(Text);

  // Envia log para a UI se foi passado o callback para notificar
  if Assigned(FLogWriteCallback) then
  begin
    // Define o callback para uma vari�vel local para ser capturada pelo m�todo closure da fila
    Callback := FLogWriteCallback;
    // Usamos TThread.Queue para atualizar a UI sem bloquear o processamento
    TThread.Queue(nil,
      procedure
      begin
        FLogWriteCallback(Text);
      end);
  end;
end;

end.
