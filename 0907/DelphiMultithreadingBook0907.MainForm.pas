unit DelphiMultithreadingBook0907.MainForm;

interface

uses
  FMX.Controls, FMX.Controls.Presentation, FMX.Forms, FMX.Graphics, FMX.ImgList,
  FMX.Layouts, FMX.ListView.Types, FMX.ListView, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.Memo, FMX.Memo.Types, FMX.ScrollBox,
  FMX.StdCtrls, FMX.Types, System.Classes, System.Diagnostics, System.ImageList,
  System.Permissions, System.Threading, System.Types,
  DelphiMultithreadingBook0907.ThumbnailLoader,
  DelphiMultithreadingBook.CancellationToken;

type
  TMainForm = class(TForm)
    AniIndicator: TAniIndicator;
    CancelButton: TButton;
    ImageList: TImageList;
    ImageListView: TListView;
    Layout: TLayout;
    LoadThumbnailsButton: TButton;
    LogMemo: TMemo;
    ProgressBar: TProgressBar;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure LoadThumbnailsButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
  private
    FCurrentTask: ITask;
    FCancellationTokenSource: TCancellationTokenSource;
    FImagePaths: TStringDynArray;
    function LoadBitmap(ImageList: TImageList; const Bitmap: TBitmap): Integer;
    procedure RequestPermissionsResult(Sender: TObject;
      const Permissions: TClassicStringDynArray;
      const GrantResults: TClassicPermissionStatusDynArray);
    procedure StartLoadingThumbnails;
    procedure SetControlsState(IsRunning, ShowAniIndicator: Boolean);
    procedure ThumbnailBatchProgress(const Batch: TArray<TThumbnailResult>);
    procedure ThumbnailCompletion(const Cancelled: Boolean);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
  FMX.MultiResBitmap,
  FMX.Platform,
  System.IOUtils,
  System.SysUtils,
  DelphiMultithreadingBook.Utils;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogMemo.WordWrap := True;
  SetControlsState(False, False);
  LoadThumbnailsButton.SetFocus;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  UnregisterLogger;
  if Assigned(FCancellationTokenSource) then
    FCancellationTokenSource.Cancel;
  FCancellationTokenSource.Free;
end;

procedure TMainForm.LoadThumbnailsButtonClick(Sender: TObject);
begin
  SetControlsState(True, True);
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
  LogWrite('! Solicitando cancelamento...');
  FCancellationTokenSource.Cancel;
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
    StartLoadingThumbnails;
  end
  else
  begin
    LogWrite('! Permissão para ler arquivos foi negada.');
    SetControlsState(False, False);
  end;
end;

procedure TMainForm.StartLoadingThumbnails;
begin
  ImageList.Source.Clear;
  ImageList.Destination.Clear;
  ImageListView.Items.Clear;

  // Task para listar os arquivos
  TTask.Run(
    procedure
    var
      PicturesPath: string;
    begin
      try
{$IFDEF MSWINDOWS}
        PicturesPath := TPath.GetPicturesPath;
{$ELSE}
        PicturesPath := TPath.GetSharedPicturesPath;
{$ENDIF}
        FImagePaths := TDirectory.GetFiles(PicturesPath, '*.*',
          function(const Path: string; const SearchRec: TSearchRec): Boolean
          begin
            try
              Result := TPath.MatchesPattern(SearchRec.Name, '*.png', False) or
                        TPath.MatchesPattern(SearchRec.Name, '*.jpg', False) or
                        TPath.MatchesPattern(SearchRec.Name, '*.jpeg', False);
            except
              on E: Exception do
              begin
                Result := False;
                LogWrite('ERRO: ' + E.ToString);
              end;
            end;
          end);

        TThread.Queue(nil,
          procedure
          var
            i: Integer;
            Token: ICancellationToken;
          begin
            if csDestroying in ComponentState then
              Exit;

            // 1. Popula a lista com placeholders (nomes dos arquivos)
            LogWrite('%d arquivos encontrados.', [Length(FImagePaths)]);
            LogWrite('Carregando imagens e criando miniaturas em background...');
            LogMemo.GoToTextEnd;
            ImageListView.Items.BeginUpdate;
            try
              for i := 0 to High(FImagePaths) do
              begin
                var Item := ImageListView.Items.Add;
                Item.Text := TPath.GetFileName(FImagePaths[i]);
                // Inicialmente sem imagem
                Item.ImageIndex := -1;
              end;
            finally
              ImageListView.Items.EndUpdate;
            end;

            // 2. Dispara o carregamento "suave" em background
            if Length(FImagePaths) > 0 then
            begin
              ProgressBar.Max := Length(FImagePaths);
              ProgressBar.Value := 0;
              if Assigned(FCancellationTokenSource) then
                FCancellationTokenSource.Reset
              else
                FCancellationTokenSource := TCancellationTokenSource.Create;

              Token := FCancellationTokenSource.Token;

              var Loader := TThumbnailLoader.Create;
              try
                FCurrentTask := Loader.LoadThumbnailsAsync(
                  FImagePaths,
                  Token,
                  ThumbnailBatchProgress,
                  ThumbnailCompletion);
              finally
                Loader.Free;
              end;
            end
            else
              ThumbnailCompletion(False);
          end);
      except
        on E: Exception do
        begin
          LogWrite('ERRO: ' + E.ToString);
          ThumbnailCompletion(False);
        end;
      end;
    end);
end;

procedure TMainForm.ThumbnailBatchProgress(const Batch: TArray<TThumbnailResult>);
var
  ResultItem: TThumbnailResult;
begin
  if csDestroying in ComponentState then
  begin
    for ResultItem in Batch do
      ResultItem.Bitmap.Free;
    Exit;
  end;

  if ImageList.Source.Count = 0 then
  begin
    SetControlsState(True, False);
  end;

  ImageListView.Items.BeginUpdate;
  try
    for ResultItem in Batch do
    begin
      if (ResultItem.Index >= 0) and
         (ResultItem.Index < ImageListView.Items.Count) then
      begin
        var Item := ImageListView.Items[ResultItem.Index];
        Item.ImageIndex := LoadBitmap(ImageList, ResultItem.Bitmap);
      end;
      ResultItem.Bitmap.Free;
    end;
  finally
    ImageListView.Items.EndUpdate;
  end;

  ProgressBar.Value := ProgressBar.Value + Length(Batch);
end;

procedure TMainForm.ThumbnailCompletion(const Cancelled: Boolean);
begin
  if csDestroying in ComponentState then
    Exit;

  if not Cancelled then
    LogWrite('%d Miniaturas criadas com sucesso.', [Length(FImagePaths)])
  else
    LogWrite('Criação de miniaturas cancelada.');
  LogMemo.GoToTextEnd;
  FCurrentTask := nil;
  SetControlsState(False, False);
end;

function TMainForm.LoadBitmap(ImageList: TImageList;
  const Bitmap: TBitmap): Integer;
var
  BitmapItem: TCustomBitmapItem;
  DestinationItem: TCustomDestinationItem;
  Layer: TLayer;
  SourceCollection: TCustomSourceItem;
begin
  Result := -1;
  if not Assigned(Bitmap) or (Bitmap.Width = 0) or (Bitmap.Height = 0) then
    Exit;

  SourceCollection := ImageList.Source.Add;
  SourceCollection.MultiResBitmap.SizeKind := TSizeKind.Source;
  SourceCollection.MultiResBitmap.Width := Bitmap.Width;
  SourceCollection.MultiResBitmap.Height := Bitmap.Height;
  BitmapItem := SourceCollection.MultiResBitmap.Add;
  BitmapItem.Bitmap.Assign(Bitmap);

  DestinationItem := ImageList.Destination.Add;
  Layer := DestinationItem.Layers.Add;
  Layer.SourceRect.Rect := TRectF.Create(
    TPoint.Zero,
    SourceCollection.MultiResBitmap.Width,
    SourceCollection.MultiResBitmap.Height);

  Layer.Name := SourceCollection.Name;
  Result := DestinationItem.Index;
end;

procedure TMainForm.SetControlsState(IsRunning, ShowAniIndicator: Boolean);
begin
  if csDestroying in ComponentState then Exit;
  LoadThumbnailsButton.Enabled := not IsRunning;
  LoadThumbnailsButton.Visible := LoadThumbnailsButton.Enabled;
  LoadThumbnailsButton.Align := TAlignLayout.Client;

  CancelButton.Enabled := IsRunning;
  CancelButton.Visible := CancelButton.Enabled;
  CancelButton.Align := TAlignLayout.Client;

  AniIndicator.Enabled := IsRunning and ShowAniIndicator;
  AniIndicator.Visible := IsRunning and ShowAniIndicator;
  ProgressBar.Visible := IsRunning;

  if not IsRunning then
  begin
    FCurrentTask := nil;
    if Assigned(FCancellationTokenSource) then
    begin
      FCancellationTokenSource.Free;
      FCancellationTokenSource := nil;
    end;
  end;
end;

end.

