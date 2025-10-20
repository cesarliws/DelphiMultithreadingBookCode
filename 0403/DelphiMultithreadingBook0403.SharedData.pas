unit DelphiMultithreadingBook0403.SharedData;

interface

uses
  System.SyncObjs;

var
  // Evento para controlar a pausa/retomada de threads pausáveis
  PauseEvent: TEvent;

implementation

initialization
  // Inicializa o evento de pausa
  PauseEvent := TEvent.Create(
    nil,
    True,  // ManualReset = True - Reset Manual
    True,  // InitialState = True - Estado Inicial Sinalizado (não pausado)
    'EventoPausa',
    False);

finalization
  PauseEvent.Free;

end.
