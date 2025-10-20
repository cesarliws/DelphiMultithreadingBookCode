unit DelphiMultithreadingBook0501.MessageWorkerThread;

interface

uses
  System.Classes,
  Winapi.Windows, // PostMessage, HWND
  Winapi.Messages; // WM_APP

type
  TMessageWorkerThread = class(TThread)
  private
    // Handle da janela para onde enviar mensagens
    FTargetWindowHandle: HWND;
    FMessageCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(TargetWindowHandle: HWND; MessageCount: Integer = 5);
  end;

  PMessageData = ^TMessageData;
  TMessageData = record
    TextMessage: string;
  end;

const
  // Mensagem personalizada para atualizar o Memo
  WM_UPDATE_MEMO = WM_APP + 1;
  // Mensagem para indicar tarefa concluída
  WM_TASK_DONE   = WM_APP + 2;

implementation

uses
  System.SysUtils, // Format
  DelphiMultithreadingBook.Utils;

{ TMessageWorkerThread }

constructor TMessageWorkerThread.Create(TargetWindowHandle: HWND;
  MessageCount: Integer = 5);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FTargetWindowHandle := TargetWindowHandle;
  FMessageCount := MessageCount
end;

procedure TMessageWorkerThread.Execute;
var
  i: Integer;
  MessageData: PMessageData;
begin
  DebugLogWrite('MessageWorkerThread: Iniciando trabalho...');

  for i := 1 to FMessageCount do
  begin
    if Terminated then
      Break;

    // Aloca um ponteiro para o record
    New(MessageData);
    // Define a mensagem de texto que será enviada
    MessageData^.TextMessage :=
      Format('Progresso da Thread de Mensagens: %d de %d', [i, FMessageCount]);

    // Envia a mensagem de forma assíncrona.
    // WParam contém o ponteiro para o MessageData.
    PostMessage(FTargetWindowHandle, WM_UPDATE_MEMO, WPARAM(MessageData), 0);

    // Simula trabalho
    Sleep(1000);
  end;

  // Sinaliza que a tarefa terminou
  PostMessage(FTargetWindowHandle, WM_TASK_DONE, 0, 0);

  DebugLogWrite('MessageWorkerThread: Trabalho concluído!');
end;

end.
