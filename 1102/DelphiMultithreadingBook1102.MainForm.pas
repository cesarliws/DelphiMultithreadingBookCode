unit DelphiMultithreadingBook1102.MainForm;

interface

uses
  Data.DB, FireDAC.Comp.Client, FireDAC.Comp.DataSet, FireDAC.DApt.Intf,
  FireDAC.DatS, FireDAC.Phys, FireDAC.Phys.Intf, FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef, FireDAC.Phys.SQLiteWrapper.Stat, FireDAC.Stan.Async,
  FireDAC.Stan.Def, FireDAC.Stan.Error, FireDAC.Stan.ExprFuncs, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Pool, FireDAC.UI.Intf,
  FireDAC.VCLUI.Wait, System.Classes, System.SysUtils, Vcl.Controls, Vcl.DBGrids,
  Vcl.Forms, Vcl.Grids, Vcl.StdCtrls,
  DelphiMultithreadingBook.CancellationToken,
  DelphiMultithreadingBook.Utils;

type
  TMainForm = class(TForm)
    FDConnectionTemplate: TFDConnection;
    FDMemTableUI: TFDMemTable;
    DataSourceUI: TDataSource;
    DBGridUI: TDBGrid;
    LoadDataButton: TButton;
    CancelButton: TButton;
    LogMemo: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure LoadDataButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
  private
    FCancellationTokenSource: TCancellationTokenSource;
    procedure OnDataReady(const DataStream: TStream);
    procedure OnDataError(const E: Exception);
    procedure SetButtonStates(RunningState: TRunningState);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  DelphiMultithreadingBook1102.DBWorkerThread;

procedure TMainForm.CancelButtonClick(Sender: TObject);
begin
  if Assigned(FCancellationTokenSource) then
    FCancellationTokenSource.Cancel;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  SetButtonStates(IsStopped);
  FDConnectionTemplate.ConnectionDefName := 'SQLite_Demo';
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  if Assigned(FCancellationTokenSource) then
    FCancellationTokenSource.Cancel;
  FCancellationTokenSource.Free;
  UnregisterLogger;
end;

procedure TMainForm.LoadDataButtonClick(Sender: TObject);
begin
  LogWrite('> Solicitando dados do banco de dados em segundo plano...');
  SetButtonStates(IsRunning);
  FDMemTableUI.Close;

  // Cria uma nova fonte de cancelamento para esta operação
  FCancellationTokenSource.Free;
  FCancellationTokenSource := TCancellationTokenSource.Create;

  // Cria e dispara a thread, passando os callbacks
  TDBWorkerThread.Create(FDConnectionTemplate.Params,
    'SELECT * FROM Customers', FCancellationTokenSource.Token,
    OnDataReady, OnDataError);
end;

procedure TMainForm.OnDataError(const E: Exception);
begin
  if E is EOperationCancelled then
    LogWrite('Operação cancelada pelo usuário.')
  else
    LogWrite('ERRO: ' + E.Message);

  SetButtonStates(IsStopped);
end;

procedure TMainForm.OnDataReady(const DataStream: TStream);
begin
  try
    LogWrite('Dados recebidos. Atualizando a grid...');
    FDMemTableUI.LoadFromStream(DataStream, TFDStorageFormat.sfBinary);
    LogWrite('Grid atualizada!');
  finally
    SetButtonStates(IsStopped);
  end;
end;

procedure TMainForm.SetButtonStates(RunningState: TRunningState);
begin
  LoadDataButton.Enabled := RunningState = IsStopped;
  CancelButton.Enabled := RunningState = IsRunning;
end;

end.
