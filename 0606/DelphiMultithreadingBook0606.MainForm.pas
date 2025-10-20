unit DelphiMultithreadingBook0606.MainForm;

interface

uses
  System.Classes, System.SysUtils, System.Threading,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  DelphiMultithreadingBook.Utils;

type
  TMainForm = class(TForm)
    OrdenarArraySequencialButton: TButton;
    OrdenarArrayParaleloButton: TButton;
    ProcessarArraySequencialButton: TButton;
    ProcessarArrayParaleloButton: TButton;
    LogMemo: TMemo;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

    procedure OrdenarArraySequencialButtonClick(Sender: TObject);
    procedure OrdenarArrayParaleloButtonClick(Sender: TObject);
    procedure ProcessarArraySequencialButtonClick(Sender: TObject);
    procedure ProcessarArrayParaleloButtonClick(Sender: TObject);
  private
    // Array para ordenação
    FBigIntegerArray: TArray<Integer>;
    // Array para processamento
    FBigStringArray: array of string;
    // TArray<string> não funciona, bug! passa valores errados em AValues
    // FBigStringArray: TArray<string>;
    FBenchmarkTask: ITask;
    function CopyBigIntegerArray: TArray<Integer>;
    procedure PopulateBigIntegerArray(Size: Integer);
    procedure PopulateBigStringArray(Size: Integer);
    procedure RunBenchmark(const BenchmarkName: string; BenchmarkProc: TProc);
    procedure SetButtonStates(RunningState: TRunningState);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.Diagnostics, // TStopwatch;
  System.Generics.Collections, // TArray.Sort<T>
  System.SyncObjs; // TParallelArray

const
  // 10 milhões para inteiros
  INTEGER_ARRAY_SIZE = 10000000;
  // 10 milhões para strings
  STRING_ARRAY_SIZE = 10000000;

// Função auxiliar para contar ocorrências de um caracter na string
function CountCharInString(const S: string; CharToCount: Char): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to Length(S) do
    if S[i] = CharToCount then
      Inc(Result);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplicação iniciada.');

  PopulateBigIntegerArray(INTEGER_ARRAY_SIZE);
  LogWrite('Array de Inteiros populado com %d itens.', [Length(FBigIntegerArray)]);

  PopulateBigStringArray(STRING_ARRAY_SIZE);
  LogWrite('Array de Strings populado com %d itens.', [Length(FBigStringArray)]);
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not Assigned(FBenchmarkTask);
  if not CanClose then
  begin
    LogWrite('* Aguarde o processamento finalizar para fechar esta Janela!')
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  UnregisterLogger;
end;

procedure TMainForm.PopulateBigIntegerArray(Size: Integer);
var
  i: Integer;
begin
  SetLength(FBigIntegerArray, Size);
  Randomize;
  for i := 0 to High(FBigIntegerArray) do
    // Preenche com números aleatórios
    FBigIntegerArray[i] := Random(Size);
end;

procedure TMainForm.PopulateBigStringArray(Size: Integer);
var
  i, j: Integer;
  S: string;
begin
  SetLength(FBigStringArray, Size);
  Randomize;
  for i := 0 to High(FBigStringArray) do
  begin
    // Gera strings aleatórias simples para o exemplo
    // Strings de 5 a 24 caracteres
    SetLength(S, Random(20) + 5);
    for j := 1 to Length(S) do
      // Letras maiúsculas A-Z
      S[j] := Chr(65 + Random(26));

    FBigStringArray[i] := S;
  end;
end;

procedure TMainForm.OrdenarArraySequencialButtonClick(Sender: TObject);
var
  TempArray: TArray<Integer>;
begin
  // Cria uma cópia para não afetar o array original
  TempArray := CopyBigIntegerArray;
  RunBenchmark('Ordenação SEQUENCIAL',
    procedure
    begin
      // Ordenação sequencial (da RTL)
      TArray.Sort<Integer>(TempArray);
    end);
end;

procedure TMainForm.OrdenarArrayParaleloButtonClick(Sender: TObject);
var
  TempArray: TArray<Integer>;
begin
  // Cria uma cópia para não afetar o array original
  TempArray := CopyBigIntegerArray;
  RunBenchmark('Ordenação PARALELA (TParallelArray.Sort)',
    procedure
    begin
      CheckTasksFirstRun(True);
      // Ordenação paralela (da PPL)
      TParallelArray.Sort<Integer>(TempArray);
    end);
end;

procedure TMainForm.ProcessarArraySequencialButtonClick(Sender: TObject);
var
  TotalAChars: Integer; // Mova a variável para fora para ser capturada
begin
  RunBenchmark('Processamento SEQUENCIAL de strings',
    procedure
    var
      CurrentString: string;
      i: Integer;
    begin
      TotalAChars := 0;
      for i := 0 to High(FBigStringArray) do
      begin
        CurrentString := UpperCase(FBigStringArray[i]);
        Inc(TotalAChars, CountCharInString(CurrentString, 'A'));
      end;
      LogWrite('Total de "A"s encontrados: %d', [TotalAChars]);
    end);
end;

procedure TMainForm.ProcessarArrayParaleloButtonClick(Sender: TObject);
var
  TotalAChars: Integer; // Mova a variável para fora para ser capturada
begin
  RunBenchmark('Processamento PARALELO de strings (TParallelArray.For)',
    procedure
    begin
      CheckTasksFirstRun(True);
      TotalAChars := 0;
      TParallelArray.For<string>(FBigStringArray,
        procedure(const Values: array of string; First, Last: NativeInt)
        var
          i: NativeInt;
          CurrentString: string;
          CountA: Integer;
        begin
          for i := First to Last do
          begin
            CurrentString := UpperCase(Values[i]);
            CountA := CountCharInString(CurrentString, 'A');
            TInterlocked.Add(TotalAChars, CountA);
          end;
        end);
      LogWrite('Total de "A"s encontrados: %d', [TotalAChars]);
    end);
end;

procedure TMainForm.RunBenchmark(const BenchmarkName: string;
  BenchmarkProc: TProc);
begin
  if Assigned(FBenchmarkTask) then
  begin
    LogWrite('Aguarde a finalização do benchmark anterior.');
    Exit;
  end;

  LogWrite('-----------------------------------------------------');
  LogWrite('> Iniciando benchmark: %s...', [BenchmarkName]);
  SetButtonStates(IsRunning);
  // Força a atualização da UI antes de iniciar a task
  Repaint;

  FBenchmarkTask := TTask.Run(
    procedure
    var
      Stopwatch: TStopwatch;
    begin
      Stopwatch := TStopwatch.StartNew;
      try
        // Executa o benchmark (sequencial ou paralelo) em background
        BenchmarkProc;
      finally
        Stopwatch.Stop;
        // Enfileira o resultado para a UI
        TThread.Queue(nil,
          procedure
          begin
            LogWrite('%s concluído. Tempo: %d ms.',
              [BenchmarkName, Stopwatch.ElapsedMilliseconds]);
            SetButtonStates(IsStopped);
            // Libera a referência para o próximo teste
            FBenchmarkTask := nil;
            Repaint;
          end);
      end;
    end);
end;

function TMainForm.CopyBigIntegerArray: TArray<Integer>;
begin
  SetLength(Result, Length(FBigIntegerArray));
  TArray.Copy<Integer>(FBigIntegerArray, Result, Length(FBigIntegerArray));
end;

procedure TMainForm.SetButtonStates(RunningState: TRunningState);
begin
  OrdenarArraySequencialButton.Enabled := RunningState = IsStopped;
  OrdenarArrayParaleloButton.Enabled := RunningState = IsStopped;
  ProcessarArraySequencialButton.Enabled := RunningState = IsStopped;
  ProcessarArrayParaleloButton.Enabled := RunningState = IsStopped;
  Repaint;
end;

end.
