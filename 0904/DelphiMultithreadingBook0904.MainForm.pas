unit DelphiMultithreadingBook0904.MainForm;

interface

uses
  FMX.Controls, FMX.Controls.Presentation, FMX.Forms, FMX.Memo, FMX.Memo.Types,
  FMX.StdCtrls, FMX.ScrollBox, FMX.Types, System.Classes, System.Threading,
  DelphiMultithreadingBook.Utils, FMX.Layouts;

type
  TMainForm = class(TForm)
    LogMemo: TMemo;
    Layout: TLayout;
    RequestSuccessButton: TButton;
    RequestFailButton: TButton;
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure RequestSuccessButtonClick(Sender: TObject);
    procedure RequestFailButtonClick(Sender: TObject);
  private
    FCurrentTask: ITask;
    procedure RunNetworkRequest(const URL: string);
    procedure SetButtonStates(RunningState: TRunningState);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
  System.Net.HttpClient, // THTTPClient
  System.SysUtils;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogMemo.WordWrap := True;
  LogWrite('Aplicação iniciada.');
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  UnregisterLogger;
  // Se uma tarefa de rede ainda estiver em execução quando
  // o formulário for destruído, solicita seu cancelamento.
  if Assigned(FCurrentTask) then
  begin
    FCurrentTask.Cancel;
  end;
end;

procedure TMainForm.RequestFailButtonClick(Sender: TObject);
begin
  // URL inválida para forçar uma exceção de rede
  RunNetworkRequest('https://urlinexistente.fail');
end;

procedure TMainForm.RequestSuccessButtonClick(Sender: TObject);
begin
  // URL válida para um teste de sucesso
  RunNetworkRequest('https://www.google.com');
end;

procedure TMainForm.RunNetworkRequest(const URL: string);
begin
  if Assigned(FCurrentTask) then
  begin
    LogWrite('Aguarde a requisição anterior terminar.');
    Exit;
  end;

  LogWrite('> Iniciando requisição para: ' + URL);
  SetButtonStates(IsRunning);

  FCurrentTask := TTask.Run(
    procedure
    var
      ExceptionObject: TObject;
      HTTPClient: THTTPClient;
      Response: string;
    begin
      HTTPClient := THTTPClient.Create;
      try
        try
          // Lógica de trabalho real: fazer a requisição de rede
          Response := HTTPClient.Get(URL).ContentAsString;

          // Se chegou aqui, a requisição foi bem-sucedida
          TThread.Queue(nil,
            procedure
            begin
              LogWrite('Sucesso! Resposta recebida (primeiros 100 caracteres):');
              LogWrite(Copy(Response, 1, 100) + '...');
            end);
        except
          on E: Exception do
          begin
            // Captura a exceção de rede (ou qualquer outra)
            ExceptionObject := AcquireExceptionObject;
            TThread.Queue(nil,
              procedure
              begin
                LogWrite('--- ERRO NA REQUISIÇÃO ---');
                LogWrite('Exceção: ' + (ExceptionObject as Exception).ClassName);
                LogWrite('Mensagem: ' + (ExceptionObject as Exception).Message);
                // Libera o objeto de exceção na thread principal
                ExceptionObject.Free;
              end);
          end;
        end;
      finally
        // Garante que o estado da UI seja restaurado, não importa o que aconteça
        TThread.Queue(nil,
          procedure
          begin
            SetButtonStates(IsStopped);
            FCurrentTask := nil;
          end);
        HTTPClient.Free;
      end;
    end);
end;

procedure TMainForm.SetButtonStates(RunningState: TRunningState);
begin
  if csDestroying in ComponentState then
    Exit;
  RequestSuccessButton.Enabled := RunningState = IsStopped;
  RequestFailButton.Enabled := RunningState = IsStopped;
end;

end.
