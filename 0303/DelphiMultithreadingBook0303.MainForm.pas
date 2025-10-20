unit DelphiMultithreadingBook0303.MainForm;

interface

uses
  System.Classes, System.SyncObjs, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls;

type
  TMainForm = class(TForm)
    LogMemo: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    // Mutex para garantir que apenas uma instância da aplicação possa ser executada
    FAppMutex: TMutex;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  Vcl.Dialogs,
  Winapi.Windows,
  DelphiMultithreadingBook.Utils;

const
  // Um nome único para o Mutex, geralmente um GUID para evitar colisões.
  // Para gerar um GUID no Delphi: Use CTRL+SHIFT+G no editor de código e
  // remova os colchetes [].
  // Exemplo de GUID. SUBSTITUA PELO SEU!
  MUTEX_NAME = '{F72C8429-6803-4D45-B48C-5124B25175F3}';

procedure TMainForm.FormCreate(Sender: TObject);
var
  AlreadyRunning: Boolean;
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplicação iniciada. Verificando instância única...');

  // Tenta criar (ou abrir) o Mutex
  FAppMutex := TMutex.Create(
    nil,        // nil para atributos de segurança padrão
    True,       // True para posse inicial
    MUTEX_NAME  // Nome único do Mutex
  );

  // Se o Mutex já existir GetLastError retorna ERROR_ALREADY_EXISTS
  AlreadyRunning := GetLastError = ERROR_ALREADY_EXISTS;

  if AlreadyRunning then
  begin
    // Se o Mutex já existe, a instância atual do objeto TMutex (FAppMutex)
    // é apenas um "wrapper" local. Não temos a posse do Mutex do sistema,
    // então não devemos chamar Release. Apenas liberamos o nosso objeto wrapper.
    FAppMutex.Free;
    FAppMutex := nil;

    ShowMessage('Outra instância desta aplicação já está em execução.');

    // Evita que o form da segunda instância apareça e suma em seguida.
    Application.ShowMainForm := False;

    // O uso de `Application.Terminate` é intencional neste exemplo
    // para encerrar a segunda instância.
    Application.Terminate;
    // Sai do FormCreate
    Exit;
  end
  else
  begin
    // Se é a primeira instância, ela mantém a posse do Mutex até o FormDestroy
    LogWrite('Esta é a única instância da aplicação.');
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  // A thread que criou o Mutex deve liberá-lo no final
  // Se AppMutex foi criado e somos a única instância, libere a posse.
  if Assigned(FAppMutex) then
  begin
    // Libera a posse do Mutex
    FAppMutex.Release;
    // Libera o objeto TMutex
    FAppMutex.Free;
  end;
  UnregisterLogger;
end;

end.
