unit DelphiMultithreadingBook0302.MainForm;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls;

type
  // Para não colidir com Vcl.Forms.TMonitor
  TMonitor = System.TMonitor;

  TMainForm = class(TForm)
    IniciarThreadsComMonitorButton: TButton;
    LogMemo: TMemo;
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure IniciarThreadsComMonitorButtonClick(Sender: TObject);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.SysUtils,
  DelphiMultithreadingBook0302.SharedData, // SharedSimpleList e Critical Section
  DelphiMultithreadingBook0302.WorkerThread,
  DelphiMultithreadingBook.Utils;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplicação iniciada. Clique nos botões para iniciar as threads.');
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  UnregisterLogger;
end;

procedure TMainForm.IniciarThreadsComMonitorButtonClick(Sender: TObject);
var
  i: Integer;
begin
  LogWrite('> Iniciando 5 Threads com TMonitor...');
  // Limpa a lista protegida pelo TMonitor
  // Protege o acesso à lista para limpeza
  TMonitor.Enter(SharedSimpleList);
  try
    SharedSimpleList.Clear;
  finally
    TMonitor.Exit(SharedSimpleList);
  end;

  // Cria e inicia 5 threads que acessarão a SharedSimpleList
  for i := 1 to 5 do
  begin
    // Cria 5 threads, cada uma adicionando 20 itens
    TWorkerThread.Create(i, 20);
  end;

  // Adiciona uma thread para mostrar o resultado final da lista após um tempo
  TThread.CreateAnonymousThread(
    procedure
    begin
      // O Sleep a seguir tem um propósito didático: ele pausa esta thread
      // "relatora" para dar tempo suficiente para que as threads de trabalho
      // (TWorkerThread) // executem e a concorrência pelo recurso aconteça.
      // Em uma aplicação real, a forma correta de aguardar a conclusão de
      // múltiplas tarefas seria usar primitivas de sincronização como
      // TCountdownEvent (Tópico 3.7).
      Sleep(2000);
      TThread.Queue(nil,
        procedure
        var
          s: string;
        begin
          LogWrite('');
          LogWrite('--- Conteúdo final do SharedSimpleList (TMonitor) ---');
          // Protege o acesso à lista para leitura
          TMonitor.Enter(SharedSimpleList);
          try
            for s in SharedSimpleList do
            begin
              LogWrite(s);
            end;
            LogWrite('Total de itens na lista: %d', [SharedSimpleList.Count]);
          finally
            TMonitor.Exit(SharedSimpleList);
          end;
          LogWrite('----------------------------------------');
        end
      );
    end
  ).Start;
end;

end.
