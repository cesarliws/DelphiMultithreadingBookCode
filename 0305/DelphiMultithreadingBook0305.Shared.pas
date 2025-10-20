unit DelphiMultithreadingBook0305.Shared;

interface

uses
  System.Classes,
  System.Generics.Collections, // TQueue<string>
  System.SyncObjs, // TCriticalSection, TEvent
  DelphiMultithreadingBook.Utils;

type
  TBaseThread = class(TThread)
  private
    FLogWriteCallback: TLogWriteCallback;
  protected
    procedure CallbackLogWrite(const Text: string); overload;
    procedure CallbackLogWrite(const Text: string;
      const Args: array of const); overload;
  public
    constructor Create(CreateSuspended: Boolean;
      CallbackLogWrite: TLogWriteCallback); reintroduce; virtual;
  end;

var
  // Recursos para o exemplo Produtor-Consumidor
  // Fila de mensagens compartilhada
  MensagensFila: TQueue<string>;
  // Para proteger o acesso à fila
  FilaCriticalSection: TCriticalSection;
  // Evento para sinalizar novos itens na fila
  NovosItensEvent: TEvent;

implementation

uses
  System.SysUtils; // Format

{ TBaseThread }

constructor TBaseThread.Create(CreateSuspended: Boolean; CallbackLogWrite:
  TLogWriteCallback);
begin
  inherited Create(CreateSuspended);
  FLogWriteCallback := CallbackLogWrite;
end;

procedure TBaseThread.CallbackLogWrite(const Text: string);
begin
  DebugLogWrite(Text);
  // Envia log para a UI se foi passado o callback para notificar
  if Assigned(FLogWriteCallback) then
  begin
    // Usamos TThread.Queue para atualizar a UI sem bloquear o processamento
    TThread.Queue(nil,
      procedure
      begin
        FLogWriteCallback(Text);
      end);
  end;
end;

procedure TBaseThread.CallbackLogWrite(const Text: string;
  const Args: array of const);
begin
  CallbackLogWrite(Format(Text, Args));
end;

initialization
  // Inicializa recursos do Produtor-Consumidor
  MensagensFila := TQueue<string>.Create;
  FilaCriticalSection := TCriticalSection.Create;
  // Cria o evento
  NovosItensEvent := TEvent.Create(
    nil,   // EventAttributes = nil
    False, // ManualReset = False (AutoReset)
    False, // InitialState = False (Não Sinalizado)
    '',    // Name = ''
    False  // UseCOMWait = False
  );

finalization
  // Libera o Evento
  NovosItensEvent.Free;
  // Libera a Fila
  MensagensFila.Free;
  FilaCriticalSection.Free;

end.
