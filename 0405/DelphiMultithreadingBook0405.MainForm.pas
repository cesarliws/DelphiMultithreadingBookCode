unit DelphiMultithreadingBook0405.MainForm;

interface

uses
  System.Classes, System.SysUtils, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  DelphiMultithreadingBook0405.WorkerWithExceptionThread,
  DelphiMultithreadingBook0405.WorkerWithErrorThread;

type
  TMainForm = class(TForm)
    ExecutarThreadComErroButton: TButton;
    ExecutarThreadComExceptionButton: TButton;
    LogMemo: TMemo;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ExecutarThreadComErroButtonClick(Sender: TObject);
    procedure ExecutarThreadComExceptionButtonClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
     // Referência para Exceção Não Tratada (`FatalException`)
    FWorkerWithException: TWorkerWithExceptionThread;
    // Referência para Interceptando Exceções dentro da Thread (`try..except`)
    FWorkerWithErrorThread: TWorkerWithErrorThread;

    // Handler para o OnTerminate da TWorkerThread
    // Exceção Não Tratada (`FatalException`)
    procedure WorkerWithExceptionThreadTerminated(Sender: TObject);

    // Handler para o OnTerminate da TWorkerWithErrorThread
    // Interceptando Exceções dentro da Thread (`try..except`)
    procedure WorkerWithErrorThreadTerminated(Sender: TObject);

  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  Vcl.Dialogs,
  DelphiMultithreadingBook.Utils;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplicação iniciada.');
  LogWrite('Clique em "Iniciar Thread com Exception" para testar FatalException.');
  LogWrite('Clique em "Iniciar Thread com Erro" para testar a propagação segura.');
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  // Como as threads são FreeOnTerminate, não precisamos
  // chamar WaitFor/Free aqui. Apenas desregistramos o logger.
  UnregisterLogger;
end;

procedure TMainForm.ExecutarThreadComExceptionButtonClick(Sender: TObject);
begin
  if Assigned(FWorkerWithException) then
  begin
    LogWrite('A thread de FatalException já está em execução.');
    Exit;
  end;

  LogWrite('> Iniciando Thread para lançar exceção sem tratamento...');

  FWorkerWithException := TWorkerWithExceptionThread.Create(False);
  FWorkerWithException.FreeOnTerminate := True;
  FWorkerWithException.OnTerminate := WorkerWithExceptionThreadTerminated;
end;

procedure TMainForm.ExecutarThreadComErroButtonClick(Sender: TObject);
begin
  if Assigned(FWorkerWithErrorThread) then
  begin
    LogWrite('A thread com erro já está em execução.');
    Exit;
  end;

  LogWrite('> Iniciando Thread para capturar e propagar exceção...');

  FWorkerWithErrorThread := TWorkerWithErrorThread.Create;
  FWorkerWithErrorThread.OnTerminate := WorkerWithErrorThreadTerminated;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  // Se a thread estiver executando, aguarda finalizar pois estas threads
  // podem criar ou capturar a exception após a thread ser finalizada.
  CanClose := not Assigned(FWorkerWithErrorThread)
    and not Assigned(FWorkerWithException);

  LogWrite('*** Aguarde a Thread finalizar para finalizar a aplicação!')
end;

procedure TMainForm.WorkerWithErrorThreadTerminated(Sender: TObject);
var
  WorkerThread: TWorkerWithErrorThread;
begin
  // Este método é executado na thread principal (UI Thread)!
  WorkerThread := Sender as TWorkerWithErrorThread;

  LogWrite('Thread %d (Com Erro) TERMINOU.', [WorkerThread.ThreadID]);

  // Verifica se a thread armazenou uma exceção
  if Assigned(WorkerThread.Error) then
  begin
    LogWrite('ERRO NA THREAD (propriedade Error): %s',
      [WorkerThread.Error.Message]);

    ShowMessage(Format('Erro detectado na thread (via propriedade Error): %s',
      [WorkerThread.Error.Message]));

    // IMPORTANTE: O objeto WorkerThread.Error (que foi AcquireExceptionObject)
    // será liberado automaticamente no destructor, quando o objeto
    // TWorkerWithErrorThread for liberado (devido a FreeOnTerminate = True).
    // Não chame Free aqui.
  end
  else
    LogWrite('Thread (Com Erro) concluída sem erros reportados.');

  // A thread já se auto-liberou, apenas limpamos a referência
  FWorkerWithErrorThread := nil;
end;

procedure TMainForm.WorkerWithExceptionThreadTerminated(Sender: TObject);
var
  Error: Exception;
  WorkerThread: TWorkerWithExceptionThread;
begin
  // Este evento é executado na thread principal (UI thread)
  WorkerThread := Sender as TWorkerWithExceptionThread;

  LogWrite('Thread %d (FatalException) TERMINOU.', [WorkerThread.ThreadID]);

  // Verifica se a thread foi terminada devido a uma exceção não tratada
  if Assigned(WorkerThread.FatalException) then
  begin
    Error := Exception(WorkerThread.FatalException);

    LogWrite('--- Exceção FATAL detectada em OnTerminate! ---');
    LogWrite('Mensagem: %s', [Error.Message]);
    LogWrite('Classe: %s', [Error.ClassName]);
    LogWrite('----------------------------------------');

    ShowMessage(Format('Erro FATAL na thread: %s', [Error.Message]));
    // IMPORTANTE: Não é necessário liberar WorkerThread.FatalException aqui,
    // a TThread se encarrega disso ao ser liberada (devido a FreeOnTerminate).
  end
  else
  begin
    LogWrite('Thread (FatalException) concluída sem erros reportados.');
  end;

  // Limpa a referência da thead no form
  FWorkerWithException := nil;
end;

end.
