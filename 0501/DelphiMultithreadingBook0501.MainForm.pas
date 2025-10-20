unit DelphiMultithreadingBook0501.MainForm;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Winapi.Messages,
  DelphiMultithreadingBook0501.MessageWorkerThread;

type
  TMainForm = class(TForm)
    IniciarMessageThreadButton: TButton;
    LogMemo: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure IniciarMessageThreadButtonClick(Sender: TObject);
  private
    FMessageWorkerThread: TMessageWorkerThread;
    // M�todos para receber e tratar as mensagens personalizadas
    procedure HandleTaskDoneMessage(var Msg: TMessage); message WM_TASK_DONE;
    procedure HandleUpdateMemoMessage(var Msg: TMessage); message WM_UPDATE_MEMO;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  DelphiMultithreadingBook.Utils;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplica��o iniciada.');
  LogWrite('Clique em "Iniciar Thread (PostMessage)".');
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  // Garante que a thread seja terminada e liberada ao fechar o formul�rio
  if Assigned(FMessageWorkerThread) then
  begin
    // Sinaliza para a thread terminar, se ela verificar Terminated
    FMessageWorkerThread.Terminate;
    // Aguarda a thread finalizar sua execu��o
    FMessageWorkerThread.WaitFor;
    // Libera o objeto thread (FreeOnTerminate = False)
    FMessageWorkerThread.Free;
  end;
  UnregisterLogger;
end;

procedure TMainForm.HandleTaskDoneMessage(var Msg: TMessage);
begin
  // Garante que a thread ainda existe antes de interagir com ela
  if not Assigned(FMessageWorkerThread) then
    Exit;

  // Mensagem recebida na Main Thread
  LogWrite('Tarefa da thread conclu�da via PostMessage!');

  FMessageWorkerThread.WaitFor;
  // Opcional: Libera a thread se ela n�o for mais necess�ria
  FMessageWorkerThread.Free;
  FMessageWorkerThread := nil;
  IniciarMessageThreadButton.Enabled := True;
end;

procedure TMainForm.HandleUpdateMemoMessage(var Msg: TMessage);
var
  MessageData: PMessageData;
begin
  // 1. Recebe o ponteiro bruto do par�metro WParam da mensagem.
  // 2. Faz um typecast para PMessageData para que o Delphi entenda a estrutura.
  MessageData := PMessageData(Msg.WParam);
  try
    // 3. Acessa os dados de forma segura.
    LogWrite(MessageData^.TextMessage);
  finally
    // 4. Libera a mem�ria do record que foi alocado na thread de trabalho.
    Dispose(MessageData);
  end;
end;

procedure TMainForm.IniciarMessageThreadButtonClick(Sender: TObject);
begin
  if not Assigned(FMessageWorkerThread) then
  begin
    LogWrite('> Iniciando Thread com PostMessage...');
    // Cria a worker thread e passa o Handle do Form para envio de mensagens
    FMessageWorkerThread := TMessageWorkerThread.Create(Handle);
    // Desabilita o bot�o para evitar m�ltiplas inst�ncias
    IniciarMessageThreadButton.Enabled := False;
  end
  else
  begin
    LogWrite('Thread de Mensagens j� est� em execu��o.');
  end;
end;

end.
