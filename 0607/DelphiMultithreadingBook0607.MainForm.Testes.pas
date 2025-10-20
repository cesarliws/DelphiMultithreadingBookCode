unit DelphiMultithreadingBook0607.MainForm.Testes;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Forms, Vcl.StdCtrls,
  System.Threading, Vcl.Controls,
  DelphiMultithreadingBook0607.Threading.Helpers; // Importa o helper

type
  TMainForm = class(TForm)
    LogMemo: TMemo;
    IniciarTaskOnCompleteOnErrorButton: TButton;
    IniciarFutureOnCompleteOnErrorButton: TButton;
    IniciarTaskContinueWithButton: TButton;
    IniciarFutureContinueWithButton: TButton;
    ForceExceptionCheckBox: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure IniciarTaskOnCompleteOnErrorButtonClick(Sender: TObject);
    procedure IniciarFutureOnCompleteOnErrorButtonClick(Sender: TObject);
    procedure IniciarTaskContinueWithButtonClick(Sender: TObject);
    procedure IniciarFutureContinueWithButtonClick(Sender: TObject);
  private
    FTestException: Exception; // Para gerenciar exceções adquiridas
    procedure SetButtonsEnabled(Enabled: Boolean);
    function SimulateWorkAndMaybeError(const TaskName: string; SimulateError: Boolean; Iterations: Integer): Integer;
  end;

var
  MainForm: TMainForm;

implementation

uses
  System.TypInfo; // Para GetEnumName (para TTaskStatus.ToString)

procedure TMainForm.FormCreate(Sender: TObject);
begin
  LogMemo.Lines.Add('Aplicação iniciada.');
  SetButtonsEnabled(True); // Garante que os botões comecem habilitados
  ForceExceptionCheckBox.Checked := True; // Padrão para testar erro
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  // Garante que todas as tasks/futures em execução sejam canceladas e liberadas
  // Nota: FCurrentTestTask e FCurrentTestFuture são apenas para gerenciar
  // a tarefa mais recente de cada tipo de teste. A PPL gerencia o ciclo de vida
  // das tasks/futures encadeadas.
  // Se a task/future ainda estiver rodando, sinaliza cancelamento e espera.
  // Isso é vital para um shutdown limpo.
  // Exemplo para FCurrentTestTask (se fosse um campo ITask real a ser limpo):
  // if Assigned(FCurrentTestTask) and (not FCurrentTestTask.Finished) then
  // begin
  //   FCurrentTestTask.Cancel;
  //   FCurrentTestTask.Wait;
  // end;
  // FCurrentTestTask := nil; // Limpa a referência
  // (Lógica similar para FCurrentTestFuture)

  // Libera exceções capturadas (se houver alguma que o OnError não liberou)
  if Assigned(FTestException) then
  begin
    FTestException.Free;
    FTestException := nil;
  end;
  inherited;
end;

procedure TMainForm.SetButtonsEnabled(Enabled: Boolean);
begin
  IniciarTaskOnCompleteOnErrorButton.Enabled := Enabled;
  IniciarFutureOnCompleteOnErrorButton.Enabled := Enabled;
  IniciarTaskContinueWithButton.Enabled := Enabled;
  IniciarFutureContinueWithButton.Enabled := Enabled;
  ForceExceptionCheckBox.Enabled := Enabled;
end;

function TMainForm.SimulateWorkAndMaybeError(const TaskName: string; SimulateError: Boolean; Iterations: Integer): Integer;
var
  i: Integer;
  Sum: Integer;
begin
  Sum := 0;
  OutputDebugString(PChar(Format('%s: Iniciando trabalho (%d iterações)...%s', [TaskName, Iterations, sLineBreak])));
  try
    for i := 1 to Iterations do
    begin
      TTask.CurrentTask.CheckCanceled; // Verifica cancelamento a cada iteração
      Inc(Sum);
      if SimulateError and (Random(1000000) = 0) then // Chance de 1 em 1 milhão para simular erro
      begin
        raise Exception.Create(Format('Erro simulado em %s na iteração %d!', [TaskName, i]));
      end;
      // Sleep(1); // Opcional para simular mais pausas e permitir trocas de contexto
    end;
    Result := Sum;
    OutputDebugString(PChar(Format('%s: Trabalho concluído (Sum: %d).%s', [TaskName, Sum, sLineBreak])));
  except
    on E: Exception do
    begin
      OutputDebugString(PChar(Format('%s: Exceção capturada na simulação: %s%s', [TaskName, E.Message, sLineBreak])));
      raise; // Re-lança para que a ITask/IFuture registre a falha
    end;
  end;
end;

procedure TMainForm.IniciarTaskOnCompleteOnErrorButtonClick(Sender: TObject);
var
  TestTask: ITask;
begin
  SetButtonsEnabled(False);
  LogMemo.Lines.Add('--- Testando ITask com OnComplete/OnException ---');
  LogMemo.Lines.Add(Format('Forçar Exceção: %s', [BoolToStr(ForceExceptionCheckBox.Checked, True)]));

  TestTask := TTask.Run(
    procedure // Corpo da task
    begin
      SimulateWorkAndMaybeError('Task OnComplete/OnError', ForceExceptionCheckBox.Checked, 20000000); // 20M iterações
    end
  );
  // Não precisamos guardar a referência FCurrentTestTask aqui para liberação,
  // pois os handlers de extensão já gerenciam o ciclo de vida.

  // Define os handlers usando TTaskExtensions
  TTaskExtensions.OnComplete(TestTask,
    procedure // Sucesso
    begin
      LogMemo.Lines.Add(Format('ITask OnComplete: Tarefa concluída com Status: %s',
        [GetEnumName(TypeInfo(TTaskStatus), Integer(TestTask.Status))]));
      SetButtonsEnabled(True);
    end
  );

  TTaskExtensions.OnException(TestTask,
    procedure(AException: Exception) // Falha
    begin
      LogMemo.Lines.Add(Format('ITask OnException: Tarefa falhou com erro: %s', [AException.Message]));
      // A exceção AException é um parâmetro, a liberação é responsabilidade de quem a gerou (PPL).
      SetButtonsEnabled(True);
    end
  );

  TTaskExtensions.ContinueWith(TestTask, // Exemplo de uso de OnCancel via ContinueWith simples
    procedure
    begin
      LogMemo.Lines.Add(Format('ITask OnCancel via ContinueWith: Status: %s',
        [GetEnumName(TypeInfo(TTaskStatus), Integer(TestTask.Status))]));
      SetButtonsEnabled(True);
    end,
    [OnlyOnCanceled] // Executa apenas se a task for cancelada
  );
end;

procedure TMainForm.IniciarFutureOnCompleteOnErrorButtonClick(Sender: TObject);
var
  TestFuture: IFuture<Integer>;
begin
  SetButtonsEnabled(False);
  LogMemo.Lines.Add('--- Testando IFuture com OnComplete/OnException ---');
  LogMemo.Lines.Add(Format('Forçar Exceção: %s', [BoolToStr(ForceExceptionCheckBox.Checked, True)]));

  TestFuture := TTask.Future<Integer>(
    function: Integer // Corpo da future
    begin
      Result := SimulateWorkAndMaybeError('Future OnComplete/OnException', ForceExceptionCheckBox.Checked, 50000000); // 50M iterações
    end
  );
  // Não precisamos guardar a referência FCurrentTestFuture aqui para liberação,
  // pois os handlers de extensão já gerenciam o ciclo de vida.

  // Define os handlers usando TTaskExtensions
  TTaskExtensions.OnComplete<Integer>(TestFuture,
    procedure(AResult: Integer) // Sucesso, com resultado
    begin
      LogMemo.Lines.Add(Format('IFuture OnComplete: Tarefa concluída. Resultado: %d. Status: %s',
        [AResult, GetEnumName(TypeInfo(TTaskStatus), Integer(TestFuture.Status))]));
      SetButtonsEnabled(True);
    end
  );

  TTaskExtensions.OnException<Integer>(TestFuture,
    procedure(AException: Exception) // Falha, com exceção
    begin
      LogMemo.Lines.Add(Format('IFuture OnException: Tarefa falhou com erro: %s', [AException.Message]));
      SetButtonsEnabled(True);
    end
  );

  TTaskExtensions.ContinueWith<Integer>(TestFuture, // Exemplo de uso de OnCancel via ContinueWith simples
    procedure(AResult: Integer) // Recebe o resultado mesmo no cancelamento
    begin
      LogMemo.Lines.Add(Format('IFuture OnCancel via ContinueWith: Status: %s',
        [GetEnumName(TypeInfo(TTaskStatus), Integer(TestFuture.Status))]));
      SetButtonsEnabled(True);
    end,
    [OnlyOnCanceled]
  );
end;

procedure TMainForm.IniciarTaskContinueWithButtonClick(Sender: TObject);
var
  Task1: ITask;
  Task2: ITask;
begin
  SetButtonsEnabled(False);
  LogMemo.Lines.Add('--- Testando ITask com ContinueWith ---');
  LogMemo.Lines.Add(Format('Forçar Exceção para Task 2: %s', [BoolToStr(ForceExceptionCheckBox.Checked, True)]));

  Task1 := TTask.Run(
    procedure // Task 1: sempre completa
    begin
      OutputDebugString('Task 1: Iniciando (2s)...' + sLineBreak);
      Sleep(2000);
      OutputDebugString('Task 1: Concluída.' + sLineBreak);
    end
  );

  Task2 := TTask.Run(
    procedure // Task 2: simula falha
    begin
      OutputDebugString('Task 2: Iniciando (3s)...' + sLineBreak);
      Sleep(3000);
      if ForceExceptionCheckBox.Checked then
      begin
        raise Exception.Create('Erro simulado na Task 2!');
      end;
      OutputDebugString('Task 2: Concluída.' + sLineBreak);
    end
  );

  // Exemplo 1: Continuação que executa apenas se Task1 completa com sucesso
  TTaskExtensions.ContinueWith(Task1,
    procedure
    begin
      LogMemo.Lines.Add('-> Continuação Task 1: Executada (OnlyOnCompleted)');
    end,
    [OnlyOnCompleted]
  );

  // Exemplo 2: Continuação que executa apenas se Task2 falha
  TTaskExtensions.ContinueWith(Task2,
    procedure
    begin
      LogMemo.Lines.Add('-> Continuação Task 2: Executada (OnlyOnFaulted)');
    end,
    [OnlyOnFaulted]
  );

  // Exemplo 3: Continuação que executa se Task1 NÃO completa (e.g., cancelada ou falha)
  // Para testar isso, você teria que cancelar Task1 externamente ou fazê-la falhar.
  // Por simplicidade, este exemplo só mostra a configuração.
  TTaskExtensions.ContinueWith(Task1,
    procedure
    begin
      LogMemo.Lines.Add('-> Continuação Task 1: Executada (NotOnCompleted)');
    end,
    [NotOnCompleted]
  );

  // Lógica para esperar que as tasks de teste terminem (e suas continuações)
  TTask.Run(
    procedure
    begin
      Task1.Wait; // Espera a task original 1
      Task2.Wait; // Espera a task original 2

      // Esperar pelas continuações também se necessário, ou deixá-las rodar
      // (as continuações são ITask, então PPL gerencia).
      // Mas para garantir o cleanup da UI, esperamos as tasks principais.

      TThread.Queue(nil,
        procedure
        begin
          LogMemo.Lines.Add('--- Teste ITask ContinueWith Concluído ---');
          SetButtonsEnabled(True);
        end
      );
    end
  );
end;

procedure TMainForm.IniciarFutureContinueWithButtonClick(Sender: TObject);
var
  Future1: IFuture<Integer>;
  Future2: IFuture<Integer>;
begin
  SetButtonsEnabled(False);
  LogMemo.Lines.Add('--- Testando IFuture com ContinueWith ---');
  LogMemo.Lines.Add(Format('Forçar Exceção para Future 2: %s', [BoolToStr(ForceExceptionCheckBox.Checked, True)]));

  Future1 := TTask.Future<Integer>(
    function: Integer
    begin
      OutputDebugString('Future 1: Iniciando (2s)...' + sLineBreak);
      Sleep(2000);
      OutputDebugString('Future 1: Concluída.' + sLineBreak);
      Result := 10;
    end
  );

  Future2 := TTask.Future<Integer>(
    function: Integer
    begin
      OutputDebugString('Future 2: Iniciando (3s)...' + sLineBreak);
      Sleep(3000);
      if ForceExceptionCheckBox.Checked then
      begin
        raise Exception.Create('Erro simulado na Future 2!');
      end;
      OutputDebugString('Future 2: Concluída.' + sLineBreak);
      Result := -1; // Valor de retorno para falha, se não lançar exceção
    end
  );

  // Exemplo 1: Continuação que executa se Future1 completa com sucesso (recebe o valor)
  TTaskExtensions.ContinueWith<Integer>(Future1,
    procedure(AResult: Integer)
    begin
      LogMemo.Lines.Add(Format('-> Continuação Future 1: Executada (OnlyOnCompleted). Valor: %d', [AResult]));
    end,
    [OnlyOnCompleted]
  );

  // Exemplo 2: Continuação que executa se Future2 falha (recebe o valor retornado se não throw)
  TTaskExtensions.ContinueWith<Integer>(Future2,
    procedure(AResult: Integer)
    begin
      LogMemo.Lines.Add(Format('-> Continuação Future 2: Executada (OnlyOnFaulted). Valor final (se não lançar): %d', [AResult]));
    end,
    [OnlyOnFaulted]
  );

  // Exemplo 3: Continuação que executa se Future1 NÃO completa (e.g., cancelada ou falha)
  // Similar à task, este exemplo só mostra a configuração.
  TTaskExtensions.ContinueWith<Integer>(Future1,
    procedure(AResult: Integer)
    begin
      LogMemo.Lines.Add(Format('-> Continuação Future 1: Executada (NotOnCompleted). Status: %s',
        [GetEnumName(TypeInfo(TTaskStatus), Integer(Future1.Status))]));
    end,
    [NotOnCompleted]
  );

  // Lógica para esperar que as tasks de teste terminem (e suas continuações)
  TTask.Run(
    procedure
    begin
      Future1.Wait; // Espera a future original 1
      Future2.Wait; // Espera a future original 2

      TThread.Queue(nil,
        procedure
        begin
          LogMemo.Lines.Add('--- Teste IFuture ContinueWith Concluído ---');
          SetButtonsEnabled(True);
        end
      );
    end
  );
end;

end.

