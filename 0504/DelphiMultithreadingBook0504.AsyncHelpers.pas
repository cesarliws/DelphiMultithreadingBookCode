unit DelphiMultithreadingBook0504.AsyncHelpers;

interface

uses
  System.Classes, // TNotifyEvent
  System.SysUtils, // TProc, TProcedure,
  DelphiMultithreadingBook0504.MainThreadDispatcher; // TMainThreadDispatcher

// M�todos auxiliares para postar c�digo na Main Thread de forma ass�ncrona
// RunAsync significa "Executar de forma ass�ncrona na Main Thread".
// N�o cria novas threads.
procedure RunAsync(Proc: TProc); overload;
procedure RunAsync(Proc: TProcedure); overload;
procedure RunAsync(Sender: TObject; NotifyEvent: TNotifyEvent); overload;
procedure RunAsync(NotifyEvent: TNotifyEvent); overload;

implementation

procedure RunAsync(Proc: TProc);
begin
  // Despacha o TProc diretamente para a Main Thread via o Dispatcher
  TMainThreadDispatcher.Post(Proc);
end;

procedure RunAsync(Proc: TProcedure);
begin
  // Encapsula TProcedure (que n�o � um m�todo de objeto)
  // Para TProc (m�todo an�nimo)
  TMainThreadDispatcher.Post(
    procedure
    begin
      Proc();
    end);
end;

procedure RunAsync(Sender: TObject; NotifyEvent: TNotifyEvent);
begin
  // Encapsula TNotifyEvent para TProc, capturando Sender
  TMainThreadDispatcher.Post(
    procedure
    begin
      NotifyEvent(Sender);
    end);
end;

procedure RunAsync(NotifyEvent: TNotifyEvent);
begin
  // Encapsula TNotifyEvent para TProc, passando nil para Sender
  TMainThreadDispatcher.Post(
    procedure
    begin
      NotifyEvent(nil);
    end);
end;

end.
