unit DelphiMultithreadingBook0804.BankAccount;

interface

uses
  System.Classes,
  System.SyncObjs, // TCriticalSection
  System.SysUtils;

type
  TBankAccount = class(TObject)
  private
    FBalance: Integer;
    FAccountNumber: Integer;
    FLock: TCriticalSection;
  public
    constructor Create(AccountNumber: Integer; InitialBalance: Integer);
    destructor Destroy; override;

    // Métodos para acesso seguro à conta
    function GetBalance: Integer;
    function GetAccountNumber: Integer;

    procedure Deposit(Amount: Integer);
    procedure Withdraw(Amount: Integer);

    property AccountNumber: Integer read GetAccountNumber;

    // Lock específico para esta conta
    property Lock: TCriticalSection read FLock;
  end;

implementation

{ TBankAccount }

constructor TBankAccount.Create(AccountNumber: Integer;
  InitialBalance: Integer);
begin
  inherited Create;
  FAccountNumber := AccountNumber;
  FBalance := InitialBalance;
  FLock := TCriticalSection.Create;
end;

destructor TBankAccount.Destroy;
begin
  FLock.Free;
  inherited;
end;

procedure TBankAccount.Deposit(Amount: Integer);
begin
  FLock.Enter;
  try
    FBalance := FBalance + Amount;
  finally
    FLock.Leave;
  end;
end;

procedure TBankAccount.Withdraw(Amount: Integer);
begin
  FLock.Enter;
  try
    if FBalance >= Amount then
      FBalance := FBalance - Amount
    else
      raise Exception.Create('Saldo insuficiente!');
  finally
    FLock.Leave;
  end;
end;

function TBankAccount.GetBalance: Integer;
begin
  FLock.Enter;
  try
    Result := FBalance;
  finally
    FLock.Leave;
  end;
end;

function TBankAccount.GetAccountNumber: Integer;
begin
  Result := FAccountNumber;
end;

end.
