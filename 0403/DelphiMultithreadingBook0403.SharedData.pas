unit DelphiMultithreadingBook0403.SharedData;

interface

uses
  System.SyncObjs;

var
  // Evento para controlar a pausa/retomada de threads paus�veis
  PauseEvent: TEvent;

implementation

initialization
  // Inicializa o evento de pausa
  PauseEvent := TEvent.Create(
    nil,
    True,  // ManualReset = True - Reset Manual
    True,  // InitialState = True - Estado Inicial Sinalizado (n�o pausado)
    'EventoPausa',
    False);

finalization
  PauseEvent.Free;

end.
