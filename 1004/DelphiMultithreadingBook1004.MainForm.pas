unit DelphiMultithreadingBook1004.MainForm;

interface

uses
  System.Classes, System.Threading, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  DelphiMultithreadingBook.Utils,
  DelphiMultithreadingBook.CancellationToken;

type
  TMainForm = class(TForm)
    StartPipelineButton: TButton;
    CancelButton: TButton;
    LogMemo: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure StartPipelineButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
  private
    FOrchestratorTask: ITask;
    // Fonte para criar e controlar o token de cancelamento
    FCancellationTokenSource: TCancellationTokenSource;
    procedure SetButtonStates(IsRunning: Boolean);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.SysUtils,
  DelphiMultithreadingBook1004.PipelineTasks;

procedure TMainForm.CancelButtonClick(Sender: TObject);
begin
  // Agora, cancelamos a FONTE, e o sinal se propaga para todos
  if Assigned(FCancellationTokenSource) then
  begin
    LogWrite('Solicitando cancelamento do pipeline...');
    FCancellationTokenSource.Cancel;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  // Garante o cancelamento ao fechar
  if Assigned(FCancellationTokenSource) then
    FCancellationTokenSource.Cancel;
  // O FOrchestratorTask.Wait seria ideal aqui para garantir
  // que a task termine antes de o form fechar, mas pode causar deadlock
  // se a task tentar usar TThread.Queue. O cancelamento já é uma boa proteção.
  FCancellationTokenSource.Free;
  UnregisterLogger;
end;

procedure TMainForm.SetButtonStates(IsRunning: Boolean);
begin
  StartPipelineButton.Enabled := not IsRunning;
  CancelButton.Enabled := IsRunning;
end;

procedure TMainForm.StartPipelineButtonClick(Sender: TObject);
var
  Token: ICancellationToken;
begin
  if Assigned(FOrchestratorTask) then
    Exit;

  LogMemo.Lines.Clear;
  LogWrite('> Iniciando pipeline de importação...');
  SetButtonStates(True);

  // Cria uma nova fonte de cancelamento para esta execução
  FCancellationTokenSource := TCancellationTokenSource.Create;
  Token := FCancellationTokenSource.Token;

  FOrchestratorTask := TTask.Run(
    procedure
    var
      CustomerFuture, ProductFuture: IFuture<TStrings>;
      ReportFuture: IFuture<string>;
      CustomerData, ProductData: TStrings;
      ReportResult: string;
    begin
      CustomerData := nil;
      ProductData := nil;
      try
        Token.ThrowIfCancellationRequested;
        LogWrite('Disparando download de Clientes e Produtos...');
        CustomerFuture := TPipelineTasks.DownloadCustomerDataAsync(Token);
        ProductFuture := TPipelineTasks.DownloadProductDataAsync(Token);

        TTask.WaitForAll([CustomerFuture, ProductFuture]);

        Token.ThrowIfCancellationRequested;
        CustomerData := CustomerFuture.Value;
        ProductData := ProductFuture.Value;
        LogWrite('Downloads concluídos. Consolidando relatório...');

        ReportFuture := TPipelineTasks.GenerateOrderReportAsync(
          CustomerData, ProductData, Token);

        ReportResult := ReportFuture.Value;
        TThread.Queue(nil,
          procedure
          begin
            LogWrite('PIPELINE CONCLUÍDO COM SUCESSO!');
            LogWrite(ReportResult);
          end);
      except
        on E: EOperationCancelled do
        begin
          TThread.Queue(nil,
            procedure
            begin
              LogWrite('PIPELINE CANCELADO PELO USUÁRIO.');
            end);
        end;
        on E: Exception do
        begin
          ReportResult := E.ToString;
          TThread.Queue(nil, procedure
            begin
              LogWrite('ERRO NO PIPELINE: ' + ReportResult);
            end);
        end;
      end;

      TThread.Queue(nil,
        procedure
        begin
          CustomerData.Free;
          ProductData.Free;
          FCancellationTokenSource.Free;
          FCancellationTokenSource := nil;
          FOrchestratorTask := nil;
          if not (csDestroying in ComponentState) then
            SetButtonStates(False);
        end);
    end);
end;

end.
