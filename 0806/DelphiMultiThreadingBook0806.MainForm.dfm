object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 
    'Delphi Multithreading Book - 8.6: Depura'#231#227'o de Aplica'#231#245'es Multit' +
    'hreaded'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    624
    441)
  TextHeight = 13
  object IniciarCodeSiteThreadButton: TButton
    Left = 8
    Top = 8
    Width = 185
    Height = 25
    Caption = 'Iniciar Thread (CodeSite)'
    TabOrder = 0
    OnClick = IniciarCodeSiteThreadButtonClick
  end
  object LogMemo: TMemo
    Left = 8
    Top = 39
    Width = 608
    Height = 394
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 1
  end
end
