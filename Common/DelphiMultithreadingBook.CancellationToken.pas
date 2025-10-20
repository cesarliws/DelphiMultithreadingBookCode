unit DelphiMultithreadingBook.CancellationToken;

interface

uses
  System.Classes,
  System.SyncObjs,
  System.SysUtils;

type
  /// <summary>
  ///   Interface para token de cancelamento.
  ///   Representa um token que pode ser monitorado para cancelamento.
  ///   Implementado como interface para gerenciamento autom�tico de mem�ria
  /// </summary>
  ICancellationToken = interface(IInterface)
    ['{F774136C-B0E3-40A6-A223-9D5C93C39794}']
    /// <summary>
    ///   Indica se o cancelamento foi solicitado.
    /// </summary>
    function GetIsCancellationRequested: Boolean;
    /// <summary>
    ///   Indica se o cancelamento foi solicitado.
    /// </summary>
    property IsCancellationRequested: Boolean read GetIsCancellationRequested;

    /// <summary>
    ///   Lan�a uma exce��o se o cancelamento foi solicitado.
    /// </summary>
    /// <exception cref="EOperationCancelled">
    ///   Lan�ada quando o cancelamento foi solicitado
    /// </exception>
    procedure ThrowIfCancellationRequested;

    // Adiciona um m�todo para esperar pelo cancelamento.
    // Permite que a thread espere passivamente pelo sinal de cancelamento.
    function WaitForCancellation(Timeout: Cardinal = INFINITE): TWaitResult;
  end;

  // Classe concreta que implementa a interface ICancellationToken
  TCancellationToken = class(TInterfacedObject, ICancellationToken)
  strict private
    // Refer�ncia ao TEvent da Source
    FCancellationEvent: TEvent;
    FIsCancellationRequestedFunc: TFunc<Boolean>;
  public
    // Construtor recebe a fun��o para verificar o estado e o TEvent da Source
    constructor Create(IsCancellationRequestedFunc: TFunc<Boolean>;
      CancellationEvent: TEvent);

    function GetIsCancellationRequested: Boolean;
    function WaitForCancellation(Timeout: Cardinal): TWaitResult;
    procedure ThrowIfCancellationRequested;

    property IsCancellationRequested: Boolean read GetIsCancellationRequested;
  end;

  /// <summary>
  ///   Fornece a capacidade de solicitar que uma opera��o seja cancelada.
  /// </summary>
  TCancellationTokenSource = class
  strict private
    FIsCancellationRequested: Boolean;
    // Evento interno para sinalizar o cancelamento
    FEvent: TEvent;
    // Armazena a interface do token
    FToken: ICancellationToken;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    ///   Sinaliza que o cancelamento deve ser solicitado.
    /// </summary>
    procedure Cancel;
    procedure Reset;
    /// <summary>
    ///   Retorna o ICancellationToken associado a esta fonte.
    /// </summary>
    function Token: ICancellationToken;
    /// <summary>
    ///   Indica se o cancelamento foi solicitado.
    /// </summary>
    property IsCancellationRequested: Boolean read FIsCancellationRequested;
  end;

implementation

{ TCancellationTokenSource }

constructor TCancellationTokenSource.Create;
begin
  inherited Create;
  FIsCancellationRequested := False;
  // Manual reset event
  FEvent := TEvent.Create(nil, True, False, '');
  // Cria o token passando a l�gica de verifica��o e o evento
  // (sem ciclo de refer�ncia)
  FToken := TCancellationToken.Create(
    // Function an�nima que verifica o estado da Source
    function: Boolean
    begin
      Result := FIsCancellationRequested;
    end,
    // Passa o evento para o token poder esperar por ele
    FEvent
  );
end;

destructor TCancellationTokenSource.Destroy;
begin
  Cancel;
  // FToken � uma interface, ser� liberada quando n�o houver mais
  // refer�ncias externas. FEvent precisa ser liberado explicitamente.
  FEvent.Free;
  inherited;
end;

procedure TCancellationTokenSource.Reset;
begin
  FIsCancellationRequested := False
end;

procedure TCancellationTokenSource.Cancel;
begin
  if not FIsCancellationRequested then
  begin
    FIsCancellationRequested := True;
    // Sinaliza o evento de cancelamento para quem estiver esperando
    FEvent.SetEvent;
  end;
end;

function TCancellationTokenSource.Token: ICancellationToken;
begin
  // Retorna a inst�ncia �nica da interface do token
  Result := FToken;
end;

{ TCancellationToken }

constructor TCancellationToken.Create(IsCancellationRequestedFunc:
  TFunc<Boolean>; CancellationEvent: TEvent);
begin
  inherited Create;
  FIsCancellationRequestedFunc := IsCancellationRequestedFunc;
  // Refer�ncia direta ao TEvent da Source (forte)
  FCancellationEvent := CancellationEvent;
end;

function TCancellationToken.GetIsCancellationRequested: Boolean;
begin
  // Chama a lambda para verificar o estado da Source
  Result := FIsCancellationRequestedFunc();
end;

procedure TCancellationToken.ThrowIfCancellationRequested;
begin
  if (not Assigned(Self)) or GetIsCancellationRequested then
    raise EOperationCancelled.Create('Opera��o cancelada!');
end;

function TCancellationToken.WaitForCancellation(Timeout: Cardinal): TWaitResult;
begin
  // Espera no TEvent da Source para ser notificado sobre o cancelamento
  Result := FCancellationEvent.WaitFor(Timeout);
end;

end.
