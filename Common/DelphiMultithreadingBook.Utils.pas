unit DelphiMultithreadingBook.Utils;

interface

uses
  System.Classes;

type
{$SCOPEDENUMS OFF}
  TRunningState = (IsRunning, IsPaused, IsStopped);
{$SCOPEDENUMS ON}

  /// <summary>
  ///   Define a assinatura padr�o para os callbacks de log usados nos exemplos.
  /// </summary>
  /// <remarks>
  ///   Este tipo � centralizado aqui na unit de utilit�rios para garantir um
  ///   padr�o consistente em todo o livro. Threads de trabalho receber�o um
  ///   procedimento an�nimo ou m�todo com esta assinatura para poderem
  ///   reportar mensagens de volta para a thread principal de forma segura
  ///   e desacoplada.
  /// </remarks>
  TLogWriteCallback = reference to procedure(const text: string);

// LogWrite envia Text para o LogMemo
procedure LogWrite(const Text: string); overload;
procedure LogWrite(const Text: string; const Args: array of const); overload;

// DebugLogWrite envia Text para a Janela de mensagens de Debug do Delphi
procedure DebugLogWrite(const Text: string); overload;
procedure DebugLogWrite(const Text: string; const Args: array of const); overload;

// Registrar e Desregistrar o MemoLog.Lines que receber� as mensagens de log
procedure RegisterLogger(const Logger: TStrings);
procedure UnregisterLogger;

// Fun��o auxiliar para identificar a primeira chamada a PPL e notificar sobre o Warmup
function CheckTasksFirstRun(WriteLog: Boolean): Boolean;

// Simular processamento de CPU
function SimulateCPUWork(Value: Integer = 0): Int64;

implementation

uses
{$IFDEF MSWINDOWS}
  WinApi.Windows,
{$ENDIF}
  System.SysUtils;

var
  _logger: TStrings;
  _tasksFirstRun: Boolean;

procedure CheckMainThread;
begin
  if TThread.Current.ThreadID <> MainThreadID then
  begin
    raise Exception.Create(
      'Este m�todo s� pode ser chamado a partir da MainThread.');
  end;
end;

procedure RegisterLogger(const Logger: TStrings);
begin
  _logger := Logger;
end;

procedure UnregisterLogger;
begin
  _logger := nil;
end;

function CheckTasksFirstRun(WriteLog: Boolean): Boolean;
begin
  // TODO : adicionar verifica��o real se a thread pool foi inicializada
  if not _tasksFirstRun then
  begin
    _tasksFirstRun := True;
    if WriteLog then
    begin
      LogWrite('*** ATEN��O!');
      LogWrite(
        '* Primeira execu��o mais lenta devido a inicializa��o do Thread Pool');
      LogWrite('* Execute novamente para melhor performance');
    end;
    Result := False;
  end
  else
    Result := True;
end;

function SimulateCPUWork(Value: Integer = 0): Int64;
var
  i: Integer;
  Calc: Double;
begin
  if Value = 0 then
    Calc := Random(100)
  else
    Calc := Value;

  for i := 1 to 50 do
    Calc := Sin(Calc) + Sqrt(Abs(Calc));

  Result := Trunc(Calc);
end;

procedure LogWrite(const Text: string);
begin
  if not Assigned(_logger) then
    Exit;

  if TThread.Current.ThreadID = MainThreadID then
    _logger.Add(Text)
  else
    TThread.Queue(nil,
      procedure
      begin
        if Assigned(_logger) then
          _logger.Add(Text);
      end
    );
end;

procedure LogWrite(const Text: string; const Args: array of const);
begin
   LogWrite(Format(Text, Args));
end;

procedure DebugLogWrite(const Text: string);
begin
  // A fun��o OutputDebugString (da unit WinApi.Windows) nos permite enviar
  // mensagens de texto para a "Events Window" (Janela de Mensagens) do Delphi.
{$IFDEF MSWINDOWS}
  OutputDebugString(PChar(Text + sLineBreak));
{$ENDIF}
end;

procedure DebugLogWrite(const Text: string; const Args: array of const);
begin
  DebugLogWrite(Format(Text, Args));
end;

end.
