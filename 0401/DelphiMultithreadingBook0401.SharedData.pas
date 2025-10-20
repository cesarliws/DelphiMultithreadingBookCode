unit DelphiMultithreadingBook0401.SharedData;

interface

uses
  System.Classes,
  System.SyncObjs;

var
  // Evento para controlar a pausa/retomada de threads paus�veis
  PauseEvent: TEvent;

implementation

uses
  System.SysUtils;

initialization
  // Inicializa o evento de pausa:
  PauseEvent := TEvent.Create(
    nil,           // EventAttributes = nil
    True,          // ManualReset = True
    True,          // InitialState = True (Sinalizado, N�o Pausado)
    'EventoPausa', // Name
    False          // UseCOMWait = False
  );

finalization
  PauseEvent.Free;

end.
