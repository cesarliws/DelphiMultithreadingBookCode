unit DelphiMultithreadingBook0602.MainForm;

interface

uses
  System.Classes, System.Threading, Vcl.Forms, Vcl.StdCtrls, Vcl.Controls,
  DelphiMultithreadingBook.Utils;

type
  TMainForm = class(TForm)
    IniciarTaskButton: TButton;
    CalcularTaskButton: TButton;
    ForceExceptionCheckBox: TCheckBox;
    LogMemo: TMemo;

    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure IniciarTaskButtonClick(Sender: TObject);
    procedure CalcularTaskButtonClick(Sender: TObject);
  private
    FFutureRunning: Boolean;
    FTaskRunning: Boolean;
    procedure SetButtonStates(RunningState: TRunningState);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.SysUtils;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplica��o iniciada.');
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := (not FTaskRunning) and (not FFutureRunning);

  if FTaskRunning then
    LogWrite('*** Aguarde a Tarefa (TTask) finalizar para fechar esta Janela...');

  if FFutureRunning then
    LogWrite('*** Aguarde o Calculo (IFuture) finalizar para fechar esta Janela...');
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  UnregisterLogger;
end;

procedure TMainForm.IniciarTaskButtonClick(Sender: TObject);
begin
  LogWrite('> Iniciando tarefa TTask...');
  FTaskRunning := True;
  SetButtonStates(IsRunning);

  TTask.Run(
    procedure
    var
      i: Integer;
    begin
      try
        DebugLogWrite('TTask: Iniciando trabalho pesado...');

        for i := 1 to 5 do
        begin
          if TTask.CurrentTask.Status = TTaskStatus.Canceled then
          begin
            DebugLogWrite('TTask: Tarefa cancelada cooperativamente.');
            Break;
          end;

          DebugLogWrite('TTask: Executando passo %d...', [i]);
          Sleep(1000);
        end;

        DebugLogWrite('TTask: Trabalho conclu�do.');
      finally
        TThread.Queue(nil,
          procedure
          begin
            if not (csDestroying in ComponentState) then
            begin
              LogWrite('Tarefa TTask conclu�da e UI atualizada!');
              SetButtonStates(IsStopped);
            end;
            FTaskRunning := False;
          end
          );
      end;
    end
  );

  LogMemo.Lines.Add('Tarefa TTask disparada! UI continua responsiva.');
end;

procedure TMainForm.CalcularTaskButtonClick(Sender: TObject);
var
  CalcFuture: IFuture<Integer>;
  ForceException: Boolean;
begin
  LogWrite('> Iniciando tarefa de c�lculo (IFuture)...');
  ForceException := ForceExceptionCheckBox.Checked;
  SetButtonStates(IsRunning);
  FFutureRunning := True;

  CalcFuture := TTask.Future<Integer>(
    function: Integer
    var
      i, index, Sum: Integer;
    begin
      Sum := 0;
      index := 0;
      DebugLogWrite('IFuture Task: Iniciando c�lculo pesado...');
      try
        // Simula c�lculo pesado
        for i := 1 to 100000000 do
        begin
          Inc(Sum);
          // Verifica cancelamento de forma mais eficiente
          TTask.CurrentTask.CheckCanceled;

          if ForceException and (Random(100) = 0) then
          begin
            index := i;
            raise Exception.Create('Erro simulado durante o c�lculo!');
          end;
        end;

        // Atribui o resultado final
        Result := Sum;
        DebugLogWrite('IFuture Task: C�lculo conclu�do.');
      except
        on E: Exception do
        begin
          DebugLogWrite(
            'IFuture Task: Exce��o capturada na tarefa: %s ap�s %d itera��es.',
            [E.Message, index]);
          // Re-lan�a para a IFuture
          raise;
        end;
      end;
    end
  );

  // Task que aguarda o resultado da Future e atualiza a UI
  TTask.Run(
    procedure
    var
      ResultFromFuture: Integer;
      ExceptionObject: TObject;
    begin
      // Espera a conclus�o e trata poss�veis exce��es
      try
        // Isso lan�ar� a exce��o se a task falhou
        ResultFromFuture := CalcFuture.Value;
        // importante remover a refer�ncia, sen�o pode ter memory leak
        CalcFuture := nil;

        TThread.Queue(nil,
          procedure
          begin
            LogWrite('Resultado do c�lculo (IFuture): %d', [ResultFromFuture]);
            SetButtonStates(IsStopped);
            FFutureRunning := False;
          end
        );
      except
        on E: Exception do
        begin
          // Captura a exce��o para exibi��o na thread principal
          ExceptionObject := AcquireExceptionObject;
          // importante remover a refer�ncia, sen�o pode ter memory leak
          CalcFuture := nil;

          TThread.Queue(nil,
            procedure
            begin
              LogWrite('C�lculo (IFuture) falhou: %s',
                [(ExceptionObject as Exception).ToString]);

              CalcularTaskButton.Enabled := True;
              ForceExceptionCheckBox.Enabled := True;

              // Exce��o capturada com AcquireExceptionObject deve ser destru�da
              ExceptionObject.Free;
              FFutureRunning := False;
            end
          );
        end;
      end;
    end);

  LogWrite('Tarefa de c�lculo disparada! UI continua responsiva.' +
    ' Aguardando resultado...');
end;

procedure TMainForm.SetButtonStates(RunningState: TRunningState);
begin
  IniciarTaskButton.Enabled := RunningState = IsStopped;
  CalcularTaskButton.Enabled := RunningState = IsStopped;
  ForceExceptionCheckBox.Enabled := RunningState = IsStopped;
end;

end.

