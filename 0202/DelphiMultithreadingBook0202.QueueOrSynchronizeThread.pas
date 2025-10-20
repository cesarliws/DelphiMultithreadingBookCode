unit DelphiMultithreadingBook0202.QueueOrSynchronizeThread;

interface

uses
  System.Classes,
  System.SysUtils,
  Vcl.StdCtrls; // TMemo

type
  TInterfaceUpdateType = (
    Queue,
    Synchronize
  );

  TQueueOrSynchronizeThread = class(TThread)
  private
    FInterfaceUpdateType: TInterfaceUpdateType;
    // Refer�ncia ao Memo para demonstrar o problema de acoplamento
    FLogMemoRef: TMemo;
  protected
    procedure Execute; override;
  public
    constructor Create(const LogMemo: TMemo;
      InterfaceUpdateType: TInterfaceUpdateType);
  end;

implementation

uses
  DelphiMultithreadingBook.Utils;

{ TQueueOrSynchronizeThread }

constructor TQueueOrSynchronizeThread.Create(const LogMemo: TMemo;
  InterfaceUpdateType: TInterfaceUpdateType);
begin
  // Inicia a thread imediatamente
  inherited Create(False);
  FreeOnTerminate := True;
  FInterfaceUpdateType := InterfaceUpdateType;
  // Passamos a refer�ncia do Memo (exemplo de acoplamento direto para demonstrar)
  FLogMemoRef := LogMemo;
end;

procedure TQueueOrSynchronizeThread.Execute;
var
  UpdateType: string;
  i: Integer;
begin
  if FInterfaceUpdateType = TInterfaceUpdateType.Queue then
    UpdateType := 'Queue'
  else
    UpdateType := 'Synchronize';

  DebugLogWrite('Thread (%s) iniciada. Simulando trabalho pesado...',
    [UpdateType]);

  // Loop curto para ver as atualiza��es
  for i := 1 to 5 do
  begin
    if Terminated then Break;

    // A cada itera��o, enviamos uma atualiza��o para a UI
    if FInterfaceUpdateType = TInterfaceUpdateType.Queue then
      Queue(
        procedure
        begin
          // AVISO: Acesso direto via FLogMemoRef.Lines.Add() cria acoplamento.
          // Usamos para demonstrar AGORA, mas vamos melhorar depois!
          FLogMemoRef.Lines.Add(Format('Thread (%s): Progresso %d de 5',
            [UpdateType, i]));
        end
      )
      else
        Synchronize(
          procedure
          begin
            // AVISO: Acesso direto via FLogMemoRef.Lines.Add() cria acoplamento.
            // Usamos para demonstrar AGORA, mas vamos melhorar depois!
            FLogMemoRef.Lines.Add(Format('Thread (%s): Progresso %d de 5',
              [UpdateType, i]));
          end
        );

    // Pausa de 1 segundo para vermos o progresso
    Sleep(1000);
  end;

  // S� se a thread n�o foi terminada prematuramente
  if not Terminated then
  begin
    if FInterfaceUpdateType = TInterfaceUpdateType.Queue then
      Queue(
        procedure
        begin
          FLogMemoRef.Lines.Add(Format('Thread (%s) conclu�da!', [UpdateType]));
        end
      )
    else
      Synchronize(
        procedure
        begin
          FLogMemoRef.Lines.Add(Format('Thread (%s) conclu�da!', [UpdateType]));
        end
      );
  end
  else
  begin
    DebugLogWrite('Thread (%s) terminada prematuramente.', [UpdateType]);
  end;
end;

end.
