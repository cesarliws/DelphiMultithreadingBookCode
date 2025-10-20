unit DelphiMultithreadingBook0802.Worker;

interface

uses
  System.Classes;

type
  TExecutionMode = (emNoSync, emCriticalSection, emThreadVar);

  TWorker = class(TThread)
  private
    FMode: TExecutionMode;
    FIncrementCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(Mode: TExecutionMode; IncrementCount: Integer);
  end;

implementation

uses
  System.SysUtils, System.SyncObjs,
  DelphiMultithreadingBook0802.SharedData;

constructor TWorker.Create(Mode: TExecutionMode; IncrementCount: Integer);
begin
  // Cria suspensa
  inherited Create(True);
  // Gerenciamento manual pelo form
  FreeOnTerminate := False;
  FMode := Mode;
  FIncrementCount := IncrementCount;
end;

procedure TWorker.Execute;
var
  i: Integer;
begin
  // A vari�vel threadvar � inicializada com zero para cada thread.
  if FMode = emThreadVar then
  begin
    ContadorLocal := 0;
  end;

  for i := 1 to FIncrementCount do
  begin
    case FMode of
      emNoSync:
        // ACESSO INSEGURO - Gera Race Condition
        Inc(ContadorGlobal);

      emCriticalSection:
        // Acesso seguro, mas com conten��o de lock
        begin
          ContadorLock.Enter;
          try
            Inc(ContadorGlobal);
          finally
            ContadorLock.Leave;
          end;
        end;

      emThreadVar:
        // Acesso ao contador local da thread. Sem lock, sem conten��o.
        Inc(ContadorLocal);
    end;
  end;

  // Se usamos threadvar, adicionamos o subtotal ao total geral no final.
  // Esta � a �nica opera��o que precisa de sincroniza��o.
  // Usamos TInterlocked.Add por ser a forma mais perform�tica de
  // fazer uma adi��o at�mica, conforme vimos em detalhes no T�pico 7.2.
  if FMode = emThreadVar then
  begin
    TInterlocked.Add(ContadorGlobalFinal, ContadorLocal);
  end;
end;

end.

