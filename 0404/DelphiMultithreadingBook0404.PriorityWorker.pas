unit DelphiMultithreadingBook0404.PriorityWorker;

interface

uses
  System.Classes;

type
  TPriorityWorker = class(TThread)
  private
    FName: string;
  protected
    procedure Execute; override;
  public
    constructor Create(const Name: string; PriorityValue: TThreadPriority);
  end;

implementation

uses
  System.SysUtils,
  DelphiMultithreadingBook.Utils;

{ TPriorityWorker }

constructor TPriorityWorker.Create(const Name: string;
  PriorityValue: TThreadPriority);
begin
  // Inicia imediatamente
  inherited Create(False);
  FreeOnTerminate := True;
  FName := Name;
  Priority := PriorityValue;
end;

procedure TPriorityWorker.Execute;
var
  // Usamos Int64 para evitar overflow em um teste longo
  WorkCounter: Int64;
begin
  WorkCounter := 0;
  while not Terminated do
  begin
    // Simula uma unidade de trabalho puramente computacional
    SimulateCPUWork(250);
    Inc(WorkCounter);
  end;

  // Reporta o resultado APENAS UMA VEZ, no final.
  LogWrite('%s finalizou. Unidades de trabalho concluídas: %d',
    [FName, WorkCounter]);
end;

end.
