unit DelphiMultithreadingBook1002.MainForm;

interface

uses
  System.Classes, System.Threading,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ComCtrls,
  DelphiMultithreadingBook.ApiDownloader,
  DelphiMultithreadingBook.Utils;

type
  TMainForm = class(TForm)
    FetchButton: TButton;
    CancelButton: TButton;
    LogMemo: TMemo;
    procedure FetchButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FDownloader: TApiDownloader;
    FContinuationTask: ITask;
    procedure SetButtonStates(IsRunning: Boolean);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.SysUtils;

const
  RICK_AND_MORTY_API_URL = 'https://rickandmortyapi.com/api/character';

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplicação iniciada.');
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not Assigned(FDownloader);
  if not CanClose then
  begin
    LogWrite('* Cancele o processamento para fechar a Janela.');
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  if Assigned(FDownloader) then
    FDownloader.Cancel;
  UnregisterLogger;
end;

procedure TMainForm.CancelButtonClick(Sender: TObject);
begin
  if Assigned(FDownloader) then
    FDownloader.Cancel;
end;

procedure TMainForm.FetchButtonClick(Sender: TObject);
var
  CharactersFuture: IFuture<TStrings>;
begin
  if Assigned(FContinuationTask) then
  begin
    LogWrite('Aguarde a busca anterior terminar.');
    Exit;
  end;

  LogWrite('> Buscando todos os personagens de Rick and Morty (paginado)...');
  SetButtonStates(True);
  LogMemo.Lines.Clear;

  FDownloader := TApiDownloader.Create;
  CharactersFuture := FDownloader.DownloadAllPagesAsync(RICK_AND_MORTY_API_URL);

  FContinuationTask := TTask.Run(
    procedure
    var
      CharacterNames: TStrings;
      ExceptionObj: TObject;
    begin
      try
        CharacterNames := CharactersFuture.Value;

        TThread.Queue(nil,
          procedure
          begin
            // O código dentro do Queue é executado na UI thread.
            try
              LogWrite('Busca concluída! Total de %d personagens encontrados.',
                [CharacterNames.Count]);
              LogWrite('---');
              LogMemo.Lines.AddStrings(CharacterNames);
            finally
              // Liberamos a lista DEPOIS de usá-la, no contexto da UI thread.
              CharacterNames.Free;
            end;
          end);
      except
        on E: Exception do
        begin
          ExceptionObj := AcquireExceptionObject;
          TThread.Queue(nil,
            procedure
            begin
              try
                LogWrite('ERRO: ' + (ExceptionObj as Exception).Message);
              finally
                (ExceptionObj as Exception).Free;
              end;
            end);
        end;
      end;
      // Bloco final para restaurar a UI
      TThread.Queue(nil,
        procedure
        begin
          SetButtonStates(False);
          FDownloader.Free;
          FDownloader := nil;
          FContinuationTask := nil;
        end);
    end);
end;

procedure TMainForm.SetButtonStates(IsRunning: Boolean);
begin
  FetchButton.Enabled := not IsRunning;
  CancelButton.Enabled := IsRunning;
end;

end.
