unit DelphiMultithreadingBook0405.ExceptionUtils;

interface

uses
  System.SysUtils,
  System.Threading; // System.Threading para EAggregateException

// Este procedimento pode ser usado em qualquer lugar onde voc� precise
// inspecionar uma exce��o, especialmente se houver a possibilidade
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
    DebugLogWrite('Erro Agregado Detectado: %s', [AggregateException.Message]);

    // Ao iterar sobre InnerExceptions,
    // voc� pode obter detalhes de cada falha individual.
    for InneException in AggregateException do
    begin
      DebugLogWrite('  -> Exce��o Interna: %s: %s',
        [InneException.ClassName, InneException.Message]);
      // Voc� pode fazer um tratamento espec�fico para cada InnerExc aqui,
      // como logar individualmente, exibir detalhes em uma lista na UI,
      // ou at� mesmo tentar identificar padr�es de erros.
    end;
  end
  else
  begin
    DebugLogWrite('Erro Simples Detectado: %s: %s', [E.ClassName, E.Message]);
  end;
end;

end.
