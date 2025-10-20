unit DelphiMultithreadingBook0906.MainForm;

interface

uses
  FMX.Controls, FMX.Controls.Presentation, FMX.Forms, FMX.Memo,
  FMX.Memo.Types, FMX.ScrollBox, FMX.StdCtrls, FMX.Types,
  System.Classes, System.Threading,
  DelphiMultithreadingBook.Utils,
  DelphiMultithreadingBook0906.ApiDownloader, FMX.Layouts;

type
  TMainForm = class(TForm)
    LogMemo: TMemo;
    Layout: TLayout;
    IniciarDownloadAPIsButton: TButton;
    CancelarDownloadsButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure IniciarDownloadAPIsButtonClick(Sender: TObject);
    procedure CancelarDownloadsButtonClick(Sender: TObject);
  private
    FDownloader: TApiDownloader;
    procedure SetButtonStates(RunningState: TRunningState);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
  System.SysUtils,
  System.Diagnostics,
  System.Generics.Collections;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplicação iniciada.');
  SetButtonStates(IsStopped);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  // Garante que qualquer operação em andamento seja cancelada
  if Assigned(FDownloader) then
    FDownloader.Cancel;
  UnregisterLogger;
end;

procedure TMainForm.SetButtonStates(RunningState: TRunningState);
begin
  if csDestroying in ComponentState then
    Exit;
  IniciarDownloadAPIsButton.Enabled := RunningState = IsStopped;
  CancelarDownloadsButton.Enabled := RunningState = IsRunning;
end;

procedure TMainForm.IniciarDownloadAPIsButtonClick(Sender: TObject);
var
  UrlsToDownload: TArray<string>;
  Stopwatch: TStopwatch;
begin
  if Assigned(FDownloader) then
  begin
    LogWrite('Aguarde os downloads anteriores terminarem.');
    Exit;
  end;

  LogWrite('> Iniciando download paralelo de APIs...');
  SetButtonStates(IsRunning);

  UrlsToDownload := [
    // APIs Financeiras (JSON) - Rápidas
    'https://api.coinbase.com/v2/exchange-rates?currency=BTC',
    'https://economia.awesomeapi.com.br/json/last/USD-BRL',
    'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd',

    // APIs de Informação/Diversão (JSON) - Rápidas
    'https://api.github.com/users/octocat',
    'https://catfact.ninja/fact',
    'https://official-joke-api.appspot.com/random_joke',

    // Arquivo de Texto (Maior) - Potencialmente mais lento
    'https://www.gutenberg.org/files/2701/2701-0.txt', // Moby Dick

    // URL para simular falha
    'https://url-invalida-para-teste.fail'
  ];

  Stopwatch := TStopwatch.StartNew;
  FDownloader := TApiDownloader.Create;
  FDownloader.DownloadBatchAsync(UrlsToDownload,
    // Callback 'OnComplete' - Este código será executado na UI Thread
    procedure(const Results: TArray<TDownloadResult>)
    var
      ResultItem: TDownloadResult;
    begin
      LogWrite('--- Resultados dos Downloads Paralelos ---');
      for ResultItem in Results do
      begin
        if Assigned(ResultItem.CaughtException) then
        begin
          LogWrite('[FALHA] %s: %s',
            [ResultItem.URL, ResultItem.CaughtException.Message]);
          // Libera a exceção que foi capturada com AcquireExceptionObject
          ResultItem.CaughtException.Free;
        end
        else
        begin
          LogWrite('[OK] %s: Concluído (%d bytes)',
            [ResultItem.URL, Length(ResultItem.Content)]);
          LogWrite('- Resposta recebida (primeiros 100 caracteres):');
          LogWrite('- "' + Copy(ResultItem.Content, 1, 100) + '..."');
        end;
      end;

      Stopwatch.Stop;
      LogWrite('Tempo total: %d ms.', [Stopwatch.ElapsedMilliseconds]);
      LogWrite('----------------------------------------');
      SetButtonStates(IsStopped);
      FDownloader.Free; // Libera o downloader
      FDownloader := nil;
    end
  );

  LogWrite('Requisições disparadas para %d URLs. UI continua responsiva.',
    [Length(UrlsToDownload)]);
end;

procedure TMainForm.CancelarDownloadsButtonClick(Sender: TObject);
begin
  if Assigned(FDownloader) then
  begin
    LogWrite('Solicitando cancelamento dos downloads...');
    FDownloader.Cancel;
  end;
end;

end.
