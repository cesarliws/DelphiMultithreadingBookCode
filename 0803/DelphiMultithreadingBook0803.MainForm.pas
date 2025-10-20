unit DelphiMultithreadingBook0803.MainForm;

interface

uses
  System.Classes, System.Threading, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  DelphiMultithreadingBook0803.ConsumerThread,
  DelphiMultithreadingBook.Utils;

type
  TMainForm = class(TForm)
    ProduzirMensagensButton: TButton;
    LogMemo: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ProduzirMensagensButtonClick(Sender: TObject);
  private
    FConsumerThread: TConsumerThread;
    // Controla a tarefa de produ��o
    FProducerTask: ITask;

    // M�todo que ser� passado como callback para o ConsumerThread
    procedure ConsumerMessagesCallback(const Text: string);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.SysUtils,
  WinApi.Windows, // Sleep
  DelphiMultithreadingBook0803.SharedData;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplica��o iniciada.');
  LogWrite('Consumidor iniciado e aguardando mensagens...');

  // 1. Cria e inicia o Consumidor UMA VEZ. Ele viver� com a aplica��o.
  FConsumerThread := TConsumerThread.Create(ConsumerMessagesCallback);
  FConsumerThread.Start;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  if Assigned(FProducerTask) then
  begin
    FProducerTask.Cancel;
  end;

  // 3. Encerra o Consumidor de forma limpa quando a aplica��o fecha.
  if Assigned(FConsumerThread) then
  begin
    FConsumerThread.Terminate;
    FConsumerThread.WaitFor;
    FConsumerThread.Free;
    FConsumerThread := nil;
  end;
  UnregisterLogger;
end;

procedure TMainForm.ConsumerMessagesCallback(const Text: string);
begin
  LogWrite(Text);
end;

procedure TMainForm.ProduzirMensagensButtonClick(Sender: TObject);
begin
  if Assigned(FProducerTask) then
  begin
    LogWrite('Aguarde o lote anterior de mensagens ser produzido.');
    Exit;
  end;

  ProduzirMensagensButton.Enabled := False;
  LogWrite('> Iniciando produ��o de um novo lote de 10 mensagens...');

  // 2. A "Produ��o" � uma TTask leve, n�o uma TThread pesada.
  FProducerTask := TTask.Run(
    procedure
    var
      i: Integer;
      TextMessage: string;
    begin
      try
        try
          for i := 1 to 10 do
          begin
            TTask.CurrentTask.CheckCanceled;
            TextMessage := Format('Mensagem %d', [i]);
            ThreadSafeMessageQueue.PushItem(TextMessage);
            DebugLogWrite('Produtor: Adicionou "%s" na fila.', [TextMessage]);
            Sleep(100 + Random(500)); // Simula tempo de produ��o
          end;
        except
          on E: EOperationCancelled do
            DebugLogWrite('Produtor: Produ��o de mensagens Cancelada!');

          on E: Exception do
          begin
            TextMessage := E.ToString;
            TThread.Queue(nil,
              procedure
              begin
                if not (csDestroying in ComponentState) then
                  LogWrite(TextMessage);
              end);
          end;
        end;
      finally
        // Ao final, apenas reabilita o bot�o na UI thread
        TThread.Queue(nil,
          procedure
          begin
            if csDestroying in ComponentState then
              Exit;
            if FProducerTask.Status = TTaskStatus.Completed then
              LogWrite('Lote de mensagens produzido com sucesso.');

            ProduzirMensagensButton.Enabled := True;
            FProducerTask := nil;
          end);
      end;
    end);
end;

end.
