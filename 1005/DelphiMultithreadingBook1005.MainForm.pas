unit DelphiMultithreadingBook1005.MainForm;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  DelphiMultithreadingBook.Utils,
  DelphiMultithreadingBook1005.PipelineProcessor;

type
  TMainForm = class(TForm)
    StartPipelineButton: TButton;
    CancelButton: TButton;
    LogMemo: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure StartPipelineButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    FProcessor: TPipelineProcessor;
    procedure OnStateChange(const State: TPipelineState;
      const Message: string);
    procedure SetButtonStates(RunningState: TRunningState);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.SysUtils;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  SetButtonStates(IsStopped);
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not Assigned(FProcessor);
  if not CanClose then
  begin
    LogWrite('* Cancele a Pipeline para fechar esta Janela!')
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  UnregisterLogger;
  if Assigned(FProcessor) then
  begin
    FProcessor.Free;
  end;
end;

procedure TMainForm.StartPipelineButtonClick(Sender: TObject);
begin
  if Assigned(FProcessor) then
    Exit;

  LogMemo.Lines.Clear;
  LogWrite('> Iniciando pipeline com Máquina de Estado...');
  SetButtonStates(IsRunning);

  FProcessor := TPipelineProcessor.Create(OnStateChange);
  FProcessor.Run;
end;

procedure TMainForm.CancelButtonClick(Sender: TObject);
begin
  if Assigned(FProcessor) then
  begin
    FProcessor.Cancel;
  end;
end;

procedure TMainForm.OnStateChange(const State: TPipelineState;
  const Message: string);
begin
  if csDestroying in ComponentState then Exit;
  if not Message.IsEmpty then
    LogWrite(Message);

  case State of
    CompletedState, FailedState, CanceledState:
      begin
        SetButtonStates(IsStopped);
        FProcessor.Free;
        FProcessor := nil;
      end;
  end;
end;

procedure TMainForm.SetButtonStates(RunningState: TRunningState);
begin
  if csDestroying in ComponentState then Exit;
  StartPipelineButton.Enabled := RunningState = IsStopped;
  CancelButton.Enabled := RunningState = IsRunning;
end;

end.


