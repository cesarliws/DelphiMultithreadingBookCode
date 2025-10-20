unit DelphiMultithreadingBook0203.WorkerThread;

interface

uses
  System.Classes;

type
  TWorkerThread = class(TThread)
  private
    FUseLocking: Boolean;
    FIncrementCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(UseLocking: Boolean; IncrementCount: Integer);
  end;

implementation

uses
  System.SyncObjs,
  System.SysUtils,
  DelphiMultithreadingBook0203.SharedData;

constructor TWorkerThread.Create(UseLocking: Boolean;
  IncrementCount: Integer);
begin
  // Cria a Thread suspensa
  inherited Create(True);
  // Gerenciamento manual pelo orquestrador
  FreeOnTerminate := False;
  FUseLocking := UseLocking;
  FIncrementCount := IncrementCount;
end;

procedure TWorkerThread.Execute;
var
  i: Integer;
begin
  for i := 1 to FIncrementCount do
  begin
    if FUseLocking then
    begin
      ContadorLock.Enter;
      try
        ContadorGlobal := ContadorGlobal + 1;
      finally
        ContadorLock.Leave;
      end;
    end
    else
    begin
      // Acesso inseguro - propenso a Race Condition
      ContadorGlobal := ContadorGlobal + 1;
    end;
  end;
end;

end.
