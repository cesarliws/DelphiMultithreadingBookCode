unit DelphiMultithreadingBook0304.MainForm;

interface

uses
  System.Classes,  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TMainForm = class(TForm)
    IniciarThreadsComSemaphoreButton: TButton;
    LogMemo: TMemo;
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure IniciarThreadsComSemaphoreButtonClick(Sender: TObject);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  DelphiMultithreadingBook0304.SharedData,   // WorkerSemaphore
  DelphiMultithreadingBook0304.WorkerThread, // TWorkerThread
  DelphiMultithreadingBook.Utils;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplica��o iniciada. Clique nos bot�es para iniciar as threads.');
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  UnregisterLogger;
end;

procedure TMainForm.IniciarThreadsComSemaphoreButtonClick(Sender: TObject);
var
  i: Integer;
begin
  LogWrite('> Iniciando 10 Threads com Sem�foro (limite 3 simult�neas)...');

  // Cria 10 threads, todas tentar�o adquirir uma permiss�o do sem�foro
  for i := 1 to 10 do
  begin
    // Cria thread worker
    TWorkerThread.Create(i, LogWrite);
  end;

  LogWrite('Verifique a janela de Mensagens do Delphi os efeitos do Sem�foro.');
  LogWrite('Apenas 3 threads devem processar simultaneamente.');
end;

end.
