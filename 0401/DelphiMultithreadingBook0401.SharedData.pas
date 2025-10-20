unit DelphiMultithreadingBook0401.SharedData;

interface

uses
  System.Classes,
  System.SyncObjs;

var
  // Evento para controlar a pausa/retomada de threads pausáveis
  PauseEvent: TEvent;

implementation

uses
  System.SysUtils;

initialization
  // Inicializa o evento de pausa:
  PauseEvent := TEvent.Create(
    nil,           // EventAttributes = nil
    True,          // ManualReset = True
    True,          // InitialState = True (Sinalizado, Não Pausado)
    'EventoPausa', // Name
    False          // UseCOMWait = False
  );

finalization
  PauseEvent.Free;

end.
