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
    // Mutex para garantir que apenas uma inst�ncia da aplica��o possa ser executada
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
  // Um nome �nico para o Mutex, geralmente um GUID para evitar colis�es.
  // Para gerar um GUID no Delphi: Use CTRL+SHIFT+G no editor de c�digo e
  // remova os colchetes [].
  // Exemplo de GUID. SUBSTITUA PELO SEU!
  MUTEX_NAME = '{F72C8429-6803-4D45-B48C-5124B25175F3}';

procedure TMainForm.FormCreate(Sender: TObject);
var
  AlreadyRunning: Boolean;
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplica��o iniciada. Verificando inst�ncia �nica...');

  // Tenta criar (ou abrir) o Mutex
  FAppMutex := TMutex.Create(
    nil,        // nil para atributos de seguran�a padr�o
    True,       // True para posse inicial
    MUTEX_NAME  // Nome �nico do Mutex
  );

  // Se o Mutex j� existir GetLastError retorna ERROR_ALREADY_EXISTS
  AlreadyRunning := GetLastError = ERROR_ALREADY_EXISTS;

  if AlreadyRunning then
  begin
    // Se o Mutex j� existe, a inst�ncia atual do objeto TMutex (FAppMutex)
    // � apenas um "wrapper" local. N�o temos a posse do Mutex do sistema,
    // ent�o n�o devemos chamar Release. Apenas liberamos o nosso objeto wrapper.
    FAppMutex.Free;
    FAppMutex := nil;

    ShowMessage('Outra inst�ncia desta aplica��o j� est� em execu��o.');

    // Evita que o form da segunda inst�ncia apare�a e suma em seguida.
    Application.ShowMainForm := False;

    // O uso de `Application.Terminate` � intencional neste exemplo
    // para encerrar a segunda inst�ncia.
    Application.Terminate;
    // Sai do FormCreate
    Exit;
  end
  else
  begin
    // Se � a primeira inst�ncia, ela mant�m a posse do Mutex at� o FormDestroy
    LogWrite('Esta � a �nica inst�ncia da aplica��o.');
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  // A thread que criou o Mutex deve liber�-lo no final
  // Se AppMutex foi criado e somos a �nica inst�ncia, libere a posse.
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
