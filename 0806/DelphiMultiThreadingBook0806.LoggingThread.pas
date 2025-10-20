Unit DelphiMultithreadingBook0806.LoggingThread;

interface

uses
  System.Classes;

type
  TLoggingThread = class(TThread)
  protected
    procedure Execute; override;
  public
    constructor Create; reintroduce;
  end;

implementation

uses
  System.SysUtils,
  CodeSiteLogging;

{ TLoggingThread }

constructor TLoggingThread.Create;
begin
  inherited Create(True);
  FreeOnTerminate := True;
end;

procedure TLoggingThread.Execute;
var
  i: Integer;
begin
  // Adiciona tracing para o método, útil para depurar fluxo
  CodeSite.TraceMethod('TLoggingThread.Execute', tmoTiming);

  // Logar ID e nome da thread
  CodeSite.Send('Thread de Trabalho: Iniciada.');
  try
    for i := 1 to 5 do
    begin
      if Terminated then
        Break;
      CodeSite.Send(Format('Thread de Trabalho: Executando passo %d.', [i]));
      Sleep(500);
    end;
    CodeSite.Send('Thread de Trabalho: Finalizada.');
  except
    on E: Exception do
    begin
      // Logar a exceção completa
      CodeSite.Send('ERRO na Thread de Trabalho:', E);
    end;
  end;
end;

end.

