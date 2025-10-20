unit DelphiMultithreadingBook0308.MainForm;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  DelphiMultithreadingBook0308.Worker;

type
  TMainForm = class(TForm)
    StartButton: TButton;
    CancelButton: TButton;
    LogMemo: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure StartButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
  private
    FOrchestrator: TThread;
    FWorker: TWorkerWithCancel;
    procedure FinalizeThreads;
    procedure OrchestratorTerminated(Sender: TObject);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.SysUtils,
  Winapi.Windows,
  DelphiMultithreadingBook.Utils;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FinalizeThreads;
  UnregisterLogger;
end;

procedure TMainForm.StartButtonClick(Sender: TObject);
begin
  if Assigned(FOrchestrator) then
  begin
    LogWrite('Teste j� em andamento.');
    Exit;
  end;

  LogMemo.Lines.Clear;
  LogWrite('> Iniciando Worker e Orquestrador...');
  StartButton.Enabled := False;
  CancelButton.Enabled := True;

  FWorker := TWorkerWithCancel.Create;
  FWorker.Start;

  // Cria uma thread an�nima para orquestrar, para n�o bloquear a UI
  FOrchestrator := TThread.CreateAnonymousThread(
    procedure
    var
      Handles: array[0..1] of THandle;
      WaitResult: DWORD;
    begin
      // Garante que a refer�ncia ao worker seja v�lida ao iniciar
      if not Assigned(FWorker) then
        Exit;

      // �ndice 0: T�rmino da thread de trabalho (Handle da thread)
      Handles[0] := FWorker.Handle;
      // �ndice 1: Evento de cancelamento
      Handles[1] := FWorker.CancelEvent.Handle;

      // Espera por QUALQUER um dos dois handles ser sinalizado
      WaitResult := WaitForMultipleObjects(2, @Handles, False, INFINITE);

      // Reporta o resultado para a UI de forma segura
      TThread.Queue(nil, procedure
        begin
          // Apenas processa o resultado se o form ainda existir
          if not (csDestroying in ComponentState) then
          begin
            case WaitResult of
              WAIT_OBJECT_0 + 0:
                LogWrite('Orquestrador: Worker terminou por conta pr�pria.');
              WAIT_OBJECT_0 + 1:
                LogWrite('Orquestrador: Sinal de cancelamento recebido!');
            else
              LogWrite('Orquestrador: Erro na espera.');
            end;
            // Limpeza
            FinalizeThreads;
          end;
        end);
    end);

  // ATRIBUI��O FUNDAMENTAL: Diz ao orquestrador para chamar
  // OrchestratorTerminated antes de se auto-destruir.
  FOrchestrator.OnTerminate := OrchestratorTerminated;

  // Inicia a thread orquestradora, que tem FreeOnTerminate = True por padr�o
  FOrchestrator.Start;
end;

procedure TMainForm.CancelButtonClick(Sender: TObject);
begin
  if Assigned(FWorker) then
  begin
    LogWrite('Disparando evento de cancelamento...');
    FWorker.CancelEvent.SetEvent;
    CancelButton.Enabled := False;
  end;
end;

procedure TMainForm.OrchestratorTerminated(Sender: TObject);
begin
  // A thread orquestradora terminou e est� prestes a ser liberada.
  // Esta � a �nica hora segura para limpar a nossa refer�ncia a ela.
  FOrchestrator := nil;
end;

procedure TMainForm.FinalizeThreads;
begin
  // Se o form for fechado, e a thread ainda existir, pedimos para ela terminar.
  // Se ela j� terminou, FOrchestrator ser� nil e nada acontecer�.
  if Assigned(FOrchestrator) then
  begin
    FOrchestrator.Terminate;
  end;

  if Assigned(FWorker) then
  begin
    FWorker.Terminate;
    FWorker.CancelEvent.SetEvent;
    FWorker.Free;
    FWorker := nil;
  end;

  if not (csDestroying in ComponentState) then
  begin
    StartButton.Enabled := True;
    CancelButton.Enabled := False;
  end;
end;

end.
