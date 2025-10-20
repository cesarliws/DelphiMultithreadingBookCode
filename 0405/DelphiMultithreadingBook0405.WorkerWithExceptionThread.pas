unit DelphiMultithreadingBook0405.WorkerWithExceptionThread;

interface

uses
  System.Classes;

type
  // Thread que não faz tratamento das Exceptions
  TWorkerWithExceptionThread = class(TThread)
  protected
    procedure Execute; override;
  end;

implementation

uses
  System.SysUtils,
  DelphiMultithreadingBook.Utils;

{ TWorkerThread }

procedure TWorkerWithExceptionThread.Execute;
begin
  LogWrite('WorkerWithExceptionThread: Iniciando trabalho que causará erro...');
  // Simula algum trabalho
  Sleep(1000);

  // Lançando uma exceção intencionalmente, SEM CAPTURAR NESTE MÉTODO.
  // Isso fará com que a TThread defina FatalException.
  raise Exception.Create('Exceção gerada na thread de trabalho (não capturada)!');

  // O código a partir daqui não será executado.
  LogWrite('WorkerWithExceptionThread: Trabalho concluído (este texto não aparecerá).');
end;

end.
