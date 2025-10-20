object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 
    'Delphi Multithreading Book - 5.3: Integra'#231#227'o de I/O Ass'#237'ncrono c' +
    'om Threads'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    624
    441)
  TextHeight = 15
  object IniciarAsyncDownloadButton: TButton
    Left = 8
    Top = 8
    Width = 185
    Height = 25
    Caption = 'Iniciar Download Ass'#237'ncrono'
    TabOrder = 0
    OnClick = IniciarAsyncDownloadButtonClick
  end
  object LogMemo: TMemo
    Left = 8
    Top = 39
    Width = 608
    Height = 394
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 2
  end
  object CancelarDownloadButton: TButton
    Left = 199
    Top = 8
    Width = 185
    Height = 25
    Caption = 'Cancelar Download'
    TabOrder = 1
    OnClick = CancelarDownloadButtonClick
  end
end
