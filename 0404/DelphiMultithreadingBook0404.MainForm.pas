unit DelphiMultithreadingBook0404.MainForm;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls,
  DelphiMultithreadingBook.Utils;

type
  TMainForm = class(TForm)
    IniciarThreadButton: TButton;
    LogMemo: TMemo;
    TestTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure IniciarThreadButtonClick(Sender: TObject);
    procedure TestTimerTimer(Sender: TObject);
  private
    FThreadTimeCritical: TThread;
    FThreadIdle: TThread;
    procedure FinalizeThreads;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.SysUtils,
  DelphiMultithreadingBook0404.PriorityWorker;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplicação iniciada.');
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FinalizeThreads;
  UnregisterLogger;
end;

procedure TMainForm.FinalizeThreads;
begin
  TestTimer.Enabled := False;
  if Assigned(FThreadTimeCritical) then
  begin
    FThreadTimeCritical.Terminate;
    FThreadTimeCritical := nil;
  end;

  if Assigned(FThreadIdle) then
  begin
    FThreadIdle.Terminate;
    FThreadIdle := nil;
  end;
end;

procedure TMainForm.IniciarThreadButtonClick(Sender: TObject);
begin
  FinalizeThreads;
  LogMemo.Lines.Clear;
  LogWrite('> Iniciando threads com prioridades TIME CRITICAL e IDLE...');
  IniciarThreadButton.Enabled := False;

  // Cria as duas threads com prioridades opostas
  FThreadTimeCritical := TPriorityWorker.Create('Thread TIME CRITICAL',
    tpTimeCritical);
  FThreadIdle := TPriorityWorker.Create('Thread IDLE', tpIdle);

  // Usa um TTimer para finalizar o teste após 5 segundos
  TestTimer.Enabled := True;
  LogWrite('Threads TIME CRITICAL e IDLE iniciadas, aguarde...');
end;

procedure TMainForm.TestTimerTimer(Sender: TObject);
begin
  // Dispara apenas uma vez
  TestTimer.Enabled := False;
  LogWrite('--- Fim do Teste ---');
  FinalizeThreads;
  IniciarThreadButton.Enabled := True;
end;

end.
