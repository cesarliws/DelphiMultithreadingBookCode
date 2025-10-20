unit DelphiMultithreadingBook1001.LogFileProcessor;

interface

uses
  System.Classes,
  System.Threading;

type
  TLogProgressCallback = reference to procedure(const ProcessedCount,
    TotalCount: Integer; const FileName: string);

  TLogCompletionCallback = reference to procedure(const Cancelled: Boolean;
    const TotalFiles, TotalLines, TotalWords: Int64;
    const ErrorLines: TStrings);

  TLogFileProcessor = class
  private
    FProcessorTask: ITask;
  public
    procedure ProcessLogsAsync(const DirectoryPath: string;
      OnProgress: TLogProgressCallback; OnComplete: TLogCompletionCallback);
    procedure Cancel;
  end;

implementation

uses
  System.Diagnostics,
  System.IOUtils,
  System.SyncObjs,
  System.SysUtils,
  System.Types;

{ TLogFileProcessor }

procedure TLogFileProcessor.Cancel;
begin
  if Assigned(FProcessorTask) then
    FProcessorTask.Cancel;
end;

procedure TLogFileProcessor.ProcessLogsAsync(const DirectoryPath: string;
  OnProgress: TLogProgressCallback; OnComplete: TLogCompletionCallback);
begin
  FProcessorTask := TTask.Run(
    procedure
    var
      ErrorLines: TStringList;
      ErrorLock: TCriticalSection;
      Files: TStringDynArray;
      TotalLines, TotalWords: Int64;
      ProcessedCount: Integer;
      LoopResult: TParallel.TLoopResult;
    begin
      ErrorLines := nil;
      ErrorLock := nil;
      try
        TotalLines := 0;
        TotalWords := 0;
        ProcessedCount := 0;
        ErrorLines := TStringList.Create;
        ErrorLock := TCriticalSection.Create;

        Files := TDirectory.GetFiles(DirectoryPath, '*.txt');

        if Length(Files) = 0 then
        begin
          TThread.Queue(nil, procedure
            begin
              if Assigned(OnComplete) then
                OnComplete(False, 0, 0, 0, ErrorLines);
            end);
          // O finally abaixo cuidará da limpeza
          Exit;
        end;

        LoopResult := TParallel.For(Low(Files), High(Files),
          procedure(i: Integer; LoopState: TParallel.TLoopState)
          var
            FileContent, Line: string;
            LineCount, WordCount: Integer;
            LocalErrorLines: TStringList;
          begin
            if Self.FProcessorTask.Status = TTaskStatus.Canceled then
            begin
              LoopState.Stop;
              Exit;
            end;

            FileContent := TFile.ReadAllText(Files[i]);
            LineCount := 0;
            WordCount := 0;
            LocalErrorLines := TStringList.Create;
            try
              for Line in FileContent.Split([sLineBreak]) do
              begin
                Inc(LineCount);
                WordCount := WordCount + Length(Line.Split([' ']));
                if Line.Contains('ERROR') then
                  LocalErrorLines.Add(Format('[%s] %s',
                    [TPath.GetFileName(Files[i]), Line]));
              end;

              TInterlocked.Add(TotalLines, LineCount);
              TInterlocked.Add(TotalWords, WordCount);

              if LocalErrorLines.Count > 0 then
              begin
                ErrorLock.Enter;
                try
                  ErrorLines.AddStrings(LocalErrorLines);
                finally
                  ErrorLock.Leave;
                end;
              end;

              TInterlocked.Increment(ProcessedCount);
              TThread.Queue(nil, procedure
                begin
                  if Assigned(OnProgress) then
                    OnProgress(ProcessedCount, Length(Files),
                      TPath.GetFileName(Files[i]));
                end);
            finally
              LocalErrorLines.Free;
            end;
          end);

        // -- Bloco de Conclusão --
        TThread.Queue(nil, procedure
          begin
            try
              // Chama o evento de conclusão passando os resultados
              if Assigned(OnComplete) then
                OnComplete(FProcessorTask.Status = TTaskStatus.Canceled,
                  Length(Files), TotalLines, TotalWords, ErrorLines);
            finally
              // Garante que os objetos sejam liberados APÓS o evento ser chamado
              ErrorLines.Free;
              ErrorLock.Free;
            end;
          end);

      except
        // Em caso de exceção (ex: TDirectory.GetFiles falha)
        on E: Exception do
        begin
          TThread.Queue(nil, procedure
            begin
              try
                // Garante que o ErrorLines não seja nil
                // se a exceção ocorreu antes de sua criação
                if not Assigned(ErrorLines) then
                  ErrorLines := TStringList.Create;

                ErrorLines.Insert(0, Format('ERRO CRÍTICO NA TASK: %s',
                  [E.Message]));

                if Assigned(OnComplete) then
                  // Sinaliza falha
                  OnComplete(True, 0, 0, 0, ErrorLines);
              finally
                // Garante a limpeza mesmo em caso de exceção
                if Assigned(ErrorLines) then ErrorLines.Free;
                if Assigned(ErrorLock) then ErrorLock.Free;
              end;
            end);
        end;
      end;
    end);
end;

end.
