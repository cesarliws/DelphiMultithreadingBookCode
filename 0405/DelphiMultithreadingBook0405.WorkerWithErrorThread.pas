unit DelphiMultithreadingBook0405.WorkerWithErrorThread;

interface

uses
  System.Classes,
  System.SysUtils,
  DelphiMultithreadingBook0405.WorkerWithExceptionThread;

type
  // Thread que faz tratamento de exceptions
  TWorkerWithErrorThread = class(TThread)
  private
    // Campo para armazenar a exce��o capturada
    FError: Exception;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;

    // Propriedade para acessar o erro (leitura)
    property Error: Exception read FError;
  end;

implementation

uses
  DelphiMultithreadingBook.Utils;

{ TWorkerWithErrorThread }

constructor TWorkerWithErrorThread.Create;
begin
  inherited Create(False);
  // A thread se auto-liberar� quando terminar
  FreeOnTerminate := True;
end;

destructor TWorkerWithErrorThread.Destroy;
begin
  if Assigned(FError) then
    FError.Free;
  inherited;
end;

procedure TWorkerWithErrorThread.Execute;
var
  // Vari�vel tempor�ria para a exce��o
  ExceptionObject: TObject;
  Divisor: Integer;
  i: Integer;
  Valor: Integer;
begin
  // Limpa qualquer erro anterior
  FError := nil;

  try
    for i := 0 to 10 do
    begin
      LogWrite('WorkerWithErrorThread: Iniciando trabalho...');
      // Simula trabalho
      Sleep(1000);

      // Pode ser 0 ou 1
      Divisor := Random(2);
      if Divisor = 0 then
      begin
        LogWrite('WorkerWithErrorThread: Tentando dividir por zero...');
        // For�a uma exce��o EDivByZero
        Valor := 100 div Divisor;
        LogWrite(
          'WorkerWithErrorThread: Divis�o efetuada com sucesso 100 / %d = %d',
          [Divisor, Valor]);
      end
      else
        LogWrite('WorkerWithErrorThread: Divis�o realizada com sucesso.');
    end;

    LogWrite('WorkerWithErrorThread: Trabalho conclu�do com sucesso.');
  except
    on E: Exception do
    begin
      // **CR�TICO:** Adquire o objeto de exce��o para garantir que ele n�o seja
      // liberado automaticamente no final do bloco 'except' da thread de trabalho.
      // Isso permite que o objeto de exce��o seja acessado com seguran�a na
      // thread principal.
      ExceptionObject := AcquireExceptionObject;

      // Armazena a exce��o capturada no campo da thread.
      // O objeto 'E' � o mesmo que 'CapturedEx' neste ponto, mas 'CapturedEx'
      // garante que a contagem de refer�ncia seja incrementada.
      FError := Exception(ExceptionObject);

      LogWrite('WorkerWithErrorThread: Exce��o capturada: %s', [E.Message]);
      // N�O re-lan�amos a exce��o, pois ela foi "tratada" para ser reportada.
    end;
  end;
end;

end.
