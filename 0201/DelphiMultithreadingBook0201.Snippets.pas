unit DelphiMultithreadingBook0201.Snippets;

// Unit usada somente para criar os snippets de c�digos aleat�rios usados em
// trechos do livro. N�o � c�digo pronto para uso.

interface

uses
  System.Classes,
  Vcl.StdCtrls,
  Vcl.Forms;

type
  // Apenas modelo para estudos, n�o usada no Projeto.
  // Leia os coment�rios
  TWorkerThread = class(TThread)
  protected
    procedure Execute; override;
  public
    // Construtor para inicializar a thread
    constructor Create(CreateSuspended: Boolean); overload;
  end;

type
  TBusyWorkerThread = class(TThread)
  protected
    procedure Execute; override;
  end;

type
  TBackgroundWorkerThread = class(TThread)
  protected
    procedure Execute; override;
  end;

type
  TRunThreadForm = class(TForm)
    LogMemo: TMemo;
    StartButton: TButton;
    procedure StartButtonClick(Sender: TObject);
  private
    FWorkerThread: TWorkerThread;
  end;

type
  TTasksForm = class(TForm)
   StartButton: TButton;
   StopButton: TButton;
   procedure FormDestroy(Sender: TObject);
   procedure StartButtonClick(Sender: TObject);
   procedure StopButtonClick(Sender: TObject);
  private
    FWorkerThread: TWorkerThread;
  end;

implementation

var
  RunThreadForm: TRunThreadForm;

{ TRunThreadForm }

procedure TRunThreadForm.StartButtonClick(Sender: TObject);
begin
  // Cria a thread em estado suspenso
  FWorkerThread := TWorkerThread.Create(True);
  // Configura��es adicionais podem ir aqui
  // ...
  // Inicia a execu��o da thread
  FWorkerThread.Start;
end;

{ TWorkerThread }

constructor TWorkerThread.Create(CreateSuspended: Boolean);
begin
  // Chame o construtor do ancestral TThread
  inherited Create(CreateSuspended);
  // (Opcional) Adicione suas pr�prias inicializa��es aqui
end;

procedure TWorkerThread.Execute;
begin
  // --- Este � o cora��o da sua thread! ---
  // Todo o c�digo que voc� quer que execute em segundo plano vai aqui.
  // IMPORTANTE: NUNCA acesse componentes da interface de usu�rio (UI) aqui!
  // Isso ser� explicado em detalhes mais adiante.

  // (Este � um exemplo de C�DIGO RUIM - apenas para ilustra��o do conceito)
  // LogMemo.Lines.Add('A thread est� executando!');

  // Simula um trabalho demorado
  Sleep(5000); // Pausa a execu��o da thread por 5 segundos

  // (Este � um exemplo de C�DIGO RUIM)
  // LogMemo.Lines.Add('A thread terminou!');

  // (Opcional) Verifique a propriedade Terminated periodicamente para permitir
  // o encerramento da thread
  // if not Terminated then
  // begin
  // // Continua o trabalho
  // end;
end;

{ TTasksForm }

procedure TTasksForm.FormDestroy(Sender: TObject);
begin
  // Garante que a thread seja terminada e liberada ao fechar o formul�rio
  if Assigned(FWorkerThread) then
  begin
    FWorkerThread.Terminate;
    FWorkerThread.WaitFor;
    FWorkerThread.Free;
    FWorkerThread := nil;
  end;
end;

procedure TTasksForm.StartButtonClick(Sender: TObject);
begin
  if not Assigned(FWorkerThread) then
  begin
    FWorkerThread := TWorkerThread.Create(True);
    FWorkerThread.FreeOnTerminate := False; // IMPORTANTE: Gerenciamento manual
    FWorkerThread.Start;
  end;
end;

procedure TTasksForm.StopButtonClick(Sender: TObject);
begin
  if Assigned(FWorkerThread) then
  begin
    FWorkerThread.Terminate; // Sinaliza para a thread terminar cooperativamente
    FWorkerThread.WaitFor;   // Espera a thread realmente terminar
    FWorkerThread.Free;      // Libera o objeto thread
    FWorkerThread := nil;    // Limpa a refer�ncia
  end;
end;

{ TBusyWorkerThread }

// Dentro do m�todo Execute da TThread
procedure TBusyWorkerThread.Execute;
begin
  // ... trabalho demorado ...
  TThread.Synchronize(nil,
    procedure
    begin
      // Este c�digo roda na thread principal (UI thread)
      RunThreadForm.LogMemo.Lines.Add('Trabalho conclu�do!');
    end);
end;

{ TBackgroundWorkerThread }

// Dentro do m�todo Execute da TThread
procedure TBackgroundWorkerThread.Execute;
begin
  // ... trabalho demorado ...
  TThread.Queue(nil,
    procedure
    begin
      // Este c�digo roda na thread principal (UI thread)
      RunThreadForm.LogMemo.Lines.Add('Trabalho conclu�do (ass�ncrono)!');
    end);
end;

end.
