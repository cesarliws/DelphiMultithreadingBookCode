unit DelphiMultithreadingBook.ExceptionUtils;

interface

uses
  System.SysUtils,
  System.Threading; // EAggregateException

// Este procedimento pode ser usado em qualquer lugar onde você precise
// inspecionar uma exceção, especialmente se houver a possibilidade
// de ser uma EAggregateException.
procedure HandlePotentialAggregateException(E: Exception);

implementation

uses
  DelphiMultithreadingBook.Utils;

procedure HandlePotentialAggregateException(E: Exception);
var
  AggregateException: EAggregateException;
  InneException: Exception;
begin
  if E is EAggregateException then
  begin
    AggregateException := EAggregateException(E);
    // Você também pode usar AggregateException.ToString para extrair as
    // mensagens de todas as exceptions agregadas de uma vez.
    DebugLogWrite('Erro Agregado Detectado: %s', [AggregateException.Message]);

    // Ao iterar sobre InnerExceptions,
    // você pode obter detalhes de cada falha individual.
    for InneException in AggregateException do
    begin
      DebugLogWrite('  -> Exceção Interna: %s: %s',
        [InneException.ClassName, InneException.Message]);
      // Você pode fazer um tratamento específico para cada InneException aqui,
      // como logar individualmente, exibir detalhes em uma lista na UI,
      // ou até mesmo tentar identificar padrões de erros.
    end;
  end
  else
  begin
    DebugLogWrite('Erro Simples Detectado: %s: %s', [E.ClassName, E.Message]);
  end;
end;

end.
