unit DelphiMultithreadingBook0907.ThumbnailLoader;

interface

uses
  FMX.Graphics,
  System.Classes,
  System.Generics.Collections,
  System.Threading,
  System.Types,
  DelphiMultithreadingBook.CancellationToken;

type
  TThumbnailResult = record
    Index: Integer;
    Bitmap: TBitmap;
  end;

  TThumbnailBatchProgressCallback = reference to procedure(
    const Batch: TArray<TThumbnailResult>);
  TThumbnailCompletionCallback = reference to procedure(const Cancelled: Boolean);

  TThumbnailLoader = class
  public
    function LoadThumbnailsAsync(const FilePaths: TStringDynArray;
      const Token: ICancellationToken; OnProgress: TThumbnailBatchProgressCallback;
      OnComplete: TThumbnailCompletionCallback): ITask;
  end;

implementation

uses
  System.SysUtils,
  DelphiMultithreadingBook.Utils;

const
  THUMBNAIL_SIZE = 150;
  BATCH_SIZE = 10; // Enviar um lote a cada 25 imagens

{ TThumbnailLoader }

function TThumbnailLoader.LoadThumbnailsAsync(
  const FilePaths: TStringDynArray; const Token: ICancellationToken;
  OnProgress: TThumbnailBatchProgressCallback;
  OnComplete: TThumbnailCompletionCallback): ITask;
begin
  Result := TTask.Run(
    procedure
    var
      BatchBuffer: TList<TThumbnailResult>;
      i: Integer;
    begin
      BatchBuffer := TList<TThumbnailResult>.Create;
      try
        // Loop sequencial simples para máxima estabilidade
        for i := Low(FilePaths) to High(FilePaths) do
        begin
          Token.ThrowIfCancellationRequested;

          var OriginalBitmap := TBitmap.Create;
          var Thumbnail: TBitmap;
          try
            OriginalBitmap.LoadFromFile(FilePaths[i]);
            Thumbnail := OriginalBitmap.CreateThumbnail(THUMBNAIL_SIZE, THUMBNAIL_SIZE);
          finally
            OriginalBitmap.Free;
          end;

          var ResultItem: TThumbnailResult;
          ResultItem.Index := i;
          ResultItem.Bitmap := Thumbnail;
          BatchBuffer.Add(ResultItem);

          // Se o buffer atingiu o tamanho do lote, ou se esta é a última imagem
          if (BatchBuffer.Count >= BATCH_SIZE) or (i = High(FilePaths)) then
          begin
            var BatchToSend := BatchBuffer.ToArray;
            BatchBuffer.Clear;
            TThread.Queue(nil,
              procedure
              begin
                if Assigned(OnProgress) then
                  OnProgress(BatchToSend);
                SetLength(BatchToSend, 0);
              end);
            // Cede tempo de CPU para manter a UI 100% fluida
            Sleep(5);
          end;
        end;

        // Notifica a conclusão
        TThread.Queue(nil,
          procedure
          begin
            if Assigned(OnComplete) then
              OnComplete(False);
            BatchBuffer.Free;
          end);
      except
        on E: Exception do
        begin
          var IsCancelled := E is EOperationCancelled;
          TThread.Queue(nil,
            procedure
            begin
              if Assigned(OnComplete) then
                OnComplete(IsCancelled);
              LogWrite('Destruindo BatchBuffer (Exception)(3)');
              BatchBuffer.Free;
            end);
        end;
      end;
    end);
end;

end.
