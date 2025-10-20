unit DelphiMultithreadingBook1102.DBWorkerThread;

interface

uses
  System.Classes,
  System.SysUtils,
  FireDAC.Stan.Def,
  FireDAC.Stan.Intf,
  DelphiMultithreadingBook.CancellationToken,
  DelphiMultithreadingBook1102.WorkerDataModule;

type
  TDataReadyEvent = reference to procedure(const DataStream: TStream);
  TDataErrorEvent = reference to procedure(const E: Exception);

  TDBWorkerThread = class(TThread)
  private
    FConnParams: TStrings;
    FSQL: string;
    FOnDataReady: TDataReadyEvent;
    FOnDataError: TDataErrorEvent;
    FToken: ICancellationToken;
    FDataModule: TWorkerDM;
  protected
    procedure Execute; override;
  public
    constructor Create(const ConnParams: TStrings; const SQL: string;
      const Token: ICancellationToken; OnDataReady: TDataReadyEvent;
      OnDataError: TDataErrorEvent);
    destructor Destroy; override;
  end;

implementation

uses
  FireDAC.Comp.Client;

{ TDBWorkerThread }

constructor TDBWorkerThread.Create(const ConnParams: TStrings;
  const SQL: string; const Token: ICancellationToken;
  OnDataReady: TDataReadyEvent; OnDataError: TDataErrorEvent);
begin
  // Thread se auto-libera
  FreeOnTerminate := True;
  FConnParams := TStringList.Create;
  FConnParams.AddStrings(ConnParams);
  FSQL := SQL;
  FToken := Token;
  FOnDataReady := OnDataReady;
  FOnDataError := OnDataError;
  FDataModule := TWorkerDM.Create(nil);
  // Inicia imediatamente
  inherited Create(False);
end;

destructor TDBWorkerThread.Destroy;
begin
  FConnParams.Free;
  FDataModule.Free;
  inherited;
end;

procedure TDBWorkerThread.Execute;
var
  DataStream: TStream;
  ExceptionObj: TObject;
begin
  // Cria uma instância do DataModule para uso exclusivo desta thread
  try
    FDataModule.FDConnection.Params.AddStrings(FConnParams);
    FDataModule.FDConnection.Open;
    FToken.ThrowIfCancellationRequested;
    FDataModule.LoadData(FSQL);

    // Transfere os dados para um TMemoryStream
    DataStream := TMemoryStream.Create;
    try
      FDataModule.FDQuery.SaveToStream(DataStream, TFDStorageFormat.sfBinary);
      DataStream.Position := 0;

      // Envia o stream para a UI thread
      TThread.Synchronize(nil,
        procedure
        begin
          if Assigned(FOnDataReady) then
            FOnDataReady(DataStream);
        end);
    except
      begin
        // Garante que o stream seja liberado se a transferência falhou
        DataStream.Free;
         // Re-lança a exceção para o mecanismo da TThread
        raise;
      end;
    end;
  except
    on E: Exception do
    begin
      // Captura e passa a exceção para a UI thread (Tópico 4.5)
      ExceptionObj := AcquireExceptionObject;
      TThread.Synchronize(nil,
        procedure
        begin
          if Assigned(FOnDataError) then
            FOnDataError(ExceptionObj as Exception);
          // A UI thread é responsável por liberar a exceção
          ExceptionObj.Free;
        end);
    end;
  end;
end;

end.
