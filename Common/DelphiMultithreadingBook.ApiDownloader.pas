unit DelphiMultithreadingBook.ApiDownloader;

interface

uses
  System.Classes,
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
    FCurrentTask: ITask;
  public
    // Download uma única URL de forma assíncrona
    function DownloadUrlAsync(const URL: string): IFuture<string>;

    // Download de um lote de URLs
    procedure DownloadBatchAsync(const Urls: TArray<string>;
      OnComplete: TBatchDownloadCompleteCallback);

    // Download com paginação
    function DownloadAllPagesAsync(const InitialURL: string): IFuture<TStrings>;
    procedure Cancel;
  end;

implementation

uses
  System.Json,
  System.NetConsts,
  System.Net.HttpClient,
  System.Net.URLClient,
  DelphiMultithreadingBook.Utils;

{ TApiDownloader }

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

procedure TApiDownloader.DownloadBatchAsync(const Urls: TArray<string>;
  OnComplete: TBatchDownloadCompleteCallback);
begin
  FCurrentTask := TTask.Run(
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

function TApiDownloader.DownloadAllPagesAsync(
  const InitialURL: string): IFuture<TStrings>;
begin
  Result := TTask.Future<TStrings>(
    function: TStrings
    var
      NextUrl: string;
      HTTPClient: THTTPClient;
      Response: IHTTPResponse;
      JsonObject, JsonInfo: TJSONObject;
      JsonArray: TJSONArray;
      DataList: TStringList;
    begin
      DataList := TStringList.Create;
      try
        HTTPClient := THTTPClient.Create;
        try
          HTTPClient.UserAgent := 'Delphi-Multithreading-Book-Example/1.0';
          NextUrl := InitialURL;

          while not NextUrl.IsEmpty do
          begin
            TTask.CurrentTask.CheckCanceled;
            // LogWrite é thread-safe: Usado para dar um feedback de progresso
            // O ideal é usar notificação ou callback
            LogWrite('Buscando página: %s', [NextUrl]);

            Response := HTTPClient.Get(NextUrl);

            if Response.StatusCode <> 200 then
              raise Exception.CreateFmt('Falha na requisição: Status %d - %s',
                [Response.StatusCode, Response.StatusText]);

            JsonObject := nil;
            try
              JsonObject := TJSONObject.ParseJSONValue(Response.ContentAsString)
                as TJSONObject;
              if not Assigned(JsonObject) then Break;
              JsonArray := JsonObject.GetValue('results') as TJSONArray;
              if Assigned(JsonArray) then
                for var JsonValue in JsonArray do
                  if (JsonValue is TJSONObject) and
                    ((JsonValue as TJSONObject).TryGetValue('name', NextUrl)) then
                    DataList.Add(NextUrl);

              if (JsonObject.TryGetValue('info', JsonInfo)) then
              begin
                if JsonInfo.TryGetValue('next', NextUrl) then
                begin
                  if NextUrl = 'null' then NextUrl := '';
                end
                else
                  NextUrl := '';
                JsonInfo := nil;
              end;
            finally
              JsonObject.Free;
            end;
          end;
        finally
          HTTPClient.Free;
        end;
        Result := DataList;
        DataList := nil;
      except
        DataList.Free;
        raise;
      end;
    end
  );
  FCurrentTask := Result;
end;

procedure TApiDownloader.Cancel;
begin
  if Assigned(FCurrentTask) then
    FCurrentTask.Cancel;
end;

end.
