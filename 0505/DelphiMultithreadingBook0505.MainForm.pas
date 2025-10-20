unit DelphiMultithreadingBook0505.MainForm;

interface

uses
  System.Classes, System.Messaging, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  DelphiMultithreadingBook0505.WorkerThread;

type
  TMainForm = class(TForm)
    LogMemo: TMemo;
    StartThreadButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure StartThreadButtonClick(Sender: TObject);
  private
    FWorkerThread: TWorkerThread;
    // Método handler para receber mensagens de progresso
    procedure HandleProgressMessage(const Sender: TObject; const M: TMessage);
    procedure FinalizeWorkerThread;
    procedure WorkerThreadTerminated(Sender: TObject);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.SysUtils,
  DelphiMultithreadingBook.Utils;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplicação iniciada. Inscrevendo no TMessageManager...');

  // Assina o TMessageManager para receber mensagens do tipo TProgressMessage
  // A subscribe pode ocorrer aqui no FormCreate (Main Thread)
  TMessageManager.DefaultManager.SubscribeToMessage(TProgressMessage,
    HandleProgressMessage);

  LogWrite('Inscrito no TMessageManager para mensagens de progresso.');
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  // É importante se desinscrever das mensagens ao destruir o formulário
  TMessageManager.DefaultManager.Unsubscribe(TProgressMessage,
    HandleProgressMessage);
  FinalizeWorkerThread;
  UnregisterLogger;
end;

procedure TMainForm.StartThreadButtonClick(Sender: TObject);
begin
  // Garante que qualquer execução anterior seja finalizada
  FinalizeWorkerThread;

  LogWrite('> Iniciando Worker Thread para publicar mensagens...');
  FWorkerThread := TWorkerThread.Create;
  FWorkerThread.OnTerminate := WorkerThreadTerminated;
  FWorkerThread.Start;
  StartThreadButton.Enabled := False;
end;

procedure TMainForm.HandleProgressMessage(const Sender: TObject;
  const M: TMessage);
var
  ProgressMsg: TProgressMessage;
begin
  // Este handler é executado na thread que se inscreveu
  // (neste caso, a Main Thread)
  if M is TProgressMessage then
  begin
    ProgressMsg := M as TProgressMessage;
    LogWrite('Mensagem recebida: %s', [ProgressMsg.MessageText]);
    // Podemos atualizar a UI diretamente aqui porque este handler
    // é chamado na Main Thread
  end;
end;

procedure TMainForm.WorkerThreadTerminated(Sender: TObject);
begin
  LogWrite('Worker Thread finalizou.');
  StartThreadButton.Enabled := True;
end;

procedure TMainForm.FinalizeWorkerThread;
begin
  if Assigned(FWorkerThread) then
  begin
    FWorkerThread.Terminate;
    FWorkerThread.WaitFor;
    FWorkerThread.Free;
    FWorkerThread := nil;
  end;
end;

end.
