unit DelphiMultithreadingBook0504.MainThreadDispatcher;

interface

uses
  System.Classes,
  System.SysUtils, // TProc
  Winapi.Messages,
  Winapi.Windows;

type
  TMainThreadDispatcher = class(TComponent)
  private
    // Mensagem customizada
    const WM_RUN_POSTED = WM_APP + 1;
    // Inst�ncia do Singleton
    class var FInstance: TMainThreadDispatcher;
    class function GetInstance: TMainThreadDispatcher; static;
  private
    // Handle da janela oculta
    FWindowHandle: HWND;

    // Este WndProc recebe todas as mensagens.
    procedure WndProc(var Msg: TMessage);

    // M�todo handler espec�fico para WM_RUN_POSTED
    procedure WMRunPosted(var Msg: TMessage);
  protected
    procedure Initialize; virtual;
    procedure Finalize; virtual;
  public
    constructor Create(Owner: TComponent); override;
    destructor Destroy; override;

    // M�todo para postar o TProc na fila de mensagens da main thread
    class procedure Post(Proc: TProc);
    // Propriedade para acessar a inst�ncia �nica do dispatcher
    class property Instance: TMainThreadDispatcher read GetInstance;
  end;

implementation

type
  // Ponteiro para TProc para passar via WParam
  PProc = ^TProc;

{ TMainThreadDispatcher }

constructor TMainThreadDispatcher.Create(Owner: TComponent);
begin
  inherited;
  // Inicializa o handle da janela
  Initialize;
end;

destructor TMainThreadDispatcher.Destroy;
begin
  // Desaloca o handle da janela
  Finalize;
  inherited;
end;

procedure TMainThreadDispatcher.Initialize;
begin
  // Cria a janela oculta
  FWindowHandle := AllocateHWnd(WndProc);
end;

procedure TMainThreadDispatcher.Finalize;
begin
  if FWindowHandle <> 0 then
    // Desaloca o handle da janela
    DeallocateHWnd(FWindowHandle);
  // Limpa o handle
  FWindowHandle := 0;
end;

procedure TMainThreadDispatcher.WndProc(var Msg: TMessage);
begin
  if Msg.Msg = WM_RUN_POSTED then
    // Delega o tratamento da mensagem espec�fica para um m�todo dedicado
    WMRunPosted(Msg)
  else
    // Passa as outras mensagens para o WndProc padr�o do sistema
    Msg.Result := DefWindowProc(FWindowHandle, Msg.Msg, Msg.WParam, Msg.LParam);
end;

procedure TMainThreadDispatcher.WMRunPosted(var Msg: TMessage);
var
  ProcData: PProc;
  Proc: TProc;
begin
  // Recupera o ponteiro para o TProc
  ProcData := PProc(Msg.WParam);
  // Usar try..finally para garantir a libera��o do ProcData
  try
    if Assigned(ProcData^) then
    begin
      // Desreferencia para obter o TProc
      Proc := ProcData^;
      // Executa o m�todo an�nimo
      Proc();
    end;
  finally
    // Garante que a mem�ria alocada para o ponteiro do TProc seja sempre liberada
    Dispose(ProcData);
  end;
end;

class function TMainThreadDispatcher.GetInstance: TMainThreadDispatcher;
begin
  // Cria a inst�ncia se n�o existir
  if not Assigned(FInstance) then
    FInstance := TMainThreadDispatcher.Create(nil);
  Result := FInstance;
end;

class procedure TMainThreadDispatcher.Post(Proc: TProc);
var
  ProcData: PProc;
begin
  // Aloca mem�ria para o ponteiro do TProc e armazena o m�todo
  New(ProcData);
  ProcData^ := Proc;
  // Posta a mensagem para a janela oculta, passando o ponteiro via WPARAM
  PostMessage(GetInstance.FWindowHandle, WM_RUN_POSTED, WParam(ProcData), 0);
end;

initialization
  TMainThreadDispatcher.FInstance := nil;

finalization
  // Garante que a inst�ncia singleton seja liberada no encerramento da aplica��o
  if Assigned(TMainThreadDispatcher.FInstance) then
    TMainThreadDispatcher.FInstance.Free;

end.
