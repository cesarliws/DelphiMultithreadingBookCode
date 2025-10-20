unit DelphiMultithreadingBook0201.WorkerThread;

interface

uses
  System.Classes,
  Vcl.ComCtrls; // TProgressBar

type
  TWorkerThread = class(TThread)
  private
    // Refer�ncia ao ProgressBar na UI
    FProgressBar: TProgressBar;
  protected
    procedure Execute; override;
  public
    // O uso da refer�ncia de componentes VCL em Threads n�o � recomendado,
    // neste exemplo � usado para simplificar os outros conceitos apresentados.
    // � recomentado o uso de m�todos de "Callback" para notificar a Main Thread
    // (Interface de Usu�rio) de atualiza��es a partir das Threads.
    constructor Create(ProgressBar: TProgressBar);
  end;

implementation

uses
  System.SysUtils; // Sleep

{ TWorkerThread }

constructor TWorkerThread.Create(ProgressBar: TProgressBar);
begin
  // Cria suspensa
  inherited Create(True);
  FProgressBar := ProgressBar;
  // Gerenciamento manual da libera��o
  FreeOnTerminate := False;
end;

procedure TWorkerThread.Execute;
var
  i: Integer;
begin
  for i := 0 to 100 do
  begin
    // Verifica se a thread foi solicitada para terminar
    if Terminated then
    begin
      // Opcional: Sincronizar uma �ltima atualiza��o para indicar interrup��o
      TThread.Synchronize(nil,
        procedure
        begin
          // Reseta a barra de progresso
          FProgressBar.Position := 0;
          // Poderia adicionar mensagem no Log
        end);
      // Sai do loop
      Break;
    end;

    // Simula um trabalho demorado
    Sleep(100);

    // Atualiza o progresso na UI de forma segura
    // Usamos Queue aqui para n�o bloquear a thread de trabalho
    TThread.Queue(nil,
      procedure
      begin
        FProgressBar.Position := i;
      end);
  end;

  // Sincroniza uma mensagem final na UI quando o trabalho termina
  if not Terminated then
  begin
    TThread.Synchronize(nil,
      procedure
      begin
        FProgressBar.Position := 100;
        // Poderia adicionar mensagem de "Conclu�do!" no Log
      end);
  end;
end;

end.
