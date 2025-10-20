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

    // Referências explícitas para as duas threads de transferência
    FWorker1: TBankTransferWorker;
    FWorker2: TBankTransferWorker;
    // Contador para gerenciar threads em execução
    FRunningWorkers: Integer;

    // Método auxiliar para exibir saldos no LogMemo
    procedure DisplayBalances;
    // Handler de término para as threads de transferência
    procedure TransferWorkerFinished(Sender: TObject);
    // Controla o estado dos botões da UI
    procedure SetButtonStates(RunningState: TRunningState);
    // Método para finalizar e liberar os workers
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
  LogWrite('Aplicação iniciada.');

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
  // O padrão idiomático é sinalizar (se aplicável), esperar e liberar.

  if Assigned(FWorker1) then
  begin
    // A chamada Terminate é um no-op neste worker específico, pois seu Execute
    // não verifica a propriedade Terminated, mas é uma boa prática incluí-la
    // em um método de finalização genérico.
    FWorker1.Terminate;
    // WaitFor aguarda a thread finalizar, não importa o motivo.
    // Ele retorna imediatamente se a thread já tiver terminado.
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
  // Este evento é executado na thread principal (UI Thread)!
  if (csDestroying in ComponentState) then
    Exit;

  Worker := Sender as TBankTransferWorker;

  // Usa a flag IsTransferDone para um log mais rico, informando o sucesso da operação.
  if Worker.IsTransferDone then
    LogWrite('Thread de Transferência (ID: %d) finalizou COM SUCESSO.', [Worker.ThreadID])
  else
    LogWrite('Thread de Transferência (ID: %d) finalizou COM FALHA (provável exceção).', [Worker.ThreadID]);

  // Decrementa o contador de forma atômica para gerenciar o ciclo de vida.
  TInterlocked.Decrement(FRunningWorkers);

  // Apenas quando o contador de threads em execução chegar a zero,
  // o processo é considerado concluído.
  if FRunningWorkers = 0 then
  begin
    LogWrite('--- Todas as operações de transferência foram concluídas. ---');
    DisplayBalances;
    SetButtonStates(IsStopped);
  end;
end;

procedure TMainForm.IniciarDeadlockExemploButtonClick(Sender: TObject);
begin
  LogWrite('--- Iniciando Exemplo de DEADLOCK (sem prevenção) ---');
  LogWrite('Isso pode travar a aplicação. Você provavelmente terá ' +
    'que encerrá-la manualmente.');

  FinalizeWorkers;
  // Reseta saldos
  FBancoConta101.Deposit(1000 - FBancoConta101.GetBalance);
  FBancoConta102.Deposit(1000 - FBancoConta102.GetBalance);
  DisplayBalances;
  SetButtonStates(IsRunning);

  // Define que duas threads serão executadas
  FRunningWorkers := 2;

  // Thread 1: 101 -> 102
  FWorker1 := TBankTransferWorker.Create(FBancoConta101, FBancoConta102, 100, False);
  FWorker1.OnTerminate := TransferWorkerFinished;
  FWorker1.Start;

  // Thread 2: 102 -> 101
  FWorker2 := TBankTransferWorker.Create(FBancoConta102, FBancoConta101, 100, False);
  FWorker2.OnTerminate := TransferWorkerFinished;
  FWorker2.Start;

  LogWrite('Threads de transferência iniciadas (sem prevenção).');
end;

procedure TMainForm.IniciarDeadlockPrevencaoButtonClick(Sender: TObject);
begin
  LogWrite('--- Iniciando Exemplo com PREVENÇÃO de DEADLOCK ---');

  FinalizeWorkers;
  // Reseta saldos
  FBancoConta101.Deposit(1000 - FBancoConta101.GetBalance);
  FBancoConta102.Deposit(1000 - FBancoConta102.GetBalance);
  DisplayBalances;
  SetButtonStates(IsRunning);

  // Define que duas threads serão executadas
  FRunningWorkers := 2;

  // Thread 1: 101 -> 102
  FWorker1 := TBankTransferWorker.Create(FBancoConta101, FBancoConta102, 100, True);
  FWorker1.OnTerminate := TransferWorkerFinished;
  FWorker1.Start;

  // Thread 2: 102 -> 101
  FWorker2 := TBankTransferWorker.Create(FBancoConta102, FBancoConta101, 100, True);
  FWorker2.OnTerminate := TransferWorkerFinished;
  FWorker2.Start;

  LogWrite('Threads de transferência iniciadas (com prevenção).');
end;

end.
