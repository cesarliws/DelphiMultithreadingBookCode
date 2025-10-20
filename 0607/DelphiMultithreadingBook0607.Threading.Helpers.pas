unit DelphiMultithreadingBook0607.Threading.Helpers;

interface

uses
  System.Classes, // Para TProc
  System.SysUtils, // Para Exception, Format
  System.Threading; // Para ITask, IFuture, TTaskStatus

type
  // Define TProc<T> para receber o resultado da Future
  TProcResult<T> = reference to procedure(const AResult: T);
  // Define TProcException para receber a exceção em caso de falha
  TProcException = reference to procedure(const AException: Exception);

  // Nova classe para métodos auxiliares da PPL
  // Esta classe conterá os métodos 'Then' como métodos estáticos
  TTaskExtensions = class
  public
    // Método para encadear uma ação após a conclusão da ITask (sem retorno)
    class procedure &Then(const ATask: ITask; const OnComplete: TProc; const
      OnError: TProcException = nil; const OnCancel: TProc = nil); overload; static;

    // Método para encadear uma ação após a conclusão da IFuture<T> (com retorno)
    class procedure &Then<T>(const AFuture: IFuture<T>; const OnComplete:
      TProcResult<T>; const OnError: TProcException = nil; const OnCancel:
      TProc = nil); overload; static;
  end;

type
  TAction<T> = reference to procedure(const arg: T);

  TTaskContinuationOptions = (
    NotOnCompleted,
    NotOnFaulted,
    NotOnCanceled,
    OnlyOnCompleted,
    OnlyOnFaulted,
    OnlyOnCanceled
  );

  ITaskEx = interface(ITask)
    ['{3AE1A614-27AA-4B5A-BC50-42483650E20D}']
    function GetExceptObj: Exception;
    function GetStatus: TTaskStatus;
    function ContinueWith(const continuationAction: TAction<ITaskEx>;
      continuationOptions: TTaskContinuationOptions): ITaskEx;

    property ExceptObj: Exception read GetExceptObj;
    property Status: TTaskStatus read GetStatus;
  end;

  TTaskEx = class(TTask, ITaskEx)
  private
    fExceptObj: Exception;
    function GetExceptObj: Exception;
  protected
    function ContinueWith(const continuationAction: TAction<ITaskEx>;
      continuationOptions: TTaskContinuationOptions): ITaskEx;
  public
    destructor Destroy; override;

    class function Run(const action: TProc): ITaskEx; static;
  end;

{
  TTaskEx.Run(
    procedure
    begin
      Sleep(2000);
      raise EProgrammerNotFound.Create('whoops')
    end)
    .ContinueWith(
    procedure(const t: ITaskEx)
    begin
      TThread.Queue(nil,
        procedure
        begin
          ShowMessage(t.ExceptObj.Message);
        end);
    end, OnlyOnFaulted);
}


implementation

uses
  WinApi.Windows;

{ TTaskExtensions }

class procedure TTaskExtensions.&Then(const ATask: ITask; const OnComplete: TProc;
  const OnError: TProcException; const OnCancel: TProc);
var
  CurrentTask: ITask; // Captura a referência para evitar ciclo
begin
  CurrentTask := ATask;

  // Cria uma nova TTask no pool para aguardar a conclusão da Future original
  TTask.Run(
    procedure
    begin
      try
        CurrentTask.Wait; // Espera pela conclusão da Task original (bloqueia esta task do pool)
      except
        // Captura exceções do CurrentFuture.Wait para que o OnError possa ser chamado
        on E: Exception do
        begin
          // A exceção será tratada no OnError (se atribuído)
        end;
      end;

      // Despacha o resultado para a Main Thread
      TThread.Queue(nil,
        procedure
        begin
          try
            case CurrentTask.Status of
              TTaskStatus.Completed:
                if Assigned(OnComplete) then
                  OnComplete();
              TTaskStatus.Canceled:
                if Assigned(OnCancel) then
                  OnCancel();
              TTaskStatus.Exception:
                if Assigned(OnError) then
                begin
//                OnError(CurrentTask.Exception); // CurrentTask.Exception é seguro após Wait
                end;
            end;
          except
            on E: Exception do
            begin
              OutputDebugString(PChar(Format('Erro inesperado no handler Then da UI: %s%s', [E.Message, sLineBreak])));
            end;
          end;
        end
      );
    end
  );
end;

class procedure TTaskExtensions.&Then<T>(const AFuture: IFuture<T>; const
  OnComplete: TProcResult<T>; const OnError: TProcException; const OnCancel: TProc);
var
  CurrentFuture: IFuture<T>; // Captura a Future tipada
begin
  CurrentFuture := AFuture;

  TTask.Run(
    procedure
    begin
      try
        CurrentFuture.Wait; // Espera pela conclusão
      except
        on E: Exception do
        begin
          // A exceção será tratada no OnError (se atribuído)
        end;
      end;

      TThread.Queue(nil,
        procedure
        begin
          try
            case CurrentFuture.Status of
              TTaskStatus.Completed:
                if Assigned(OnComplete) then
                  OnComplete(CurrentFuture.Value); // Passa o resultado para o callback
              TTaskStatus.Canceled:
                if Assigned(OnCancel) then
                  OnCancel();
              TTaskStatus.Exception:
                if Assigned(OnError) then
                begin
//                OnError(CurrentFuture.Exception);
                end;
            end;
          except
            on E: Exception do
            begin
              OutputDebugString(PChar(Format('Erro inesperado no handler Then da UI (tipado): %s%s', [E.Message, sLineBreak])));
            end;
          end;
        end
      );
    end
  );
end;

{ TTaskEx }

function TTaskEx.ContinueWith(const continuationAction: TAction<ITaskEx>;
  continuationOptions: TTaskContinuationOptions): ITaskEx;
begin
  Result := TTaskEx.Run(
    procedure
    var
      task: ITaskEx;
      doContinue: Boolean;
    begin
      task := Self;
      if not IsComplete then
        DoneEvent.WaitFor;
      fExceptObj := GetExceptionObject;
      case continuationOptions of
        NotOnCompleted:  doContinue := GetStatus <> TTaskStatus.Completed;
        NotOnFaulted:    doContinue := GetStatus <> TTaskStatus.Exception;
        NotOnCanceled:   doContinue := GetStatus <> TTaskStatus.Canceled;
        OnlyOnCompleted: doContinue := GetStatus = TTaskStatus.Completed;
        OnlyOnFaulted:   doContinue := GetStatus = TTaskStatus.Exception;
        OnlyOnCanceled:  doContinue := GetStatus = TTaskStatus.Canceled;
      else
        doContinue := False;
      end;
      if doContinue then
        continuationAction(task);
    end);
end;

destructor TTaskEx.Destroy;
begin
  fExceptObj.Free;
  inherited;
end;

function TTaskEx.GetExceptObj: Exception;
begin
  Result := fExceptObj;
end;

class function TTaskEx.Run(const action: TProc): ITaskEx;
var
  task: TTaskEx;
begin
  task := TTaskEx.Create(nil, TNotifyEvent(nil), action, TThreadPool.Default, nil);
  Result := task.Start as ITaskEx;
end;

end.
