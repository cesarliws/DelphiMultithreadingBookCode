unit DelphiMultithreadingBook0301.SharedData;

interface

uses
  System.Classes,
  System.SyncObjs; // TCriticalSection

var
  // Recurso compartilhado: uma lista de strings
  SharedStringList: TStringList;
  // Objeto Critical Section para proteger o SharedStringList
  SharedStringListCriticalSection: TCriticalSection;

implementation

initialization
  // Cria a Critical Section e o recurso protegido, nesta ordem.
  SharedStringListCriticalSection := TCriticalSection.Create;
  SharedStringList := TStringList.Create;

finalization
  // Libera os recursos na ordem inversa de criação.
  SharedStringList.Free;
  SharedStringListCriticalSection.Free;

end.
