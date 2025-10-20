unit DelphiMultithreadingBook0401.Snippets;

// Esta unit � apenas para criar os Snippets de c�digo usados no livro

interface

implementation

{$WARNINGS OFF}

uses
  System.Classes, DelphiMultithreadingBook0401.SharedData;

type
  TMinhaThread = class(TThread)
  end;

  TSnippets = class
  public
    function CreateThreadAndRunNow: TMinhaThread;
    function CreateThreadSuspended: TMinhaThread;
  end;

  TMyLongTaskThread = class(TThread)
  end;

  TMainForm = class
    procedure PauseButton(Sender: TObject);
    procedure ResumeButton(Sender: TObject);
    procedure StartButton(Sender: TObject);
  private
     FWorkerThread: TMyLongTaskThread;
  end;

// ... na interface
type
  TPausableWorkerThread = class(TThread)
  //...
  protected
    // Adicionar
    procedure TerminatedSet; override;
  //...
  end;

{ TSnippets }

function TSnippets.CreateThreadAndRunNow: TMinhaThread;
var
  MinhaThread : TMinhaThread;
begin
  // A thread come�a a executar o m�todo Execute imediatamente
  MinhaThread := TMinhaThread.Create(False);
  Result := MinhaThread;
end;

function TSnippets.CreateThreadSuspended: TMinhaThread;
var
  MinhaThread : TMinhaThread;
begin
  // Thread � criada, mas n�o executa Execute ainda
  MinhaThread := TMinhaThread.Create(True);
  // ... Configura��es da thread ...

  // Inicia a execu��o do m�todo Execute
  MinhaThread.Start;
end;

// No Form principal
procedure TMainForm.StartButton(Sender: TObject);
begin
  FWorkerThread := TMyLongTaskThread.Create(False); // Inicia
end;

procedure TMainForm.PauseButton(Sender: TObject);
begin
  if Assigned(FWorkerThread) then
    // Pausa a thread (APENAS PARA DEPURAR/ILUSTRAR O CONCEITO)
    FWorkerThread.Suspend;
end;

procedure TMainForm.ResumeButton(Sender: TObject);
begin
  if Assigned(FWorkerThread) then
    // Retoma a thread (APENAS PARA DEPURAR/ILUSTRAR O CONCEITO)
    FWorkerThread.Resume;
end;

// ... na implementation
procedure TPausableWorkerThread.TerminatedSet;
begin
  inherited;
  // A pr�pria thread se encarrega de sinalizar o evento para sair do
  // estado de espera e poder terminar sua execu��o.
  PauseEvent.SetEvent;
end;

end.
