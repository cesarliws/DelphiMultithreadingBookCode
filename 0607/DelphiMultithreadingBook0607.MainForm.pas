unit DelphiMultithreadingBook0607.MainForm;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Forms, Vcl.StdCtrls,
  System.Threading, Vcl.Controls,
  Vcl.Dialogs, Deep.Threading.Helpers;
//DelphiMultithreadingBook0607.Threading.BasicHelpers; // Importa o helper

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
    FCurrentTestTask: ITask; // Para gerenciar a task atualmente em teste
    FCurrentTestFuture: IFuture<Integer>; // Para gerenciar a future atualmente em teste

    FTestException: Exception; // Para gerenciar exce��es adquiridas
    procedure SetButtonsEnabled(Enabled: Boolean);
    function SimulateWorkAndMaybeError(const TaskName: string; SimulateError: Boolean; Iterations: Integer): Integer;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.TypInfo; // Para GetEnumName

procedure TMainForm.FormCreate(Sender: TObject);
begin
  LogMemo.Lines.Add('Aplica��o iniciada.');
  SetButtonsEnabled(True); // Garante que os bot�es comecem habilitados
  ForceExceptionCheckBox.Checked := True; // Padr�o para testar erro
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  // Garante que todas as tasks/futures em execu��o sejam canceladas e liberadas
  if Assigned(FCurrentTestTask) and (FCurrentTestTask.Status = TTaskStatus.Running) then
  begin
    FCurrentTestTask.Cancel;
    FCurrentTestTask.Wait;
  end;
  FCurrentTestTask := nil;

  if Assigned(FCurrentTestFuture) and (FCurrentTestTask.Status = TTaskStatus.Running) then
  begin
    FCurrentTestFuture.Cancel;
    FCurrentTestFuture.Wait;
  end;
  FCurrentTestFuture := nil;

  // Libera exce��es capturadas
  if Assigned(FTestException) then
  begin
    FTestException.Free;
    FTestException := nil;
  end;
end;

procedure TMainForm.SetButtonsEnabled(Enabled: Boolean);
begin
  IniciarTaskOnCompleteOnErrorButton.Enabled := Enabled;
  IniciarFutureOnCompleteOnErrorButton.Enabled := Enabled;
  IniciarTaskContinueWithButton.Enabled := Enabled;
  IniciarFutureContinueWithButton.Enabled := Enabled;
  ForceExceptionCheckBox.Enabled := Enabled;
  FCurrentTestTask := nil;
end;

function TMainForm.SimulateWorkAndMaybeError(const TaskName: string; SimulateError: Boolean; Iterations: Integer): Integer;
var
  i: Integer;
  Sum: Integer;
begin
  Sum := 0;
  OutputDebugString(PChar(Format('%s: Iniciando trabalho (%d itera��es)...%s', [TaskName, Iterations, sLineBreak])));
  try
    for i := 1 to Iterations do
    begin
      TTask.CurrentTask.CheckCanceled;
      Inc(Sum);
      if SimulateError and (Random(1000000) = 0) then // Chance de 1 em 1 milh�o
      begin
        raise Exception.Create(Format('Erro simulado em %s na itera��o %d!', [TaskName, i]));
      end;
      // Sleep(1); // Opcional para simular mais pausas
    end;
    Result := Sum;
    OutputDebugString(PChar(Format('%s: Trabalho conclu�do (Sum: %d).%s', [TaskName, Sum, sLineBreak])));
  except
    on E: Exception do
    begin
      OutputDebugString(PChar(Format('%s: Exce��o capturada: %s%s', [TaskName, E.Message, sLineBreak])));
      raise; // Re-lan�a para que a ITask/IFuture registre a falha
    end;
  end;
end;


procedure TMainForm.IniciarTaskOnCompleteOnErrorButtonClick(Sender: TObject);
var
  TestTask: ITask;
begin
  SetButtonsEnabled(False);
  LogMemo.Lines.Add('--- Testando ITask com OnComplete/OnException ---');

  TestTask := TTask.Run(
    procedure // Corpo da task
    begin
      SimulateWorkAndMaybeError('Task OnComplete/OnError', ForceExceptionCheckBox.Checked, 20000000); // 20M itera��es
    end
  );
  FCurrentTestTask := TestTask; // Salva a refer�ncia para cleanup

//   Define os handlers usando TTaskExtensions
//TTaskExtensions.OnComplete(TestTask,
//  procedure // Sucesso
//  begin
//    LogMemo.Lines.Add(Format('ITask OnComplete: Tarefa conclu�da com Status: %s',
//      [GetEnumName(TypeInfo(TTaskStatus), Integer(TestTask.Status))]));
//    SetButtonsEnabled(True);
//  end
//);
//
//TTaskExtensions.OnException(TestTask,
//  procedure(const AException: Exception) // Falha
//  begin
//    LogMemo.Lines.Add(Format('ITask OnException: Tarefa falhou com erro: %s', [AException.Message]));
//       A exce��o j� foi adquirida e ser� liberada pelo helper
//    SetButtonsEnabled(True);
//  end
//);
//
//TTaskExtensions.ContinueWith(TestTask, // Teste OnCancel via ContinueWith simples
//  procedure
//  begin
//    LogMemo.Lines.Add(Format('ITask OnCancel via ContinueWith: Status: %s',
//      [GetEnumName(TypeInfo(TTaskStatus), Integer(TestTask.Status))]));
//    SetButtonsEnabled(True);
//  end,
//  [OnlyOnCanceled]
//);
end;


procedure TMainForm.IniciarFutureOnCompleteOnErrorButtonClick(Sender: TObject);
var
  TestFuture: IFuture<Integer>;
begin
  SetButtonsEnabled(False);
  LogMemo.Lines.Add('--- Testando IFuture com OnComplete/OnException ---');

  TestFuture := TTask.Future<Integer>(
    function: Integer // Corpo da future
    begin
      Result := SimulateWorkAndMaybeError('Future OnComplete/OnException', ForceExceptionCheckBox.Checked, 50000000); // 50M itera��es
    end
  );
  FCurrentTestFuture := TestFuture; // Salva a refer�ncia

  // Define os handlers usando TTaskExtensions
//TTaskExtensions.OnComplete<Integer>(TestFuture,
//  procedure(const AResult: Integer) // Sucesso, com resultado
//  begin
//    LogMemo.Lines.Add(Format('IFuture OnComplete: Tarefa conclu�da. Resultado: %d. Status: %s',
//      [AResult, GetEnumName(TypeInfo(TTaskStatus), Integer(TestFuture.Status))]));
//    SetButtonsEnabled(True);
//  end
//);
//
//TTaskExtensions.OnException<Integer>(TestFuture,
//  procedure(const AException: Exception) // Falha, com exce��o
//  begin
//    LogMemo.Lines.Add(Format('IFuture OnException: Tarefa falhou com erro: %s', [AException.Message]));
//    SetButtonsEnabled(True);
//  end
//);
//
//TTaskExtensions.ContinueWith<Integer>(TestFuture, // Teste OnCancel via ContinueWith simples
//  procedure(const AResult: Integer)
//  begin
//    LogMemo.Lines.Add(Format('IFuture OnCancel via ContinueWith: Status: %s',
//      [GetEnumName(TypeInfo(TTaskStatus), Integer(TestFuture.Status))]));
//    SetButtonsEnabled(True);
//  end,
//  [OnlyOnCanceled]
//);
end;

procedure TMainForm.IniciarTaskContinueWithButtonClick(Sender: TObject);
var
  Task1: ITask;
  Task2: ITask;
begin
  SetButtonsEnabled(False);
  LogMemo.Lines.Add('--- Testando ITask com ContinueWith ---');
  LogMemo.Lines.Add('Task 1: Apenas sucesso');
  LogMemo.Lines.Add('Task 2: Falha (se ForceException ativado)');

  Task1 := TTask.Run(
    procedure // Task 1: sempre completa
    begin
      OutputDebugString('Task 1: Iniciando (2s)...' + sLineBreak);
      Sleep(2000);
      OutputDebugString('Task 1: Conclu�da.' + sLineBreak);
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
      OutputDebugString('Task 2: Conclu�da.' + sLineBreak);
    end
  );

  // Exemplo 1: Continua��o que executa apenas se Task1 completa com sucesso
//Task1 := TTaskExtensions.ContinueWith(Task1,
//  procedure
//  begin
//    LogMemo.Lines.Add('-> Continua��o Task 1: Executada (OnlyOnCompleted)');
//  end,
//  [OnlyOnCompleted]
//);
//
//// Exemplo 2: Continua��o que executa apenas se Task2 falha
//Task2 := TTaskExtensions.ContinueWith(Task2,
//  procedure
//  begin
//    LogMemo.Lines.Add('-> Continua��o Task 2: Executada (OnlyOnFaulted)');
//  end,
//  [OnlyOnFaulted]
//);
//
//// Exemplo 3: Continua��o que executa se Task1 N�O completa com sucesso (e.g., cancelada)
//Task1 := TTaskExtensions.ContinueWith(Task1, // Usemos Task1, mas o cancelamento deve vir de fora
//  procedure
//  begin
//    LogMemo.Lines.Add('-> Continua��o Task 1: Executada (NotOnCompleted)');
//    // Simular cancelamento para testar NotOnCompleted
//    Task1.Cancel; // Isso n�o afeta a Continua��o rec�m-criada, mas sim a task original
//  end,
//  [NotOnCompleted]
//);
//
//// L�gica para esperar que as tasks de teste terminem
//TTask.Run(
//  procedure
//  begin
//    Task1.Wait; // Espera a continua��o de Task1
//    Task2.Wait; // Espera a continua��o de Task2
//    TThread.Queue(nil,
//      procedure
//      begin
//        LogMemo.Lines.Add('--- Teste ITask ContinueWith Conclu�do ---');
//        SetButtonsEnabled(True);
//      end
//    );
//  end
//);
end;

procedure TMainForm.IniciarFutureContinueWithButtonClick(Sender: TObject);
var
  Future1: IFuture<Integer>;
  Future2: IFuture<Integer>;
  F: IFutureEx<Integer>;
begin
  F := TTask.Async<Integer>(
      function: Integer
      begin
        Sleep(1000);
        Result := 42;
      end)
    .WithTimeout(2000)
    .OnComplete(
       procedure(const Value: Integer)
       begin
         ShowMessage('Result: ' + Value.ToString);
       end)
    .OnException(
       procedure(const E: Exception)
       begin
         ShowMessage('Error: ' + E.Message);
       end)
    .Start;

  Exit;

  SetButtonsEnabled(False);
  LogMemo.Lines.Add('--- Testando IFuture com ContinueWith ---');
  LogMemo.Lines.Add('Future 1: Sucesso (retorna 10)');
  LogMemo.Lines.Add('Future 2: Falha (se ForceException ativado, retorna -1)');

  Future1 := TTask.Future<Integer>(
    function: Integer
    begin
      OutputDebugString('Future 1: Iniciando (2s)...' + sLineBreak);
      Sleep(2000);
      OutputDebugString('Future 1: Conclu�da.' + sLineBreak);
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
      OutputDebugString('Future 2: Conclu�da.' + sLineBreak);
      Result := -1;
    end
  );

  // Exemplo 1: Continua��o que executa se Future1 completa com sucesso (recebe o valor)
//Future1 := TTaskExtensions.ContinueWith<Integer>(Future1,
//  procedure(const AResult: Integer)
//  begin
//    LogMemo.Lines.Add(Format('-> Continua��o Future 1: Executada (OnlyOnCompleted). Valor: %d', [AResult]));
//  end,
//  [OnlyOnCompleted]
//);
//
//// Exemplo 2: Continua��o que executa se Future2 falha (recebe o valor que causou a falha, ou -1)
//Future2 := TTaskExtensions.ContinueWith<Integer>(Future2,
//  procedure(const AResult: Integer)
//  begin
//    LogMemo.Lines.Add(Format('-> Continua��o Future 2: Executada (OnlyOnFaulted). Valor retornado (em caso de falha): %d', [AResult]));
//  end,
//  [OnlyOnFaulted]
//);
//
//// L�gica para esperar que as tasks de teste terminem
//TTask.Run(
//  procedure
//  begin
//    Future1.Wait; // Espera a continua��o de Future1
//    Future2.Wait; // Espera a continua��o de Future2
//    TThread.Queue(nil,
//      procedure
//      begin
//        LogMemo.Lines.Add('--- Teste IFuture ContinueWith Conclu�do ---');
//        SetButtonsEnabled(True);
//      end
//    );
//  end
//);
end;

end.
