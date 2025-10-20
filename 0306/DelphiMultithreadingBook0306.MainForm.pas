unit DelphiMultithreadingBook0306.MainForm;

interface

uses
  System.Classes, System.UITypes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  DelphiMultithreadingBook0306.Workers,
  DelphiMultithreadingBook.Utils;

type
  TMainForm = class(TForm)
    IniciarCriticalSectionButton: TButton;
    IniciarMREWButton: TButton;
    LogMemo: TMemo;
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure IniciarCriticalSectionButtonClick(Sender: TObject);
    procedure IniciarMREWButtonClick(Sender: TObject);
  private
    procedure RunTest(LockType: TLockType);
    procedure SetButtonsState(RunningState: TRunningState);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.Diagnostics,
  System.SyncObjs,
  System.SysUtils;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplicação Iniciada.');
  LogWrite('Execute os Testes algumas vezes para comparar os Resultados.');
  LogMemo.ScrollBars := ssVertical;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  UnregisterLogger;
end;

procedure TMainForm.RunTest(LockType: TLockType);
const
  READER_COUNT = 8;
  START_MESSAGE = '> Iniciando teste com %s (%d threads)...';
var
  ConfigList: TStringList;
  CriticalSection: TCriticalSection;
  MREW: TLightweightMREW;
  Stopwatch: TStopwatch;
  Countdown: TCountdownEvent;
  i: Integer;
begin
  if LockType = TLockType.MultiReadExclusiveWrite then
    LogWrite(START_MESSAGE, ['TLightweightMREW', READER_COUNT])
  else
    LogWrite(START_MESSAGE, ['TCriticalSection', READER_COUNT]);

  SetButtonsState(IsRunning);
  ConfigList := TStringList.Create;
  CriticalSection := TCriticalSection.Create;
  Countdown := TCountdownEvent.Create(READER_COUNT);
  Stopwatch := TStopwatch.StartNew;

  // Dispara as threads leitoras
  for i := 1 to READER_COUNT do
    TReaderThread.Create(LockType, ConfigList, CriticalSection, MREW,
      procedure(const Msg: string)
      begin
        LogWrite(Msg);
        // Este callback é chamado quando cada thread termina
        Countdown.Signal;
      end);

  // Thread orquestradora para aguardar o fim sem bloquear a UI
  TThread.CreateAnonymousThread(procedure
    begin
      // Espera todas as 8 threads sinalizarem
      Countdown.WaitFor;
      Stopwatch.Stop;
      TThread.Queue(nil,
        procedure
        begin
          LogWrite('------------------------------------');
          LogWrite(Format('Teste concluído em: %d ms', [Stopwatch.ElapsedMilliseconds]));
          ConfigList.Free;
          CriticalSection.Free;
          Countdown.Free;
          SetButtonsState(IsStopped);
        end);
    end
  ).Start;
end;


procedure TMainForm.IniciarCriticalSectionButtonClick(Sender: TObject);
begin
  RunTest(TLockType.CriticalSection);
end;

procedure TMainForm.IniciarMREWButtonClick(Sender: TObject);
begin
  RunTest(TLockType.MultiReadExclusiveWrite);
end;

procedure TMainForm.SetButtonsState(RunningState: TRunningState);
begin
  if csDestroying in ComponentState then
    Exit;
  IniciarCriticalSectionButton.Enabled := RunningState = IsStopped;
  IniciarMREWButton.Enabled := RunningState = IsStopped;
end;

end.
