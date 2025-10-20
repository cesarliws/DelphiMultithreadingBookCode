unit DelphiMultithreadingBook0906.ApiDownloader;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  System.Threading;

type
  TDownloadResult = record
    URL: string;
    Content: string;
    CaughtException: Exception;
  end;

  TBatchDownloadCompleteCallback =
    reference to procedure(const Results: TArray<TDownloadResult>);

  TApiDownloader = class
  private
    FOrchestratorTask: ITask;
  public
    // MÉTODO PÚBLICO para baixar uma única URL de forma assíncrona
    function DownloadUrlAsync(const URL: string): IFuture<string>;

    // MÉTODO PÚBLICO para baixar um lote de URLs
    procedure DownloadBatchAsync(const Urls: TArray<string>;
      OnComplete: TBatchDownloadCompleteCallback);

    procedure Cancel;
  end;

implementation

uses
  System.Net.HttpClient,
  System.Classes, // TThread
  DelphiMultithreadingBook.Utils;

{ TApiDownloader }

procedure TApiDownloader.Cancel;
begin
  if Assigned(FOrchestratorTask) then
    FOrchestratorTask.Cancel;
end;

procedure TApiDownloader.DownloadBatchAsync(const Urls: TArray<string>;
  OnComplete: TBatchDownloadCompleteCallback);
begin
  FOrchestratorTask := TTask.Run(
    procedure
    var
      DownloadTasks: TArray<IFuture<string>>;
      Results: TArray<TDownloadResult>;
      i: Integer;
    begin
      // Etapa 1: Disparar uma tarefa para cada URL
      SetLength(DownloadTasks, Length(Urls));
      for i := 0 to High(Urls) do
      begin
        DownloadTasks[i] := DownloadUrlAsync(Urls[i]);
      end;

      // Etapa 2: Coletar os resultados
      SetLength(Results, Length(DownloadTasks));
      for i := 0 to High(DownloadTasks) do
      begin
        Results[i].URL := Urls[i];
        try
          Results[i].Content := DownloadTasks[i].Value;
          Results[i].CaughtException := nil;
        except
          on E: Exception do
          begin
            Results[i].Content := '';
            Results[i].CaughtException := Exception(AcquireExceptionObject);
          end;
        end;
      end;

      // Etapa 3: Invocar o callback final na thread da UI
      TThread.Queue(nil,
        procedure
        begin
          if Assigned(OnComplete) then
            OnComplete(Results);
        end);
    end);
end;

function TApiDownloader.DownloadUrlAsync(const URL: string): IFuture<string>;
begin
  // A criação da TTask é encapsulada neste método.
  Result := TTask.Future<string>(
    function: string
    var
      HTTPClient: THTTPClient;
      Response: IHTTPResponse;
    begin
      HTTPClient := THTTPClient.Create;
      try
        DebugLogWrite('Downloader: Baixando URL: %s', [URL]);
        TTask.CurrentTask.CheckCanceled;
        Response := HTTPClient.Get(URL);

        if Response.StatusCode = 200 then
          Result := Response.ContentAsString
        else
          raise Exception.CreateFmt('Falha ao baixar %s: Status %d',
            [URL, Response.StatusCode]);
      finally
        HTTPClient.Free;
      end;
    end
  );
end;

end.
