unit DelphiMultithreadingBook0304.SharedData;

interface

uses
  System.Classes,
  System.SyncObjs;

var
  // Novo Sem�foro para controlar o n�mero de threads "trabalhando"
  WorkerSemaphore: TSemaphore;

implementation

initialization
  // Cria o Sem�foro:
  WorkerSemaphore := TSemaphore.Create(
    nil, // nil para atributos de seguran�a padr�o
    3,   // 3 permiss�es iniciais
    3,   // 3 permiss�es m�ximas (limita a 3 workers simult�neos)
    ''   // Nome vazio, criando um sem�foro local (n�o nomeado)
  );

finalization
  // Libera o Sem�foro
  WorkerSemaphore.Free;

end.
