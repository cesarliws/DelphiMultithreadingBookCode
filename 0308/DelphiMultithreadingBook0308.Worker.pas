unit DelphiMultithreadingBook0308.Worker;

interface

uses
  System.Classes,
  System.SyncObjs,
  DelphiMultithreadingBook.Utils;

type
  TWorkerWithCancel = class(TThread)
  private
    FCancelEvent: TEvent;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;
    property CancelEvent: TEvent read FCancelEvent;
  end;

implementation

uses
  System.SysUtils;

constructor TWorkerWithCancel.Create;
begin
  // Cria suspensa
  inherited Create(True);
  FreeOnTerminate := False;
  // Evento de reset manual, começa não sinalizado
  FCancelEvent := TEvent.Create(nil, True, False, '');
end;

destructor TWorkerWithCancel.Destroy;
begin
  FCancelEvent.Free;
  inherited;
end;

procedure TWorkerWithCancel.Execute;
begin
  LogWrite('Worker: Iniciando trabalho longo (5 segundos)...');
  // Espera 5 segundos, mas pode ser interrompido pelo CancelEvent a qualquer momento.
  // WaitFor retorna wrSignaled se o evento for sinalizado, ou wrTimeout se o tempo acabar.
  if FCancelEvent.WaitFor(5000) = wrTimeout then
    LogWrite('Worker: Trabalho concluído com sucesso!')
  else
    LogWrite('Worker: Trabalho interrompido pelo cancelamento.');
end;

end.
