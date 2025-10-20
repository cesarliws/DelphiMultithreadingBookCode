unit DelphiMultithreadingBook0603.MainForm;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.Samples.Spin,
  System.Threading,   // TParallel.For, TTask, TLoopState
  DelphiMultithreadingBook.CancellationToken,
  DelphiMultithreadingBook.Utils;

type
  TMainForm = class(TForm)
    CalcularPrimosSequencialButton: TButton;
    CalcularPrimosParaleloButton: TButton;
    PararCalculoParaleloButton: TButton;
    StopAfterCheckBox: TCheckBox;
    StopAfterSpinEdit: TSpinEdit;
    LogMemo: TMemo;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

    procedure CalcularPrimosParaleloButtonClick(Sender: TObject);
    procedure CalcularPrimosSequencialButtonClick(Sender: TObject);
    procedure PararCalculoParaleloButtonClick(Sender: TObject);
  private
    // Fonte do CancellationToken para o loop paralelo
    FParallelCancellationTokenSource: TCancellationTokenSource;
    // Refer�ncia para a tarefa paralela principal
    FParallelCalculationTask: ITask;
    // Contador de primos encontrado (protegido por TInterlocked)
    FPrimeCount: Integer;
    procedure CancelParallelForProcessing;
    procedure FinalizeParallelTask;
    function InitializeCancellationToken: ICancellationToken;
    procedure SetButtonStates(RunningState: TRunningState;
      IsParallel: Boolean = False);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.SyncObjs,    // TInterlocked
  System.SysUtils,
  System.Diagnostics, // TStopwatch
  System.Variants;

type
  // Alias para simplificar o c�digo
  TLoopState = TParallel.TLoopState;

const
  // Limite superior para a busca de n�meros primos
  MAX_NUMBER = 10000000;

// Fun��o auxiliar para verificar se � um n�mero primo
function IsPrime(N: Integer): Boolean;
var
  I: Integer;
begin
  if N <= 1 then
    Result := False
  else if N <= 3 then
    Result := True
  else if (N mod 2 = 0) or (N mod 3 = 0) then
    Result := False
  else
  begin
    I := 5;
    Result := True;
    while I * I <= N do
    begin
      if (N mod I = 0) or (N mod (I + 2) = 0) then
      begin
        Result := False;
        Break;
      end;
      I := I + 6;
    end;
  end;
end;

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplica��o iniciada.');
  SetButtonStates(IsStopped);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FinalizeParallelTask;
  UnregisterLogger;
end;

procedure TMainForm.CalcularPrimosSequencialButtonClick(Sender: TObject);
var
  i: Integer;
  PrimeCount: Integer;
  Stopwatch: TStopwatch;
begin
  LogWrite('> Iniciando c�lculo SEQUENCIAL de primos at� %d...', [MAX_NUMBER]);
  LogWrite('UI N�O responsiva durante c�culo SEQUENCIAL.');
  SetButtonStates(IsRunning);

  Stopwatch := TStopwatch.StartNew;
  PrimeCount := 0;
  for i := 1 to MAX_NUMBER do
  begin
    if IsPrime(i) then
      Inc(PrimeCount);
  end;
  Stopwatch.Stop;

  LogWrite('C�lculo SEQUENCIAL conclu�do. Primos encontrados: %d. Tempo: %s ms.',
    [PrimeCount, Stopwatch.ElapsedMilliseconds.ToString]);

  SetButtonStates(IsStopped);
end;

procedure TMainForm.CalcularPrimosParaleloButtonClick(Sender: TObject);
var
  LoopResult: TParallel.TLoopResult;
  StopAfter: Boolean;
  StopAfterValue: Integer;
  Stopwatch: TStopwatch;
  Token: ICancellationToken;
begin
  LogWrite('> Iniciando c�lculo PARALELO de primos at� %d...', [MAX_NUMBER]);
  // Prepara o ambiente para o novo c�lculo
  SetButtonStates(IsRunning, True);

  Token := InitializeCancellationToken;
  StopAfter := StopAfterCheckBox.Checked;
  StopAfterValue := StopAfterSpinEdit.Value;
  Stopwatch := TStopwatch.StartNew;

  // Reinicia o contador de primos
  FPrimeCount := 0;

  // Usa TParallel.For para paralelizar o loop
  // A tarefa principal encapsula o TParallel.For e seu ciclo de vida
  FParallelCalculationTask := TTask.Run(
    // Este m�todo ser� a tarefa principal que encapsula o TParallel.For
    procedure
    begin
      try
        LoopResult := TParallel.For(1, MAX_NUMBER,
          // Index � o n�mero atual no loop
          procedure(Index: Integer; LoopState: TLoopState)
          begin
            if LoopState.ShouldExit then
              Exit;

            // Usa o Token capturado para verifica se o cancelamento foi
            // solicitado por Token: Bot�o "Parar C�lculo"
            if Token.IsCancellationRequested then
            begin
              LogWrite('Paralelo: Itera��o %d CANCELADA por Token.', [Index]);
              // Usa Stop para uma interrup��o mais imediata,
              // j� que foi um cancelamento externo.
              LoopState.Stop;
              // Sai da itera��o atual
              Exit;
            end;

            // Opcional: Parar ap�s encontrar um n�mero X de primos
            // Exemplo: parar ap�s N primos
            if StopAfter and (MainForm.FPrimeCount > StopAfterValue) and
               (not LoopState.Stopped) and (not LoopState.Faulted) then
            begin
              LogWrite(
                'Paralelo: Itera��o %d QUEBRADA por condi��o interna (%d primos)!',
                [Index, MainForm.FPrimeCount]);
              // Usa Break, que � mais "gentil".
              // As itera��es j� em andamento podem terminar.
              LoopState.Break;
              // Sai da itera��o atual
              Exit;
            end;

            if IsPrime(Index) then
            begin
              // O acesso a FPrimeCount deve ser sincronizado!
              // Usamos TInterlocked.Increment, que � uma opera��o at�mica e
              // muito mais eficiente que uma Critical Section para este caso.
              // (Aprenderemos todos os detalhes do TInterlocked no T�pico 7.2).
              TInterlocked.Increment(FPrimeCount);
            end;
          end // Fim do corpo do loop paralelo
        ); // Fim do TParallel.For

      finally
        Stopwatch.Stop;
        // Este bloco � executado na thread do pool,
        // ent�o a UI deve ser atualizada via Queue.
        TThread.Queue(nil,
          procedure
          begin
            // Verifica se o form est� fechando (para evitar AV no shutdown)
            if csDestroying in ComponentState then
              Exit;

            LogWrite('C�lculo PARALELO conclu�do.' +
              ' Primos encontrados: %d. Tempo: %s ms.',
              [FPrimeCount, Stopwatch.ElapsedMilliseconds.ToString]);

            // Verifica o status do LoopResult para informa��es adicionais
            if LoopResult.Completed then
              LogWrite('LoopResult.Completed = True')
            // Verifica se houve interrup��o via Break
            else
            if not VarIsNull(LoopResult.LowestBreakIteration) then
              LogWrite('Loop interrompido internamente em itera��o: %d',
                [Integer(LoopResult.LowestBreakIteration)])
            else
            // Status da tarefa � a fonte de verdade para Canceled/Exception
            if FParallelCalculationTask.Status = TTaskStatus.Canceled then
              LogWrite('C�lculo PARALELO CANCELADO. Status: TTaskStatus.Canceled')
            else
            if FParallelCalculationTask.Status = TTaskStatus.Exception then
              LogWrite('C�lculo PARALELO FALHOU. Status: TTaskStatus.Exception');

            // Reabilita os bot�es e desabilita o bot�o de parar
            SetButtonStates(IsStopped);
            // Limpa a refer�ncia da tarefa principal ap�s ela terminar e ser liberada.
            // O ITask � uma Interface com gerenciamento de mem�ria autom�tico por
            // contagem de refer�ncia (ARC), mas manter a refer�ncia no campo evita
            // que ele seja liberado se o MainForm sair do escopo antes.
            FParallelCalculationTask := nil;
          end);
      end;
    end // Fim da tarefa principal que encapsula o TParallel.For
  ); // Fim do TTask.Run

  LogWrite('Tarefa TParallel.For disparada! UI continua responsiva.');

  CheckTasksFirstRun(True);
end;

procedure TMainForm.PararCalculoParaleloButtonClick(Sender: TObject);
begin
  LogWrite('* Solicitando CANCELAMENTO do c�lculo paralelo...');
  SetButtonStates(IsStopped);
  // Sinaliza o cancelamento
  CancelParallelForProcessing;
end;

procedure TMainForm.SetButtonStates(RunningState: TRunningState;
  IsParallel: Boolean = False);
begin
  if csDestroying in ComponentState then
    Exit;

  CalcularPrimosSequencialButton.Enabled := RunningState = IsStopped;
  CalcularPrimosParaleloButton.Enabled := RunningState = IsStopped;
  PararCalculoParaleloButton.Enabled := (RunningState = IsRunning) and IsParallel;
  StopAfterCheckBox.Enabled := RunningState = IsStopped;
  StopAfterSpinEdit.Enabled := RunningState = IsStopped;

  if IsParallel then
  begin
    PararCalculoParaleloButton.SetFocus;
  end;
  Repaint;
end;

procedure TMainForm.CancelParallelForProcessing;
begin
  // Libera a fonte do CancellationToken ap�s a conclus�o da tarefa
  if Assigned(FParallelCancellationTokenSource) then
  begin
    FParallelCancellationTokenSource.Cancel;
  end;
end;

function TMainForm.InitializeCancellationToken: ICancellationToken;
begin
  if Assigned(FParallelCancellationTokenSource) then
    // Se CancellationToken j� existe � reiniciado
    FParallelCancellationTokenSource.Reset
  else
    // Cria a fonte do CancellationToken para esta nova execu��o
    FParallelCancellationTokenSource := TCancellationTokenSource.Create;
  Result := FParallelCancellationTokenSource.Token;
end;

procedure TMainForm.FinalizeParallelTask;
begin
  // Garante que a tarefa paralela seja terminada e liberada ao fechar o form
  if Assigned(FParallelCalculationTask) then
  begin
    // Sinaliza o cancelamento
    CancelParallelForProcessing;
    // Espera a tarefa terminar (bloqueia, mas � necess�rio para limpeza)
    FParallelCalculationTask.Wait;
    FParallelCalculationTask := nil;
  end;

  // Libera a fonte do CancellationToken se ainda n�o foi liberada
  if Assigned(FParallelCancellationTokenSource) then
  begin
    FParallelCancellationTokenSource.Free;
    FParallelCancellationTokenSource := nil;
  end;
end;

end.
