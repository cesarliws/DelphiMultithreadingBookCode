unit DelphiMultithreadingBook0804.BankTransferWorker;

interface

uses
  System.Classes,
  DelphiMultithreadingBook0804.BankAccount;

type
  TBankTransferWorker = class(TThread)
  private
    FAccountFrom: TBankAccount;
    FAccountTo: TBankAccount;
    FAmount: Integer;
    FIsTransferDone: Boolean;
    // Flag para controlar o comportamento (com/sem preven��o)
    FUseDeadlockPrevention: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(AccountFrom, AccountTo: TBankAccount;
      TransferAmount: Integer; PreventDeadlock: Boolean);
    // Propriedade para acessar o estado de conclus�o da transfer�ncia
    property IsTransferDone: Boolean read FIsTransferDone;
  end;

implementation

uses
  System.SyncObjs, // TCriticalSection
  System.SysUtils,
  DelphiMultithreadingBook.Utils;

{ TBankTransferWorker }

constructor TBankTransferWorker.Create(AccountFrom, AccountTo: TBankAccount;
  TransferAmount: Integer; PreventDeadlock: Boolean);
begin
  // Cria suspensa, ser� iniciada explicitamente
  inherited Create(True);
  // O MainForm gerencia o ciclo de vida
  FreeOnTerminate := False;
  FAccountFrom := AccountFrom;
  FAccountTo := AccountTo;
  FAmount := TransferAmount;
  FUseDeadlockPrevention := PreventDeadlock;
  // 1. Inicializa a flag com False, garantindo um estado inicial conhecido.
  FIsTransferDone := False;
end;

procedure TBankTransferWorker.Execute;
var
  Lock1, Lock2: TCriticalSection;
  Acct1, Acct2: TBankAccount;
begin
  DebugLogWrite(
    'Transfer�ncia de %d para %d, valor %d. Preven��o Deadlock: %s', [
    FAccountFrom.AccountNumber,
    FAccountTo.AccountNumber,
    FAmount,
    BoolToStr(FUseDeadlockPrevention)
  ]);

  // Para simular o deadlock, as threads tentam adquirir os locks em ordem inversa
  // A thread A (101->102) vai tentar Lock(101) depois Lock(102)
  // A thread B (102->101) vai tentar Lock(102) depois Lock(101)
  // Se ambas adquirem o primeiro e esperam pelo segundo, h� um deadlock.

  // Bloco try..except para capturar exce��es na thread
  try
    // Implementa��o com preven��o (ordem consistente de bloqueio)
    if FUseDeadlockPrevention then
    begin
      // A ordem de aquisi��o dos locks � baseada no n�mero da conta.
      // Sempre adquire o lock da conta com menor n�mero primeiro.
      if FAccountFrom.AccountNumber < FAccountTo.AccountNumber then
      begin
        Acct1 := FAccountFrom;
        Acct2 := FAccountTo;
      end
      else
      begin
        Acct1 := FAccountTo;
        Acct2 := FAccountFrom;
      end;

      Lock1 := Acct1.Lock;
      Lock2 := Acct2.Lock;

      DebugLogWrite('Thread %d: Adquirindo Lock %d (primeiro)...',
        [ThreadID, Acct1.AccountNumber]);
      Lock1.Enter;
      try
        DebugLogWrite('Thread %d: Adquirindo Lock %d (segundo)...',
          [ThreadID, Acct2.AccountNumber, sLineBreak]);

        // Pequena pausa para aumentar a chance de deadlock sem preven��o
        Sleep(1);
        Lock2.Enter;
        try
          // Realiza a transfer�ncia dentro dos locks
          FAccountFrom.Withdraw(FAmount);
          FAccountTo.Deposit(FAmount);
          DebugLogWrite(
            'Thread %d: Transfer�ncia de %d para %d de %d conclu�da!', [
            ThreadID,
            FAccountFrom.AccountNumber,
            FAccountTo.AccountNumber,
            FAmount]);
        finally
          Lock2.Leave;
        end;
      finally
        Lock1.Leave;
      end;
    end
    // Implementa��o sem preven��o (para demonstrar o deadlock)
    else
    begin
      // Ordem inconsistente de bloqueio
      // A thread A (101 -> 102) vai tentar FAccountFrom.FLock
      // depois FAccountTo.FLock
      // A thread B (102 -> 101) vai tentar FAccountFrom.FLock (que � 102)
      // depois FAccountTo.FLock (que � 101)
      // Isso pode levar ao deadlock.

      DebugLogWrite('Thread %d: Adquirindo Lock da conta de origem (%d)...',
        [ThreadID, FAccountFrom.AccountNumber]);

      FAccountFrom.Lock.Enter;
      try
        DebugLogWrite('Thread %d: Adquirindo Lock da conta de destino (%d)...',
          [ThreadID, FAccountTo.AccountNumber]);

        // Pequena pausa para aumentar a chance de deadlock
        Sleep(1);
        // SEGUNDO LOCK, em ordem inversa para uma das threads
        FAccountTo.Lock.Enter;
        try
          // Realiza a transfer�ncia
          FAccountFrom.Withdraw(FAmount);
          FAccountTo.Deposit(FAmount);
          DebugLogWrite(
            'Thread %d: Transfer�ncia de %d para %d de %d conclu�da!', [
            ThreadID,
            FAccountFrom.AccountNumber,
            FAccountTo.AccountNumber,
            FAmount]);
        finally
          FAccountTo.Lock.Leave;
        end;
      finally
        FAccountFrom.Lock.Leave;
      end;
    end; // FUseDeadlockPrevention

    // 2. A flag S� � definida como True se chegarmos ao final do bloco try,
    // o que significa que nenhuma exce��o ocorreu.
    FIsTransferDone := True;
    DebugLogWrite('Thread %d: Transfer�ncia conclu�da COM SUCESSO.', [ThreadID]);

  except
    // 3. Em caso de exce��o, a flag FIsTransferDone permanecer� False.
    // Captura exce��es na thread (ex: Saldo insuficiente)
    on E: Exception do
    begin
      DebugLogWrite('Thread %d: ERRO na transfer�ncia: %s', [ThreadID, E.Message]);
      // N�o re-lan�amos a exce��o para que a thread termine seu ciclo
      // de vida normalmente e dispare o OnTerminate.
    end;
  end;
end;

end.
