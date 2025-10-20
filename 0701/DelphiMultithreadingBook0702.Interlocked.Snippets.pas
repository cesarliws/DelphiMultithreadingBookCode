unit DelphiMultithreadingBook0702.Interlocked.Snippets;

interface


implementation

uses
  System.SyncObjs;

// Exemplo: Contador thread-safe
var
  // Deve ser acess�vel por todas as threads
  GlobalCounter: Integer;

procedure ThreadSafeCounter;
begin
  // ...
  // Dentro de uma thread:
  // Seguro para m�ltiplas threads
  TInterlocked.Increment(GlobalCounter);
  // ...
end;

// Exemplo: Somar pontos thread-safe
var
  TotalScore: Integer;

procedure UpdateScoreCountBy10;
begin
  // ...
  // Dentro de uma thread:
  // Adiciona 10 pontos atomicamente
  TInterlocked.Add(TotalScore, 10);
  // ...
end;

// Exemplo: Troca at�mica de um flag booleano
var
  IsBusy: Boolean;

procedure UpdateBusyState;
begin
  // ...
  // Para adquirir o "status de ocupado" atomicamente:
  if not TInterlocked.Exchange(IsBusy, True) then
  begin
    // Se retornou False (o valor original), ent�o IsBusy era False e agora � True.
    // Significa que esta thread foi a primeira a definir para True.
    // Pode prosseguir com a tarefa.
  end
  else
  begin
    // Retornou True, ent�o IsBusy j� era True. J� est� ocupado.
    // N�o pode prosseguir.
  end;

  // ... Ao terminar a tarefa:
  // Libera o flag atomicamente
  TInterlocked.Exchange(IsBusy, False);
  // ...
end;


// Exemplo: Atualiza��o de um valor apenas se ele n�o mudou
var
  CurrentValue: Integer;
  DesiredValue: Integer;
  OldValue: Integer;

procedure UpdateWithRetry;
begin
  // ...
  // Loop de "tentativa e erro" para atualiza��o lock-free
  repeat
    OldValue := CurrentValue; // L� o valor atual
    DesiredValue := OldValue + 10; // Calcula o novo valor
    // Tenta definir CurrentValue para DesiredValue SOMENTE se CurrentValue
    // ainda for OldValue
    // Retorna o valor de CurrentValue ANTES da tentativa de troca.
  until TInterlocked.CompareExchange(CurrentValue, DesiredValue, OldValue) = OldValue;
  // O loop continua at� que a troca seja bem-sucedida (garantindo atomicidade)
  // ...
end;

end.
