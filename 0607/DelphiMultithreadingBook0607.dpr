program DelphiMultithreadingBook0607;

uses
  FastMM5,
  Vcl.Forms,
  DelphiMultithreadingBook0607.MainForm in 'DelphiMultithreadingBook0607.MainForm.pas' {MainForm},
  DelphiMultithreadingBook0607.Threading.Helpers in 'DelphiMultithreadingBook0607.Threading.Helpers.pas',
  DelphiMultithreadingBook0607.Threading.HelpersEx in 'DelphiMultithreadingBook0607.Threading.HelpersEx.pas',
  DelphiMultithreadingBook0403.CancellationToken in '..\0403\DelphiMultithreadingBook0403.CancellationToken.pas',
  DelphiMultithreadingBook0607.Threading.BasicHelpers in 'DelphiMultithreadingBook0607.Threading.BasicHelpers.pas',
  Deep.Threading.Helpers in 'Deep.Threading.Helpers.pas',
  DelphiMultithreadingBook0607.MainForm.Testes in 'DelphiMultithreadingBook0607.MainForm.Testes.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutDown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
