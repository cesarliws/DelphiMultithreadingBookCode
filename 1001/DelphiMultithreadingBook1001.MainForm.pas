unit DelphiMultithreadingBook1001.MainForm;

interface

uses
  System.Classes, System.Threading,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ComCtrls,
  DelphiMultithreadingBook1001.LogFileProcessor,
  DelphiMultithreadingBook.Utils;

type
  TMainForm = class(TForm)
    GenerateLogFilesButton: TButton;
    ProcessFilesButton: TButton;
    CancelButton: TButton;
    ProgressBar: TProgressBar;
    LogMemo: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure GenerateLogFilesButtonClick(Sender: TObject);
    procedure ProcessFilesButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    FCurrentTask: ITask;
    FLogProcessor: TLogFileProcessor;
    FLogsDirectory: string;
    procedure LogProgress(const ProcessedCount, TotalCount: Integer;
      const FileName: string);
    procedure LogCompletion(const Cancelled: Boolean; const TotalFiles,
      TotalLines, TotalWords: Int64; const ErrorLines: TStrings);
    procedure SetButtonStates(RunningState: TRunningState);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.IOUtils,
  System.SysUtils;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  FLogsDirectory := TPath.Combine(TPath.GetTempPath, 'BookLogs');
  LogWrite('Diretório de logs de exemplo: ' + FLogsDirectory);
  LogWrite('Use o botão "Gerar Arquivos" para criar dados de teste.');
  SetButtonStates(IsStopped);
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not Assigned(FCurrentTask) and not Assigned(FLogProcessor);
  if not CanClose then
  begin
    LogWrite('* Aguarde o Processamento finalizar para fechar a Janela!');
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  if Assigned(FLogProcessor) then
   FLogProcessor.Cancel;

  if Assigned(FCurrentTask) then
    FCurrentTask.Cancel;

  UnregisterLogger;
end;

procedure TMainForm.GenerateLogFilesButtonClick(Sender: TObject);
const
  SERVER_ERROR =
    'Timestamp: %s - Level: ERROR - Details: Falha ao conectar no servidor X.';
  OPERATION_ERROR =
    'Timestamp: %s - Level: INFO - Details: Operação %d concluída.';
begin
  LogWrite('> Gerando 20 arquivos de log de exemplo...');
  SetButtonStates(IsRunning);
  FCurrentTask := TTask.Run(
    procedure
    var
      i, j: Integer;
      Line, LogsDirectory, TimeStamp: String;
      LogFile: TStringList;
    begin
      LogsDirectory := FLogsDirectory;
      if not TDirectory.Exists(LogsDirectory) then
        TDirectory.CreateDirectory(LogsDirectory);

      LogFile := TStringList.Create;
      try
        for i := 1 to 20 do
        begin
          LogFile.Clear;
          // 5000 linhas por arquivo
          for j := 1 to 5000 do
          begin
            TimeStamp := DateTimeToStr(Now);
            // 5% de chance de erro
            if Random(100) < 5 then
              Line := Format(SERVER_ERROR, [TimeStamp])
            else
              Line := Format(OPERATION_ERROR, [TimeStamp, j]);

            LogFile.Add(Line);
          end;

          LogFile.SaveToFile(TPath.Combine(LogsDirectory,
            Format('app_log_%d.txt', [i])));
        end;

        LogWrite('Arquivos de log gerados com sucesso!');
      finally
        LogFile.Free;
        FCurrentTask := nil;
        SetButtonStates(IsStopped);
      end;
    end);
end;

procedure TMainForm.ProcessFilesButtonClick(Sender: TObject);
begin
  if Assigned(FLogProcessor) then Exit;

  LogMemo.Lines.Clear;
  LogWrite('> Iniciando processamento paralelo dos arquivos de log...');
  SetButtonStates(IsRunning);
  ProgressBar.Position := 0;

  FLogProcessor := TLogFileProcessor.Create;
  FLogProcessor.ProcessLogsAsync(FLogsDirectory, LogProgress, LogCompletion);
end;

procedure TMainForm.CancelButtonClick(Sender: TObject);
begin
  if Assigned(FCurrentTask) then
    FCurrentTask.Cancel;

  if Assigned(FLogProcessor) then
    FLogProcessor.Cancel;
end;

procedure TMainForm.LogCompletion(const Cancelled: Boolean; const TotalFiles,
  TotalLines, TotalWords: Int64; const ErrorLines: TStrings);
begin
  try
    if csDestroying in ComponentState then Exit;

    if Cancelled then
    begin
      LogWrite('--- PROCESSAMENTO CANCELADO ---');
    end
    else
    begin
      LogWrite('--- RELATÓRIO FINAL ---');
      LogWrite(Format('Total de Arquivos Processados: %d', [TotalFiles]));
      LogWrite(Format('Total de Linhas Analisadas: %d', [TotalLines]));
      LogWrite(Format('Total de Palavras Contadas: %d', [TotalWords]));
      LogWrite(Format('Total de Erros Encontrados: %d', [ErrorLines.Count]));
      if ErrorLines.Count > 0 then
      begin
        LogWrite('');
        LogWrite('--- LINHAS COM ERRO ---');
        LogMemo.Lines.AddStrings(ErrorLines);
      end;
      LogWrite('-----------------------');
    end;
  finally
    if Assigned(FLogProcessor) then
    begin
      FLogProcessor.Free;
      FLogProcessor := nil;
    end;
    SetButtonStates(IsStopped);
  end;
end;

procedure TMainForm.LogProgress(const ProcessedCount, TotalCount: Integer;
  const FileName: string);
begin
  if (csDestroying in ComponentState) or (FLogProcessor = nil) then Exit;
  ProgressBar.Max := TotalCount;
  ProgressBar.Position := ProcessedCount;
end;

procedure TMainForm.SetButtonStates(RunningState: TRunningState);
begin
  TThread.ForceQueue(nil,
    procedure
    begin
      GenerateLogFilesButton.Enabled := RunningState = IsStopped;
      ProcessFilesButton.Enabled := RunningState = IsStopped;
      CancelButton.Enabled := RunningState = IsRunning;
    end);
end;

end.
