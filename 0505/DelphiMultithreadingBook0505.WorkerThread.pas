unit DelphiMultithreadingBook0505.WorkerThread;

interface

uses
  System.Classes,
  System.Messaging;

type
  // Define o tipo de mensagem que queremos enviar
  TProgressMessage = class(TMessage)
  public
    MessageText: string;
    Progress: Integer;
    constructor Create(Progress: Integer; const Msg: string);
  end;

  TWorkerThread = class(TThread)
  protected
    procedure Execute; override;
  public
    constructor Create;
  end;

implementation

uses
  System.SysUtils;

{ TProgressMessage }

constructor TProgressMessage.Create(Progress: Integer; const Msg: string);
begin
  inherited Create;
  Self.Progress := Progress;
  Self.MessageText := Msg;
end;

{ TWorkerThread }

constructor TWorkerThread.Create;
begin
  inherited Create(True);
  FreeOnTerminate := False;
end;

procedure TWorkerThread.Execute;
var
  i: Integer;
  ProgressMsg: TProgressMessage;
begin
  // Simula um trabalho em segundo plano
  for i := 1 to 10 do
  begin
    if Terminated then Break;

    // Cria a mensagem com os dados
    ProgressMsg := TProgressMessage.Create(i * 10,
      Format('Progresso: %d%% concluído', [i * 10]));

    // Publica a mensagem.
    // O TMessageManager irá rotear esta mensagem para os assinantes.
    TMessageManager.DefaultManager.SendMessage(Self, ProgressMsg);

    // O objeto ProgressMsg será liberado pela TMessageManager quando processado.
    // Simula trabalho
    Sleep(500);
  end;
end;

end.
