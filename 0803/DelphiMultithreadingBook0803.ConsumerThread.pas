unit DelphiMultithreadingBook0803.ConsumerThread;

interface

uses
  System.Classes;

type
  // Define o tipo de callback que o ConsumerThread usará para reportar
  // mensagens para a UI. A thread consumidora será responsável por garantir
  // que este callback seja executado no contexto da thread principal.
  TConsumerMessageCallback = reference to procedure(const TextMessage: string);

  TConsumerThread = class(TThread)
  private
    // Callback para reportar mensagens
    FMessageCallback: TConsumerMessageCallback;
  protected
    procedure Execute; override;
  public
    // Construtor recebe um callback para a UI
    constructor Create(MessageCallback: TConsumerMessageCallback);
  end;

implementation

uses
  System.TypInfo,  // GetEnumName
  System.SysUtils, // Format
  System.Types,    // TWaitResult
  WinApi.Windows,  // Sleep
  DelphiMultithreadingBook0803.SharedData, // ThreadSafeMessageQueue
  DelphiMultithreadingBook.Utils;

{ TConsumerThread }

constructor TConsumerThread.Create(MessageCallback: TConsumerMessageCallback);
begin
  // Cria suspensa
  inherited Create(True);
  // Gerenciamento manual da liberação
  FreeOnTerminate := False;
  // Armazena o callback
  FMessageCallback := MessageCallback;
end;

procedure TConsumerThread.Execute;
var
  PopResult: TWaitResult;
  ProcessedCount: Integer;
  TextMessage: string;
  QueueSizeDummy: NativeInt;
begin
  ProcessedCount := 0;
  DebugLogWrite('Consumidor: Iniciando consumo de mensagens...');

  // Loop principal, verifica Terminated a cada iteração
  while not Terminated do
  begin
    // Tenta pegar um item da fila. O PopTimeout é configurado no construtor
    // da TThreadedQueue.
    // Isso garante que a thread não fique bloqueada indefinidamente no PopItem
    // e possa verificar o sinal de Terminate periodicamente.
    // PopItem sem o parâmetro QueueSize e timeout direto
    PopResult := ThreadSafeMessageQueue.PopItem(QueueSizeDummy, TextMessage);

    if PopResult = TWaitResult.wrSignaled then
    begin
      // Um item foi obtido da fila
      Inc(ProcessedCount);
      DebugLogWrite('Consumidor: Processando "%s" (Total processado: %d)',
        [TextMessage, ProcessedCount]);

      // Invoca o callback para logar na UI
      if Assigned(FMessageCallback) then
        // O ConsumerThread agora enfileira o callback para a Main UI
        TThread.Queue(nil,
          procedure
          begin
            FMessageCallback(Format('Consumidor: Processou "%s"', [TextMessage]));
          end);

      // Simula processamento da mensagem
      Sleep(50 + Random(200)); 
    end
    else if PopResult = TWaitResult.wrTimeout then
    begin
      // Fila vazia ou timeout. Thread não processou nada nesta iteração.
      // Continua o loop para verificar Terminated novamente.
      DebugLogWrite('Consumidor: Fila vazia ou timeout...');
    end
    // Outros resultados inesperados do PopItem (wrAbandoned, wrError)
    else
    begin
      DebugLogWrite('Consumidor: Erro inesperado no PopItem (%s). Terminando...',
        [GetEnumName(TypeInfo(TWaitResult), Integer(PopResult))]);
        // Sai do loop em caso de erro inesperado
      Break;
    end;
  end; // Fim do while not Terminated do

  // Após sair do loop (porque Terminated = True ou erro no PopItem),
  // processa quaisquer itens restantes na fila (drena a fila).
  // Usamos PopItem para pegar o que sobrou.
  while ThreadSafeMessageQueue.
        PopItem(QueueSizeDummy, TextMessage) = TWaitResult.wrSignaled do
  begin
    Inc(ProcessedCount);
    DebugLogWrite('Consumidor: Drenando item restante "%s"', [TextMessage]);
    if Assigned(FMessageCallback) then
      TThread.Queue(nil,
        procedure
        begin
          FMessageCallback(Format('Consumidor: Drenou "%s"', [TextMessage]));
        end);
  end;

  // Mensagem final ao encerrar
  if Assigned(FMessageCallback) then
    TThread.Queue(nil,
      procedure
      begin
        FMessageCallback(
          Format('Consumidor: Serviço terminado. Total processado: %d',
          [ProcessedCount]));
      end);

  DebugLogWrite('Consumidor: Terminado. Total processado: %d', [ProcessedCount]);
end;

end.
