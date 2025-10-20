unit DelphiMultithreadingBook0503.AsyncDownloader;

interface

uses
  System.Classes;

type
  TProgressEvent = procedure(const Sender: TObject; Progress: Integer) of object;
  TCompletionEvent = procedure(const Sender: TObject; Succeeded: Boolean;
    const Text: string) of object;

  TAsyncDownloader = class
  private
    FDestroying: Boolean;
    FOnProgress: TProgressEvent;
    FOnCompletion: TCompletionEvent;
    // Referência à thread anônima
    FWorkerThread: TThread;
    function GetIsBusy: Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    procedure DownloadFile(const Url: string);
    procedure Cancel;
    procedure FinalizeWorker;

    property OnProgress: TProgressEvent read FOnProgress write FOnProgress;
    property OnCompletion: TCompletionEvent read FOnCompletion write FOnCompletion;
    property IsBusy: Boolean read GetIsBusy;
  end;

  THttpClient = class
  public
    class function Get(const Url: string): string; static;
  end;

implementation

uses
  System.SysUtils,
  DelphiMultithreadingBook.Utils;

{ TAsyncDownloader }

constructor TAsyncDownloader.Create;
begin
  inherited Create;
  FWorkerThread := nil;
end;

destructor TAsyncDownloader.Destroy;
begin
  // Usamos FDestroying aqui por que este objeto não é um TComponent
  // para verificar "csDestroying in Component".
  FDestroying := True;
  FinalizeWorker;
  inherited;
end;

function TAsyncDownloader.GetIsBusy: Boolean;
begin
  // A verificação de "ocupado" continua a mesma
  Result := Assigned(FWorkerThread) and (not FWorkerThread.Finished);
end;
procedure TAsyncDownloader.DownloadFile(const Url: string);
var
  CurrentUrl: string;
begin
  if IsBusy then
  begin
    raise Exception.Create('Downloader já está ocupado.');
  end;

  FinalizeWorker;

   // Copia para variável local para uso na closure
  CurrentUrl := Url;

  FWorkerThread := TThread.CreateAnonymousThread(
    // Método anônimo que será executado na thread
    procedure
    var
      i: Integer;
      Cancelled: Boolean;
    begin
      DebugLogWrite('Downloader: Iniciando download de "%s"...', [CurrentUrl]);
      try
        Cancelled := False;
        // Simula progresso do download
        for i := 0 to 99 do
        begin
          // Verifica se a thread foi solicitada para terminar
          // ou se o cancelamento foi pedido
          if TThread.CheckTerminated then
          begin
            Cancelled := True;
            DebugLogWrite('Downloader: Cancelado ou Terminado.');
            Break;
          end;

          // TODO : Implementar Download com a classe THttpClient real
          THttpClient.Get(Format('%s?part=%d', [CurrentUrl, i]));


          // Reporta progresso via callback (na thread principal)
          TThread.Queue(nil,
            procedure
            begin
              // Self aqui é o TAsyncDownloader
              if Assigned(Self.FOnProgress) then
                Self.FOnProgress(Self, i);
            end
          );
        end;

        // Notifica a conclusão (sucesso ou cancelamento)
        if Assigned(Self.FOnCompletion) and not FDestroying then
        begin
          TThread.Queue(nil,
            procedure
            begin
              // A flag 'Cancelled' é necessária aqui, pois dentro de um Queue,
              // TThread.CurrentThread se refere à MainThread, e não mais à
              // nossa thread de trabalho.
              if Cancelled then
                Self.FOnCompletion(Self, False, 'Download cancelado.')
              else
                Self.FOnCompletion(Self, True,
                  Format('Download de %s concluído com sucesso!', [CurrentUrl]));
            end
          );
        end;
      except
        on E: Exception do
        begin
          DebugLogWrite('Downloader: Erro inesperado: %s', [E.Message]);
          TThread.Queue(nil,
            procedure
            begin
              if Assigned(Self.FOnCompletion) then
                Self.FOnCompletion(Self, False, Format('Erro no download: %s',
                  [E.Message]));
            end
          );
        end;
      end;
      DebugLogWrite('Downloader: Thread de download finalizada.');
    end
  );

  // Gerenciamento manual (FreeOnTerminate = False) para garantir que
  // podemos chamar WaitFor de forma segura no destructor do TAsyncDownloader.
  FWorkerThread.FreeOnTerminate := False;
  // Inicia a thread
  FWorkerThread.Start;
end;

procedure TAsyncDownloader.Cancel;
begin
  if Assigned(FWorkerThread) then
  begin
    FWorkerThread.Terminate;
  end;
end;

procedure TAsyncDownloader.FinalizeWorker;
begin
  if Assigned(FWorkerThread) then
  begin
    FWorkerThread.Terminate;
    FWorkerThread.WaitFor;
    FWorkerThread.Free;
  end;
end;

{ THttpClient }

class function THttpClient.Get(const Url: string): string;
begin
  // Simula o tempo de download
  Sleep(50 + Random(250));
  Result := Format('[200] - OK: %s', [Url]);
end;

end.

