unit DelphiMultithreadingBook0304.SharedData;

interface

uses
  System.Classes,
  System.SyncObjs;

var
  // Novo Semáforo para controlar o número de threads "trabalhando"
  WorkerSemaphore: TSemaphore;

implementation

initialization
  // Cria o Semáforo:
  WorkerSemaphore := TSemaphore.Create(
    nil, // nil para atributos de segurança padrão
    3,   // 3 permissões iniciais
    3,   // 3 permissões máximas (limita a 3 workers simultâneos)
    ''   // Nome vazio, criando um semáforo local (não nomeado)
  );

finalization
  // Libera o Semáforo
  WorkerSemaphore.Free;

end.
