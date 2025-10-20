unit DelphiMultithreadingBook0908.MainForm;

interface

uses
  FMX.Controls, FMX.Controls.Presentation, FMX.Forms, FMX.Graphics, FMX.ImgList,
  FMX.Layouts, FMX.ListView, FMX.ListView.Adapters.Base, FMX.ListView.Appearances,
  FMX.ListView.Types, FMX.Memo, FMX.Memo.Types, FMX.ScrollBox, FMX.StdCtrls,
  FMX.Types, System.Classes, System.ImageList, System.Permissions,
  System.Threading, System.Types,
  DelphiMultithreadingBook.CancellationToken,
  DelphiMultithreadingBook0908.ImageProcessor;

type
  TMainForm = class(TForm)
    CancelButton: TButton;
    Layout: TLayout;
    LogMemo: TMemo;
    StartButton: TButton;
    ProgressBar: TProgressBar;
    Layout1: TLayout;
    DeleteOutputButton: TButton;
    procedure DeleteOutputButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure StartButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
  private
    FCurrentTask: ITask;
    FCancellationTokenSource: TCancellationTokenSource;
    FImageProcessor: TImageProcessor;
    FOutputPath: string;
    FPicturesPath: string;
    FProcessedCount: Integer;
    FTotalCount: Integer;
    function HasOutputFiles: Boolean;
    procedure Configure;
    procedure StartProcessing;
    procedure ProcessingProgress;
    procedure ProcessingComplete(const Cancelled: Boolean;
      const ElapsedMs: Int64);
    procedure RequestPermissionsResult(Sender: TObject;
      const Permissions: TClassicStringDynArray;
      const GrantResults: TClassicPermissionStatusDynArray);
    procedure SetControlsState(IsRunning: Boolean);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
  FMX.DialogService,
  FMX.MultiResBitmap,
  System.IOUtils,
  System.SysUtils,
  System.UITypes,
  DelphiMultithreadingBook.Utils;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogMemo.WordWrap := True;
  Configure;
  SetControlsState(False);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  UnregisterLogger;
  if Assigned(FCancellationTokenSource) then
  begin
    FCancellationTokenSource.Cancel;
    FCancellationTokenSource.Free;
  end;

  if Assigned(FImageProcessor) then
    FImageProcessor.Free;
end;

function TMainForm.HasOutputFiles: Boolean;
begin
  Result := (FOutputPath <> '') and TDirectory.Exists(FOutputPath)
    and not TDirectory.IsEmpty(FOutputPath);
end;

procedure TMainForm.StartButtonClick(Sender: TObject);
begin
  SetControlsState(True);
  LogMemo.Lines.Clear;
  LogWrite('> Solicitando permissão de leitura de armazenamento no dispositivo.');
  TTask.Run(
    procedure
    begin
      PermissionsService.RequestPermissions([
        'android.permission.READ_EXTERNAL_STORAGE',
        'android.permission.READ_MEDIA_IMAGES',
        'android.permission.READ_MEDIA_VISUAL_USER_SELECTED'],
        RequestPermissionsResult);
    end);
end;

procedure TMainForm.CancelButtonClick(Sender: TObject);
begin
  if Assigned(FCancellationTokenSource) then
    FCancellationTokenSource.Cancel;
end;

procedure TMainForm.DeleteOutputButtonClick(Sender: TObject);
begin
  if HasOutputFiles then
  begin
    TDialogService.MessageDialog('Excluir todos arquivos criados?',
      TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbNo, TMsgDlgBtn.mbYes],
      TMsgDlgBtn.mbYes, 0,
      procedure(const Result: TModalResult)
      begin
        if Result = mrYes then
        begin
          TDirectory.Delete(FOutputPath, True);
          SetControlsState(False);
        end;
      end
    );
  end;
end;

procedure TMainForm.Configure;
begin
{$IFDEF MSWINDOWS}
  FPicturesPath := TPath.GetPicturesPath;
{$ELSE}
  FPicturesPath := TPath.GetSharedPicturesPath;
{$ENDIF};
  FOutputPath := TPath.Combine(FPicturesPath, 'Filtered_Grayscale');
end;

procedure TMainForm.RequestPermissionsResult(Sender: TObject;
  const Permissions: TClassicStringDynArray;
  const GrantResults: TClassicPermissionStatusDynArray);
begin
  if (Length(GrantResults) > 0) and
     (GrantResults[0] = TPermissionStatus.Granted) then
  begin
    LogWrite('* Permissão concedida.');
    LogWrite('> Iniciando leitura...');
    StartProcessing;
  end
  else
  begin
    LogWrite('! Permissão para ler arquivos foi negada.');
    SetControlsState(False);
  end;
end;


procedure TMainForm.StartProcessing;
var
  ImagePaths: TStringDynArray;
  Token: ICancellationToken;
begin
  ImagePaths := TDirectory.GetFiles(FPicturesPath, '*.*',
    function(const Path: string; const SearchRec: TSearchRec): Boolean
    begin
      try
        Result := TPath.MatchesPattern(SearchRec.Name, '*.jpg', False);
      except
        on E: Exception do
        begin
          Result := False;
          LogWrite('ERRO: ' + E.ToString);
        end;
      end;
    end);

  if Length(ImagePaths) > 0 then
  begin
    SetControlsState(True);
    FProcessedCount := 0;
    FTotalCount := Length(ImagePaths);
    ProgressBar.Max := FTotalCount;
    LogWrite('%d imagens jpg encontradas em %s.',
      [FTotalCount, QuotedStr(FPicturesPath)]);

    if not TDirectory.Exists(FOutputPath) then
      TDirectory.CreateDirectory(FOutputPath);

    if FCancellationTokenSource = nil then
      FCancellationTokenSource := TCancellationTokenSource.Create
    else
      FCancellationTokenSource.Reset;
    Token := FCancellationTokenSource.Token;

    LogWrite('Iniciando processamento, UI NÃO reponsiva.');
    FImageProcessor := TImageProcessor.Create;
    FCurrentTask := FImageProcessor.ProcessImagesAsync(ImagePaths,
      FOutputPath, Token, ProcessingProgress, ProcessingComplete);
  end
  else
    LogWrite('Nenhuma imagem jpg encontrada em %s.', [QuotedStr(FPicturesPath)]);
end;

procedure TMainForm.ProcessingProgress;
begin
  if csDestroying in ComponentState then Exit;
  Inc(FProcessedCount);
  ProgressBar.Value := FProcessedCount;
  LogWrite(Format('%d de %d imagens processadas...',
    [FProcessedCount, FTotalCount]));
  LogMemo.GoToTextEnd;
end;

procedure TMainForm.ProcessingComplete(const Cancelled: Boolean;
  const ElapsedMs: Int64);
begin
  if csDestroying in ComponentState then Exit;
  if Cancelled then
    LogWrite('Processamento cancelado.')
  else
    LogWrite(Format('Processamento concluído em %d ms.', [ElapsedMs]));

  LogWrite('* Atenção, as imagens estão salvas em %s! ',
    [QuotedStr(FOutputPath)]);

  FCurrentTask := nil;
  FImageProcessor.Free;
  FImageProcessor := nil;
  SetControlsState(False);
end;

procedure TMainForm.SetControlsState(IsRunning: Boolean);
begin
  StartButton.Enabled := not IsRunning;
  CancelButton.Enabled := IsRunning;
  CancelButton.Visible := IsRunning;
  DeleteOutputButton.Enabled := not IsRunning and HasOutputFiles;
  LogMemo.GoToTextEnd;
end;

end.

