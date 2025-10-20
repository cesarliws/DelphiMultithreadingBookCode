unit DelphiMultithreadingBook0301.MainForm;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls;

type
  TMainForm = class(TForm)
    IniciarThreadsComCriticalSectionButton: TButton;
    LogMemo: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure IniciarThreadsComCriticalSectionButtonClick(Sender: TObject);
  end;

var
  MainForm: TMainForm;

implementation

uses
  System.SyncObjs,
  System.SysUtils,
  DelphiMultithreadingBook0301.SharedData, // SharedStringList e Critical Section
  DelphiMultithreadingBook0301.WorkerThread,
  DelphiMultithreadingBook.Utils;

{$R *.dfm}

const
  NUM_THREADS = 5;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplica��o iniciada. Clique nos bot�es para iniciar as threads.');
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  UnregisterLogger;
end;

procedure TMainForm.IniciarThreadsComCriticalSectionButtonClick(Sender: TObject);
var
  i: Integer;
begin
  LogWrite('> Iniciando 5 threads. Aguarde o final da execu��o no LogMemo...');

  // Limpa a lista compartilhada antes de iniciar
  SharedStringListCriticalSection.Enter;
  try
    SharedStringList.Clear;
  finally
    SharedStringListCriticalSection.Leave;
  end;

  // Cria e inicia 5 threads que acessar�o o SharedStringList
  for i := 1 to NUM_THREADS do
    TWorkerThread.Create(i, 20);

  // A thread an�nima abaixo atua como um "relator" que exibir� o resultado final.
  TThread.CreateAnonymousThread(
    procedure
    begin
      // O Sleep(2000) tem um prop�sito did�tico espec�fico: ele pausa o relator
      // para dar tempo suficiente para que todas as threads de trabalho
      // (TWorkerThread) sejam iniciadas pelo sistema operacional e comecem a
      // competir pelo acesso � SharedStringList.

      // ATEN��O: Sleep N�O � uma forma segura de garantir a FINALIZA��O das
      // threads. Ele apenas cria uma janela de tempo para que a concorr�ncia
      // ocorra neste exemplo. A maneira robusta de aguardar a conclus�o de
      // m�ltiplas tarefas ser� vista em t�picos futuros,
      // com TCountdownEvent (3.7) e TTask.WaitForAll (6.4).
      Sleep(2000);

      TThread.Queue(nil,
        procedure
        var
          s: string;
        begin
          LogWrite('');
          LogWrite('----- In�cio do Log do SharedStringList -----');

          // Protege o acesso � lista para leitura
          SharedStringListCriticalSection.Enter;
          try
            for s in SharedStringList do
            begin
              LogWrite(s);
            end;
            LogWrite('Total de itens na lista: %d', [SharedStringList.Count]);
          finally
            SharedStringListCriticalSection.Leave;
          end;

          LogWrite('----------------------------------------');
        end);
    end).Start;
end;

end.
