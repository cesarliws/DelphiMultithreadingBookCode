unit DelphiMultithreadingBook0802.SharedData;

interface

uses
  System.SyncObjs;

var
  // --- Para os testes 1 e 2 ---
  ContadorGlobal: Int64;
  ContadorLock: TCriticalSection;

  // --- Para o teste 3 (otimizado) ---
  // Total final, onde os subtotais serão somados
  ContadorGlobalFinal: Int64;

threadvar
  // Cada thread terá sua própria cópia desta variável. Não há compartilhamento.
  ContadorLocal: Int64;

implementation

initialization
  ContadorLock := TCriticalSection.Create;

finalization
  ContadorLock.Free;

end.
