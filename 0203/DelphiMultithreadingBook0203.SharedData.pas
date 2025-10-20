unit DelphiMultithreadingBook0203.SharedData;

interface

uses
  System.Classes,
  System.SyncObjs;

var
  ContadorGlobal: Integer;
  ContadorLock: TCriticalSection;

implementation

initialization
  ContadorGlobal := 0;
  ContadorLock := TCriticalSection.Create;

finalization
  ContadorLock.Free;

end.
