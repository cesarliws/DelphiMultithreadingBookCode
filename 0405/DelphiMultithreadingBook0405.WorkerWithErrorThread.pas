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
    // Campo para armazenar a exceção capturada
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
  // A thread se auto-liberará quando terminar
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
  // Variável temporária para a exceção
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
        // Força uma exceção EDivByZero
        Valor := 100 div Divisor;
        LogWrite(
          'WorkerWithErrorThread: Divisão efetuada com sucesso 100 / %d = %d',
          [Divisor, Valor]);
      end
      else
        LogWrite('WorkerWithErrorThread: Divisão realizada com sucesso.');
    end;

    LogWrite('WorkerWithErrorThread: Trabalho concluído com sucesso.');
  except
    on E: Exception do
    begin
      // **CRÍTICO:** Adquire o objeto de exceção para garantir que ele não seja
      // liberado automaticamente no final do bloco 'except' da thread de trabalho.
      // Isso permite que o objeto de exceção seja acessado com segurança na
      // thread principal.
      ExceptionObject := AcquireExceptionObject;

      // Armazena a exceção capturada no campo da thread.
      // O objeto 'E' é o mesmo que 'CapturedEx' neste ponto, mas 'CapturedEx'
      // garante que a contagem de referência seja incrementada.
      FError := Exception(ExceptionObject);

      LogWrite('WorkerWithErrorThread: Exceção capturada: %s', [E.Message]);
      // NÃO re-lançamos a exceção, pois ela foi "tratada" para ser reportada.
    end;
  end;
end;

end.
