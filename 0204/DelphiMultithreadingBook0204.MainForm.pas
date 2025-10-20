unit DelphiMultithreadingBook0204.MainForm;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  DelphiMultithreadingBook.Utils;

type
  TMainForm = class(TForm)
    IniciarAnonymousMethodButton: TButton;
    IniciarAnonymousThreadButton: TButton;
    PararAnonymousThreadButton: TButton;
    LogMemo: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure IniciarAnonymousMethodButtonClick(Sender: TObject);
    procedure IniciarAnonymousThreadButtonClick(Sender: TObject);
    procedure PararAnonymousThreadButtonClick(Sender: TObject);
  private
    FAnonymousThread: TThread;
    procedure AnonymousThreadTerminated(Sender: TObject);
    procedure SetButtonStates(RunningState: TRunningState);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.SysUtils,
  Vcl.Dialogs;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplicação iniciada.');
  SetButtonStates(IsStopped);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  if Assigned(FAnonymousThread) then
  begin
    // Desassocia o evento para evitar que ele dispare durante a destruição do form
    FAnonymousThread.OnTerminate := nil;
    // Apenas sinaliza para a thread terminar.
    FAnonymousThread.Terminate;
  end;
  UnregisterLogger;
end;

procedure TMainForm.IniciarAnonymousMethodButtonClick(Sender: TObject);
var
  // TProc é um tipo para procedimentos sem parâmetros
  MinhaAcao: TProc;
begin
  MinhaAcao := procedure
    begin
      ShowMessage('Olá do Método Anônimo!');
    end;

  // Executa o método anônimo
  MinhaAcao;
end;

procedure TMainForm.IniciarAnonymousThreadButtonClick(Sender: TObject);
var
  // Exemplo de variável local capturada
  Progresso: Integer;
begin
  LogWrite('> Iniciando Thread Anônima!');
  SetButtonStates(IsRunning);

  // Cria e inicia a thread anônima
  FAnonymousThread := TThread.CreateAnonymousThread(
    // Este é o Anonymous Method que será executado na thread
    procedure
    var
      i: Integer;
      FinalizadoPeloUsuario: Boolean;
    begin
      DebugLogWrite('Thread Anônima: Iniciando trabalho...');
      FinalizadoPeloUsuario := False;
      // Usamos um loop mais curto para fins de demonstração
      for i := 1 to 5 do
      begin
        if TThread.CheckTerminated then
        begin
          FinalizadoPeloUsuario := True;
          Break;
        end;

        // Atualiza uma variável local que será capturada pelo Anonymous Method
        Progresso := i;

        // Acessando a UI de forma segura via Queue
        TThread.Queue(nil,
          procedure
          begin
            LogWrite('Thread Anônima: Progresso %d de 5', [Progresso]);
          end);

        // Pausa de 1 segundo
        Sleep(1000);
      end;

      // Mensagem final, também via Queue
      TThread.Queue(nil,
        procedure
        begin
          if not FinalizadoPeloUsuario then
            LogWrite('Thread Anônima: Concluída!')
          else
            LogWrite('Thread Anônima: Terminada prematuramente!');
        end);

      DebugLogWrite('Thread Anônima: Fim do trabalho.');
    end);

    FAnonymousThread.OnTerminate := AnonymousThreadTerminated;

    // CreateAnonymousThread cria uma Thread Suspensa com
    // CreateSuspended = True, então temos que iniciar a thread com .Start
    FAnonymousThread.Start;
end;

procedure TMainForm.AnonymousThreadTerminated(Sender: TObject);
begin
  FAnonymousThread := nil;
  SetButtonStates(IsStopped);
end;

procedure TMainForm.PararAnonymousThreadButtonClick(Sender: TObject);
begin
  if Assigned(FAnonymousThread) then
  begin
    FAnonymousThread.Terminate;
  end;
end;

procedure TMainForm.SetButtonStates(RunningState: TRunningState);
begin
  IniciarAnonymousThreadButton.Enabled := RunningState = IsStopped;
  PararAnonymousThreadButton.Enabled := RunningState = IsRunning;
end;

end.
