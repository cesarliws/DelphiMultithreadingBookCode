unit DelphiMultithreadingBook0806.MainForm;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls;

type
  TMainForm = class(TForm)
    IniciarCodeSiteThreadButton: TButton;
    LogMemo: TMemo;
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure IniciarCodeSiteThreadButtonClick(Sender: TObject);
  private
    procedure WorkerThreadTerminate(Sender: TObject);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  DelphiMultithreadingBook0806.LoggingThread,
  DelphiMultithreadingBook.Utils;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplicação iniciada.');
  LogWrite('Inicie o CodeSite Live Viewer no menu:');
  LogWrite('> Tools > CodeSite > CodeSite Live Viewer.');
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  UnregisterLogger;
end;

procedure TMainForm.IniciarCodeSiteThreadButtonClick(Sender: TObject);
var
  WorkerThread: TLoggingThread;
begin
  LogWrite('> Iniciando 3 Threads com CodeSite Logging...');

  // Cria e inicia 3 threads, associando o handler a cada uma.
  // Como FreeOnTerminate é True, elas se auto liberarão.
  WorkerThread := TLoggingThread.Create;
  WorkerThread.OnTerminate := WorkerThreadTerminate;
  WorkerThread.Start;

  WorkerThread := TLoggingThread.Create;
  WorkerThread.OnTerminate := WorkerThreadTerminate;
  WorkerThread.Start;

  WorkerThread := TLoggingThread.Create;
  WorkerThread.OnTerminate := WorkerThreadTerminate;
  WorkerThread.Start;
end;

procedure TMainForm.WorkerThreadTerminate(Sender: TObject);
begin
  // Este evento é executado na thread principal (UI Thread)
  TThread.Queue(nil,
    procedure
    begin
      LogWrite('Thread %d finalizada. Verifique o CodeSite Viewer.',
        [TThread(Sender).ThreadID]);
    end
  );
end;

end.
