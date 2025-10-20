unit DelphiMultithreadingBook0801.WorkerProcessor;

interface

uses
  System.Classes,
  System.SysUtils;

type
  // Define o tipo de callback que o WorkerProcessor usar� para reportar
  // progresso e erros
  TProgressUpdateCallback = reference to procedure(const Text: string;
    Progress: Integer);
  TErrorCallback = reference to procedure(const Text: string);

  TWorkerProcessor = class
  private
    FCancelRequested: Boolean;
    // Callbacks que ser�o invocados pelo Processor
    FUpdateCallback: TProgressUpdateCallback;
    FErrorCallback: TErrorCallback;
  public
    // Construtor agora recebe o callback de progresso e o de erro
    constructor Create(UpdateCallback: TProgressUpdateCallback;
      ErrorCallback: TErrorCallback = nil);
    procedure PerformLongCalculation;
    procedure RequestCancel;
    // M�todo para reportar erros (chamado pela thread se algo der errado)
    procedure ReportErrorFmt(const ErrorText: string; const Args: array of const);
    property CancelRequested: Boolean read FCancelRequested;
  end;

const
  CancelProcessingText = 'C�lculo Cancelado (Processor).';

implementation

uses
  DelphiMultithreadingBook.Utils;

{ TWorkerProcessor }

constructor TWorkerProcessor.Create(UpdateCallback: TProgressUpdateCallback;
  ErrorCallback: TErrorCallback);
begin
  inherited Create;
  FCancelRequested := False;
  FUpdateCallback := UpdateCallback;
  FErrorCallback := ErrorCallback;
end;

procedure TWorkerProcessor.PerformLongCalculation;
var
  i: Integer;
begin
  DebugLogWrite('TWorkerProcessor: Iniciando c�lculo...');
  try
    for i := 1 to 10 do
    begin
      if FCancelRequested then
      begin
        DebugLogWrite('TWorkerProcessor: C�lculo CANCELADO.');
        // Notifica o callback de progresso sobre o cancelamento
        if Assigned(FUpdateCallback) then
          TThread.Queue(nil,
            procedure
            begin
              FUpdateCallback(CancelProcessingText, 0);
            end
          );
        Exit;
      end;

      DebugLogWrite('TWorkerProcessor: Passo %d...', [i]);
      // Simula trabalho
      Sleep(1000);
      // Notifica o callback de progresso
      if Assigned(FUpdateCallback) then
        TThread.Queue(nil,
          procedure
          begin
            FUpdateCallback(Format('Progresso: %d', [i * 10]), i * 10);
          end
        );
    end;
    DebugLogWrite('TWorkerProcessor: C�lculo conclu�do.');
    // Notifica o callback de progresso sobre a conclus�o
    if Assigned(FUpdateCallback) then
      TThread.Queue(nil,
        procedure
        begin
          FUpdateCallback('C�lculo Finalizado (Processor).', 100);
        end
      );
  except
    on E: Exception do
    begin
      // Reporta o erro
      ReportErrorFmt('Erro durante o c�lculo: %s', [E.Message]);
      DebugLogWrite('TWorkerProcessor: Exce��o inesperada no c�lculo: %s',
        [E.Message]);
      // Re-lan�a a exce��o para que a TWorkerThread possa captur�-la se quiser
      raise;
    end;
  end;
end;

procedure TWorkerProcessor.RequestCancel;
begin
  FCancelRequested := True;
end;

procedure TWorkerProcessor.ReportErrorFmt(const ErrorText: string; const Args:
  array of const);
var
  Error: string;
begin
  Error := Format(ErrorText, Args);
  // Reporta o erro
  if Assigned(FErrorCallback) then
    TThread.Queue(nil,
      procedure
      begin
        FErrorCallback(Error);
      end
    );
end;

end.
