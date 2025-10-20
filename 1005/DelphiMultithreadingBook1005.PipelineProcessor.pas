unit DelphiMultithreadingBook1005.PipelineProcessor;

interface

uses
  System.Classes, System.Threading,
  DelphiMultithreadingBook.CancellationToken;

type
  TPipelineState = (
    IdleState,
    DownloadingCustomersState,
    DownloadingProductsState,
    GeneratingReportState,
    CompletedState,
    FailedState,
    CanceledState,
    DestroyingState
  );

  TStateChangeEvent = reference to procedure(const State: TPipelineState;
    const Message: string);

  TPipelineProcessor = class
  private
    FCurrentState: TPipelineState;
    FOrchestratorTask: ITask;
    FOnStateChange: TStateChangeEvent;
    FCustomerData: TStrings;
    FProductData: TStrings;
    FCancellationTokenSource: TCancellationTokenSource;
    FToken: ICancellationToken;
    procedure SetState(NewState: TPipelineState; const Message: string = '');
    procedure RunStateMachine;
    procedure DoDownloadCustomerData;
    procedure DoDownloadProductData;
    procedure DoGenerateReport;
  public
    constructor Create(OnStateChange: TStateChangeEvent);
    destructor Destroy; override;
    procedure Run;
    procedure Cancel;
    property CurrentState: TPipelineState read FCurrentState;
  end;

implementation

uses
  System.SysUtils;

{ TPipelineProcessor }

constructor TPipelineProcessor.Create(OnStateChange: TStateChangeEvent);
begin
  FOnStateChange := OnStateChange;
  FCurrentState := IdleState;
  FCancellationTokenSource := TCancellationTokenSource.Create;
  FToken := FCancellationTokenSource.Token;
  // Garante que o Randomize seja chamado para obter resultados diferentes
  Randomize;
end;

destructor TPipelineProcessor.Destroy;
begin
  try
    FCurrentState := DestroyingState;
    Cancel;
  finally
    FCancellationTokenSource.Free;
    FCustomerData.Free;
    FProductData.Free;
    inherited;
  end;
end;

procedure TPipelineProcessor.Run;
begin
  if FCurrentState <> IdleState then
    Exit;
  FOrchestratorTask := TTask.Run(procedure
    begin
      // A máquina de estado agora roda dentro de uma task
      RunStateMachine;
    end);
end;

procedure TPipelineProcessor.Cancel;
begin
  // Cancela a FONTE, e o sinal se propaga para todo o pipeline
  if Assigned(FCancellationTokenSource) then
    FCancellationTokenSource.Cancel;

  if Assigned(FOrchestratorTask) then
    FOrchestratorTask.Wait(250);
end;

procedure TPipelineProcessor.SetState(NewState: TPipelineState;
  const Message: string);
begin
  if FCurrentState = DestroyingState then Exit;

  FCurrentState := NewState;
  TThread.Queue(nil,
    procedure
    begin
      if (FCurrentState <> DestroyingState) and Assigned(FOnStateChange) then
        FOnStateChange(FCurrentState, Message);
    end);
end;

procedure TPipelineProcessor.RunStateMachine;
begin
  try
    // Verifica o token, não a referência da task
    FToken.ThrowIfCancellationRequested;

    case FCurrentState of
      IdleState:
        begin
          SetState(DownloadingCustomersState, 'Iniciando: Baixando Clientes...');
          // Avança para o próximo estado imediatamente
          RunStateMachine;
        end;

      DownloadingCustomersState:
        DoDownloadCustomerData;

      DownloadingProductsState:
        DoDownloadProductData;

      GeneratingReportState:
        DoGenerateReport;
    end;
  except
    on E: EOperationCancelled do
      SetState(CanceledState, 'Pipeline cancelado pelo usuário.');

    on E: Exception do
      SetState(FailedState, 'ERRO: ' + E.ToString);
  end;
end;

procedure TPipelineProcessor.DoDownloadCustomerData;
var
  i, Count: Integer;
  FirstNames, LastNames: TArray<string>;
begin
  FToken.ThrowIfCancellationRequested;
  // Simula trabalho
  Sleep(2000);

  FCustomerData := TStringList.Create;
  FirstNames := ['Joao', 'Maria', 'Pedro', 'Ana', 'Carlos', 'Mariana', 'Lucas'];
  LastNames := ['Silva', 'Souza', 'Pereira', 'Ferreira', 'Almeida', 'Lima'];

  // Gera de 3 a 10 clientes
  Count := Random(8) + 3;
  for i := 1 to Count do
  begin
    FToken.ThrowIfCancellationRequested;
    FCustomerData.Add(Format('Cliente: %d - %s %s', [i,
      FirstNames[Random(Length(FirstNames))],
      LastNames[Random(Length(LastNames))]]));
  end;

  SetState(DownloadingProductsState,
    Format('%d Clientes baixados. Baixando Produtos...', [Count]));
  RunStateMachine;
end;

procedure TPipelineProcessor.DoDownloadProductData;
var
  i, Count: Integer;
  Products: TArray<string>;
begin
  FToken.ThrowIfCancellationRequested;
  Sleep(1500); // Simula trabalho

  FProductData := TStringList.Create;
  Products := ['Notebook', 'Mouse', 'Teclado', 'Monitor', 'Webcam', 'SSD'];

  Count := Random(5) + 2; // Gera de 2 a 6 produtos
  for i := 1 to Count do
  begin
    FToken.ThrowIfCancellationRequested;
    FProductData.Add(Format('Produto: %d - %s',
      [100 + i, Products[Random(Length(Products))]]));
  end;

  SetState(GeneratingReportState,
    Format('%d Produtos baixados. Gerando Relatório...', [Count]));
  RunStateMachine;
end;

procedure TPipelineProcessor.DoGenerateReport;
var
  Report: TStrings;
begin
  FToken.ThrowIfCancellationRequested;
  Sleep(1000); // Simula trabalho

  Report := TStringList.Create;
  try
    Report.Add(Format('Relatório Gerado: %d clientes e %d produtos.',
      [FCustomerData.Count, FProductData.Count]));
    Report.Add('--- Clientes ---');
    Report.AddStrings(FCustomerData);
    Report.Add('--- Produtos ---');
    Report.AddStrings(FProductData);
    Report.Add('----------------');
    SetState(CompletedState, 'PIPELINE CONCLUÍDO:' + sLineBreak + Report.Text);
  finally
    Report.Free;
  end;
end;

end.


