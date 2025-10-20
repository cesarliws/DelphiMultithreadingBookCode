unit DelphiMultithreadingBook0804.MainForm;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  DelphiMultithreadingBook0804.BankAccount,
  DelphiMultithreadingBook0804.BankTransferWorker,
  DelphiMultithreadingBook.Utils;

type
  TMainForm = class(TForm)
    LogMemo: TMemo;
    IniciarDeadlockExemploButton: TButton;
    IniciarDeadlockPrevencaoButton: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure IniciarDeadlockExemploButtonClick(Sender: TObject);
    procedure IniciarDeadlockPrevencaoButtonClick(Sender: TObject);
  private
    FBancoConta101: TBankAccount;
    FBancoConta102: TBankAccount;

    // Refer�ncias expl�citas para as duas threads de transfer�ncia
    FWorker1: TBankTransferWorker;
    FWorker2: TBankTransferWorker;
    // Contador para gerenciar threads em execu��o
    FRunningWorkers: Integer;

    // M�todo auxiliar para exibir saldos no LogMemo
    procedure DisplayBalances;
    // Handler de t�rmino para as threads de transfer�ncia
    procedure TransferWorkerFinished(Sender: TObject);
    // Controla o estado dos bot�es da UI
    procedure SetButtonStates(RunningState: TRunningState);
    // M�todo para finalizar e liberar os workers
    procedure FinalizeWorkers;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.SyncObjs; // Para TInterlocked

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplica��o iniciada.');

  FBancoConta101 := TBankAccount.Create(101, 1000);
  FBancoConta102 := TBankAccount.Create(102, 1000);

  DisplayBalances;
  SetButtonStates(IsStopped);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FinalizeWorkers;

  FBancoConta101.Free;
  FBancoConta102.Free;
  UnregisterLogger;
end;

procedure TMainForm.FinalizeWorkers;
begin
  // Garante que as threads sejam terminadas e liberadas de forma segura.
  // O padr�o idiom�tico � sinalizar (se aplic�vel), esperar e liberar.

  if Assigned(FWorker1) then
  begin
    // A chamada Terminate � um no-op neste worker espec�fico, pois seu Execute
    // n�o verifica a propriedade Terminated, mas � uma boa pr�tica inclu�-la
    // em um m�todo de finaliza��o gen�rico.
    FWorker1.Terminate;
    // WaitFor aguarda a thread finalizar, n�o importa o motivo.
    // Ele retorna imediatamente se a thread j� tiver terminado.
    FWorker1.WaitFor;
    FWorker1.Free;
    FWorker1 := nil;
  end;

  if Assigned(FWorker2) then
  begin
    FWorker2.Terminate;
    FWorker2.WaitFor;
    FWorker2.Free;
    FWorker2 := nil;
  end;
end;

procedure TMainForm.DisplayBalances;
begin
  LogWrite('Saldos Atuais -> Conta %d: %d | Conta %d: %d', [
    FBancoConta101.AccountNumber,
    FBancoConta101.GetBalance,
    FBancoConta102.AccountNumber,
    FBancoConta102.GetBalance]);
end;

procedure TMainForm.SetButtonStates(RunningState: TRunningState);
begin
  IniciarDeadlockExemploButton.Enabled := RunningState = IsStopped;
  IniciarDeadlockPrevencaoButton.Enabled := RunningState = IsStopped;
  Repaint;
end;

procedure TMainForm.TransferWorkerFinished(Sender: TObject);
var
  Worker: TBankTransferWorker;
begin
  // Este evento � executado na thread principal (UI Thread)!
  if (csDestroying in ComponentState) then
    Exit;

  Worker := Sender as TBankTransferWorker;

  // Usa a flag IsTransferDone para um log mais rico, informando o sucesso da opera��o.
  if Worker.IsTransferDone then
    LogWrite('Thread de Transfer�ncia (ID: %d) finalizou COM SUCESSO.', [Worker.ThreadID])
  else
    LogWrite('Thread de Transfer�ncia (ID: %d) finalizou COM FALHA (prov�vel exce��o).', [Worker.ThreadID]);

  // Decrementa o contador de forma at�mica para gerenciar o ciclo de vida.
  TInterlocked.Decrement(FRunningWorkers);

  // Apenas quando o contador de threads em execu��o chegar a zero,
  // o processo � considerado conclu�do.
  if FRunningWorkers = 0 then
  begin
    LogWrite('--- Todas as opera��es de transfer�ncia foram conclu�das. ---');
    DisplayBalances;
    SetButtonStates(IsStopped);
  end;
end;

procedure TMainForm.IniciarDeadlockExemploButtonClick(Sender: TObject);
begin
  LogWrite('--- Iniciando Exemplo de DEADLOCK (sem preven��o) ---');
  LogWrite('Isso pode travar a aplica��o. Voc� provavelmente ter� ' +
    'que encerr�-la manualmente.');

  FinalizeWorkers;
  // Reseta saldos
  FBancoConta101.Deposit(1000 - FBancoConta101.GetBalance);
  FBancoConta102.Deposit(1000 - FBancoConta102.GetBalance);
  DisplayBalances;
  SetButtonStates(IsRunning);

  // Define que duas threads ser�o executadas
  FRunningWorkers := 2;

  // Thread 1: 101 -> 102
  FWorker1 := TBankTransferWorker.Create(FBancoConta101, FBancoConta102, 100, False);
  FWorker1.OnTerminate := TransferWorkerFinished;
  FWorker1.Start;

  // Thread 2: 102 -> 101
  FWorker2 := TBankTransferWorker.Create(FBancoConta102, FBancoConta101, 100, False);
  FWorker2.OnTerminate := TransferWorkerFinished;
  FWorker2.Start;

  LogWrite('Threads de transfer�ncia iniciadas (sem preven��o).');
end;

procedure TMainForm.IniciarDeadlockPrevencaoButtonClick(Sender: TObject);
begin
  LogWrite('--- Iniciando Exemplo com PREVEN��O de DEADLOCK ---');

  FinalizeWorkers;
  // Reseta saldos
  FBancoConta101.Deposit(1000 - FBancoConta101.GetBalance);
  FBancoConta102.Deposit(1000 - FBancoConta102.GetBalance);
  DisplayBalances;
  SetButtonStates(IsRunning);

  // Define que duas threads ser�o executadas
  FRunningWorkers := 2;

  // Thread 1: 101 -> 102
  FWorker1 := TBankTransferWorker.Create(FBancoConta101, FBancoConta102, 100, True);
  FWorker1.OnTerminate := TransferWorkerFinished;
  FWorker1.Start;

  // Thread 2: 102 -> 101
  FWorker2 := TBankTransferWorker.Create(FBancoConta102, FBancoConta101, 100, True);
  FWorker2.OnTerminate := TransferWorkerFinished;
  FWorker2.Start;

  LogWrite('Threads de transfer�ncia iniciadas (com preven��o).');
end;

end.
