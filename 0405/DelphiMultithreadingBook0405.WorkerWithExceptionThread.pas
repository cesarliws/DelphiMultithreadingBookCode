unit DelphiMultithreadingBook0405.WorkerWithExceptionThread;

interface

uses
  System.Classes;

type
  // Thread que n�o faz tratamento das Exceptions
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
  LogWrite('WorkerWithExceptionThread: Iniciando trabalho que causar� erro...');
  // Simula algum trabalho
  Sleep(1000);

  // Lan�ando uma exce��o intencionalmente, SEM CAPTURAR NESTE M�TODO.
  // Isso far� com que a TThread defina FatalException.
  raise Exception.Create('Exce��o gerada na thread de trabalho (n�o capturada)!');

  // O c�digo a partir daqui n�o ser� executado.
  LogWrite('WorkerWithExceptionThread: Trabalho conclu�do (este texto n�o aparecer�).');
end;

end.
