unit DelphiMultithreadingBook0503.MainForm;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  DelphiMultithreadingBook0503.AsyncDownloader,
  DelphiMultithreadingBook.Utils;

type
  TMainForm = class(TForm)
    IniciarAsyncDownloadButton: TButton;
    CancelarDownloadButton: TButton;
    LogMemo: TMemo;
    procedure CancelarDownloadButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure IniciarAsyncDownloadButtonClick(Sender: TObject);
  private
    // Instância do nosso downloader
    FDownloader: TAsyncDownloader;
    procedure DownloaderProgress(const Sender: TObject; Progress: Integer);
    procedure DownloaderComplete(const Sender: TObject; Succeeded: Boolean;
      const Text: string);
    procedure FinalizeDownloader;
    procedure SetButtonsState(RunningState: TRunningState);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.UITypes;

procedure TMainForm.CancelarDownloadButtonClick(Sender: TObject);
begin
  if Assigned(FDownloader) then
  begin
    FDownloader.Cancel;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);

  LogWrite('Aplicação iniciada.');
  LogWrite('Clique no botão para iniciar o Download Assíncrono.');

  FDownloader := TAsyncDownloader.Create;
  FDownloader.OnProgress := DownloaderProgress;
  FDownloader.OnCompletion := DownloaderComplete;

  LogMemo.ScrollBars := TScrollStyle.ssVertical;
  SetButtonsState(IsStopped);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FinalizeDownloader;
  UnregisterLogger;
end;

procedure TMainForm.IniciarAsyncDownloadButtonClick(Sender: TObject);
begin
  if not FDownloader.IsBusy then
  begin
    LogWrite('> Iniciando download...');
    // Desabilita enquanto ocupado
    SetButtonsState(IsRunning);
    // URL de exemplo, que pode ser alterada conforme necessário.
    FDownloader.DownloadFile('http://example.com/bigfile.zip');
  end
  else
  begin
    LogWrite('Downloader já está ocupado. Espere ou reinicie o aplicativo.');
  end;
end;

procedure TMainForm.SetButtonsState(RunningState: TRunningState);
begin
  if csDestroying in ComponentState then
    Exit;
  IniciarAsyncDownloadButton.Enabled := RunningState = IsStopped;
  CancelarDownloadButton.Enabled := RunningState = IsRunning;
end;

procedure TMainForm.DownloaderProgress(const Sender: TObject; Progress: Integer);
begin
  LogWrite('Download: %d%% concluído.', [Progress]);
end;

procedure TMainForm.DownloaderComplete(const Sender: TObject; Succeeded:
  Boolean; const Text: string);
begin
  LogWrite(Text);
  SetButtonsState(IsStopped);
end;

procedure TMainForm.FinalizeDownloader;
begin
  if Assigned(FDownloader) then
  begin
    FDownloader.Free;
    FDownloader := nil;
  end;
end;

end.
