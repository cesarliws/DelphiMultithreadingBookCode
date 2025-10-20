unit DelphiMultithreadingBook0802.MainForm;

interface

uses
  System.Classes, System.Threading, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  DelphiMultithreadingBook0802.Worker,
  DelphiMultithreadingBook.Utils;

type
  TMainForm = class(TForm)
    StartNoSyncButton: TButton;
    StartCriticalSectionButton: TButton;
    StartThreadVarButton: TButton;
    LogMemo: TMemo;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

    procedure StartNoSyncButtonClick(Sender: TObject);
    procedure StartCriticalSectionButtonClick(Sender: TObject);
    procedure StartThreadVarButtonClick(Sender: TObject);
  private
    // Campo para controlar a tarefa de teste em execução
    FCurrentTestTask: ITask;
    procedure RunTestAsync(Mode: TExecutionMode; const Title: string);
    procedure SetButtonStates(RunningState: TRunningState);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.Diagnostics,
  System.SysUtils,
  DelphiMultithreadingBook0802.SharedData;

const
  NUM_THREADS = 10;
  INCREMENTS_PER_THREAD = 1000000;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  SetButtonStates(IsStopped);
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not Assigned(FCurrentTestTask);
  if not CanClose then
  begin
    LogWrite('* Aguarde a Tarefa finalizar para fechar esta janela!')
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  UnregisterLogger;
end;

procedure TMainForm.StartCriticalSectionButtonClick(Sender: TObject);
begin
  RunTestAsync(emCriticalSection, 'Iniciando Teste com TCriticalSection');
end;

procedure TMainForm.StartNoSyncButtonClick(Sender: TObject);
begin
  RunTestAsync(emNoSync, 'Iniciando Teste SEM Sincronização (Esperado Falhar)');
end;

procedure TMainForm.StartThreadVarButtonClick(Sender: TObject);
begin
  RunTestAsync(emThreadVar, 'Iniciando Teste com threadvar (Otimizado)');
end;

procedure TMainForm.RunTestAsync(Mode: TExecutionMode; const Title: string);
begin
  if Assigned(FCurrentTestTask) then
  begin
    LogWrite('!!! Um teste já está em execução. Por favor, aguarde. !!!');
    Exit;
  end;

  LogWrite('--- ' + Title + ' ---');
  SetButtonStates(IsRunning);

  // Zera os contadores
  ContadorGlobal := 0;
  ContadorGlobalFinal := 0;

  // Executa o Teste em uma Task (ver Capítulo 6) para não bloquear a UI
  FCurrentTestTask := TTask.Run(
    procedure
    var
      i: Integer;
      ResultadoEsperado: Int64;
      Stopwatch: TStopwatch;
      Threads: TArray<TWorker>;
      FinalValue: Int64;
      ModeResult: TExecutionMode;
    begin
      Stopwatch := TStopwatch.StartNew;
      SetLength(Threads, NUM_THREADS);
      try
        // Cria e inicia as threads
        for i := 0 to High(Threads) do
        begin
          Threads[i] := TWorker.Create(Mode, INCREMENTS_PER_THREAD);
          Threads[i].Start;
        end;

        // Espera todas terminarem (esta espera acontece na thread da PPL, não na UI)
        for i := 0 to High(Threads) do
          Threads[i].WaitFor;

      finally
        // Libera os objetos TThread
        for i := 0 to High(Threads) do
          Threads[i].Free;
      end;

      Stopwatch.Stop;

      // Prepara os resultados para enviar para a UI
      ResultadoEsperado := NUM_THREADS * INCREMENTS_PER_THREAD;
      ModeResult := Mode;
      if Mode = emThreadVar then
        FinalValue := ContadorGlobalFinal
      else
        FinalValue := ContadorGlobal;

      // Envia o resultado final para a UI de forma segura
      TThread.Queue(nil,
        procedure
        begin
          // Proteção caso o formulário seja fechado enquanto a task executa
          if csDestroying in ComponentState then
            Exit;

          if ModeResult = emThreadVar then
          begin
            LogWrite('Concluído. Valor final: %d (Esperado: %d)',
              [FinalValue, ResultadoEsperado]);
            if FinalValue <> ResultadoEsperado then
              LogWrite('>>> OCORREU UM ERRO DE LÓGICA! <<<')
            else
              LogWrite('>>> Resultado correto! <<<');
          end
          else
          begin
            LogWrite('Concluído. Valor final: %d (Esperado: %d)',
              [FinalValue, ResultadoEsperado]);
            if FinalValue <> ResultadoEsperado then
              LogWrite('>>> OCORREU UMA RACE CONDITION! <<<')
            else
              LogWrite('>>> Resultado correto! <<<');
          end;

          LogWrite('Tempo de execução: %s ms',
            [Stopwatch.ElapsedMilliseconds.ToString]);
          LogWrite('');

          // Limpa a referência da tarefa e reabilita os botões
          FCurrentTestTask := nil;
          SetButtonStates(IsStopped);
        end);
    end);
end;

procedure TMainForm.SetButtonStates(RunningState: TRunningState);
begin
  StartNoSyncButton.Enabled := RunningState = IsStopped;
  StartCriticalSectionButton.Enabled := RunningState = IsStopped;
  StartThreadVarButton.Enabled := RunningState = IsStopped;
  Repaint;
end;

end.

