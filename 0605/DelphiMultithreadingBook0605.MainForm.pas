unit DelphiMultithreadingBook0605.MainForm;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  System.Threading,  // TTask, ITask
  DelphiMultithreadingBook.Utils;

type
  TMainForm = class(TForm)
    IniciarTarefaButton: TButton;
    CancelarTarefaButton: TButton;
    LogMemo: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure IniciarTarefaButtonClick(Sender: TObject);
    procedure CancelarTarefaButtonClick(Sender: TObject);
  private
    // Refer�ncia para a tarefa em execu��o
    FCurrentTask: ITask;
    FFinalSumValue: Integer;
    procedure SetButtonStates(RunningState: TRunningState);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.SysUtils,
  System.TypInfo;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplica��o iniciada.');
  SetButtonStates(IsStopped);
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not Assigned(FCurrentTask);
  if not CanClose then
  begin
    LogWrite('* Aguarde a Tarefa finalizar para fechar esta Janela!');
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  UnregisterLogger;
end;

procedure TMainForm.IniciarTarefaButtonClick(Sender: TObject);
begin
  // Verifica se h� uma tarefa ativa e n�o finalizada
  if Assigned(FCurrentTask) and (FCurrentTask.Status = TTaskStatus.Running) then
  begin
    LogWrite('Uma tarefa j� est� em execu��o.');
    Exit;
  end;

  LogWrite('> Iniciando tarefa de longa dura��o (cancel�vel), aguarde...');
  SetButtonStates(IsRunning);
  FFinalSumValue := 0;

  FCurrentTask := TTask.Run(
    // Corpo da tarefa
    procedure
    var
      i, Sum: Integer;
    begin
      DebugLogWrite('PPL Task: Iniciando c�lculo pesado...');
      try
        // Loop bem longo
        for i := 1 to 200000000 do
        begin
          // Verifica se o cancelamento foi solicitado.
          // Se sim, lan�a EOperationCancelled.
          TTask.CurrentTask.CheckCanceled;

          // Simula trabalho de c�lculo
          Inc(Sum);

          // Opcional: Sleep(1) para permitir trocas de contexto e teste de
          // cancelamento mais frequente
          // Sleep(1);
        end;

        DebugLogWrite('PPL Task: Trabalho conclu�do.');
      except
        // Captura a exce��o espec�fica de cancelamento da PPL
        on E: EOperationCancelled do
        begin
          DebugLogWrite(
            'PPL Task: Exce��o de cancelamento (EOperationCancelled) capturada.');
          // A��es de limpeza espec�ficas para o cancelamento podem ir aqui
        end;
        // Captura exce��es agregadas (se houver tarefas filhas falhando)
        on E: EAggregateException do
        begin
          DebugLogWrite('PPL Task: Erro agregado: %s', [E.ToString]);
        end;
        // Captura outras exce��es inesperadas
        on E: Exception do
        begin
          DebugLogWrite('PPL Task: Erro inesperado: %s', [E.Message]);
        end;
      end; // Fim do try..except

      // Atualiza a UI ap�s a conclus�o da tarefa
      TThread.Queue(nil,
        procedure
        begin
          if (csDestroying in ComponentState) then
            Exit;

          FFinalSumValue := Sum;
          LogWrite('Tarefa finalizada. Sum = %d. Status: %s', [FFinalSumValue,
            GetEnumName(TypeInfo(TTaskStatus), Integer(FCurrentTask.Status))]);

          SetButtonStates(IsStopped);
          FCurrentTask := nil;
        end);
    end);
end;

procedure TMainForm.CancelarTarefaButtonClick(Sender: TObject);
begin
  // Verifica se a tarefa est� ativa
  if Assigned(FCurrentTask) and (FCurrentTask.Status = TTaskStatus.Running) then
  begin
    LogWrite('PPL: Solicitando cancelamento da tarefa...');
    // Sinaliza o cancelamento para a task
    FCurrentTask.Cancel;
  end
  else
  begin
    LogWrite('PPL: Nenhuma tarefa ativa para cancelar.');
  end;
end;

procedure TMainForm.SetButtonStates(RunningState: TRunningState);
begin
  IniciarTarefaButton.Enabled := RunningState = IsStopped;
  CancelarTarefaButton.Enabled := RunningState = IsRunning;
end;

end.
