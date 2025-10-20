unit DelphiMultithreadingBook0101.MainForm;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls;

type
  TMainForm = class(TForm)
    IniciarProcessamentoSincronoButton: TButton;
    LogMemo: TMemo;
    procedure IniciarProcessamentoSincronoButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure LogWrite(const Text: string);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.DateUtils,
  System.SysUtils;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  LogWrite('Aplica��o iniciada.');
end;

procedure TMainForm.IniciarProcessamentoSincronoButtonClick(Sender: TObject);
var
  i: Integer;
  Inicio: TDateTime;
begin
  LogWrite('> Iniciando opera��o demorada.');
  LogWrite('Interface N�O responsiva, tente mover a janela...');
  // Garante que a mensagem acima seja exibida
  Repaint;

  Inicio := Now;
  // Um loop longo o suficiente para bloquear
  for i := 0 to 10000000 do
  begin
    // Apenas para consumir tempo. O Sleep(0) cede o restante do quantum
    // de tempo da CPU, mas a thread principal ainda est� "ocupada".
    Sleep(0);
  end;

  LogWrite(Format('Opera��o demorada conclu�da em %d ms!',
    [MilliSecondsBetween(Now, Inicio)]));
end;

procedure TMainForm.LogWrite(const Text: string);
begin
  LogMemo.Lines.Add(Text);
end;

end.
