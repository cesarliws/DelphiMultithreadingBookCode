unit DelphiMultithreadingBook0803.SharedData;

interface

uses
  System.Generics.Collections; // TThreadedQueue<T>

var
  // Fila de mensagens thread-safe
  ThreadSafeMessageQueue: TThreadedQueue<string>;

implementation

const
  // Definimos um timeout curto para as opera��es Pop e Push
  // quando a fila est� cheia/vazia, para evitar bloqueios longos.
  QUEUE_OPERATION_TIMEOUT_MS = 100;

initialization
  // Cria a fila com uma profundidade (capacidade) de 10 itens.
  ThreadSafeMessageQueue := TThreadedQueue<string>.Create(
    10, // Capacidade da Fila
    QUEUE_OPERATION_TIMEOUT_MS,  // PushTimeout
    QUEUE_OPERATION_TIMEOUT_MS); // PopTimeout

finalization
  ThreadSafeMessageQueue.Free;

end.
