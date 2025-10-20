unit DelphiMultithreadingBook0302.SharedData;

interface

uses
  System.Classes;

var
  // Recurso compartilhado para TMonitor
  SharedSimpleList: TStringList;

implementation

initialization
  // Cria (inicializa) o recurso compartilhado
  SharedSimpleList := TStringList.Create;

finalization
  // Libera o recurso compartilhado
  SharedSimpleList.Free;

end.
