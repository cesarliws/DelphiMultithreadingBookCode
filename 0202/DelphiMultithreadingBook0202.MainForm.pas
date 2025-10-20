unit DelphiMultithreadingBook0202.MainForm;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls;

type
  TMainForm = class(TForm)
    IniciarThreadQueueButton: TButton;
    IniciarThreadSynchronizeButton: TButton;
    LogMemo: TMemo;

    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure IniciarThreadQueueButtonClick(Sender: TObject);
    procedure IniciarThreadSynchronizeButtonClick(Sender: TObject);
  end;

var
  MainForm: TMainForm;

implementation

uses
  DelphiMultithreadingBook0202.QueueOrSynchronizeThread,
  DelphiMultithreadingBook.Utils;

{$R *.dfm}

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  LogWrite('Aplicação iniciada. Clique nos botões para iniciar as threads.');
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  UnregisterLogger;
end;

procedure TMainForm.IniciarThreadQueueButtonClick(Sender: TObject);
begin
  // Criamos uma instância da nossa thread,
  // passando o LogMemo e indicando para usar Queue
  TQueueOrSynchronizeThread.Create(LogMemo, TInterfaceUpdateType.Queue);
end;

procedure TMainForm.IniciarThreadSynchronizeButtonClick(Sender: TObject);
begin
  // Criamos uma instância da nossa thread,
  // passando o LogMemo e indicando para usar Synchronize
  TQueueOrSynchronizeThread.Create(LogMemo, TInterfaceUpdateType.Synchronize);
end;

end.
