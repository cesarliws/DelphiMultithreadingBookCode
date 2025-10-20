unit DelphiMultithreadingBook0801.WorkerThread;

interface

uses
  System.Classes,
  System.SysUtils,
  WinApi.Windows,
  // WorkerThread depende diretamente do WorkerProcessor
  DelphiMultithreadingBook0801.WorkerProcessor;

type
  TWorkerThread = class(TThread)
  private
    FProcessor: TWorkerProcessor;
  protected
    procedure Execute; override;
  public
    // O construtor recebe a inst�ncia do WorkerProcessor j� configurada (Dependency Injection)
    constructor Create(Processor: TWorkerProcessor);
    destructor Destroy; override;
    // Propaga o cancelamento para o processor que ela executa
    procedure RequestCancel;
    property Processor: TWorkerProcessor read FProcessor;
  end;

implementation

uses
  DelphiMultithreadingBook.Utils;

{ TWorkerThread }

constructor TWorkerThread.Create(Processor: TWorkerProcessor);
begin
  // Cria suspensa, ser� iniciada explicitamente pelo MainForm
  inherited Create(True);
  // FreeOnTerminate := False, pois o MainForm gerencia o ciclo de vida
  FreeOnTerminate := False;
  // A thread recebe a inst�ncia do processador e assume sua propriedade
  FProcessor := Processor;
end;

destructor TWorkerThread.Destroy;
begin
  // Libera o objeto processador quando a thread � destru�da
  FProcessor.Free;
  inherited;
end;

procedure TWorkerThread.Execute;
begin
  DebugLogWrite('TWorkerThread: Iniciando execu��o do processador...');
  try
    // Chama a l�gica de neg�cio principal do processador
    FProcessor.PerformLongCalculation;
  except
    on E: Exception do
    begin
      // Reporta o erro usando o callback j� configurado no FProcessor
      FProcessor.ReportErrorFmt('Erro na thread de trabalho: %s', [E.Message]);
      DebugLogWrite('TWorkerThread: Erro inesperado: %s', [E.Message]);
    end;
  end;
  DebugLogWrite('TWorkerThread: Fim da execu��o da thread.');
end;

procedure TWorkerThread.RequestCancel;
begin
  // Propaga o pedido de cancelamento para a l�gica de neg�cio do processador
  FProcessor.RequestCancel;
end;

end.
