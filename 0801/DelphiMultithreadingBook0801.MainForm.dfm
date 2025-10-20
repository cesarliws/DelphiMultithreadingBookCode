object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 
    'Delphi Multithreading Book - 8.1: Organiza'#231#227'o do C'#243'digo (Threads' +
    ' em Units Separadas)'
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
  object IniciarCalculoButton: TButton
    Left = 8
    Top = 8
    Width = 185
    Height = 25
    Caption = 'Iniciar C'#225'lculo'
    TabOrder = 0
    OnClick = IniciarCalculoButtonClick
  end
  object CancelarCalculoButton: TButton
    Left = 199
    Top = 8
    Width = 185
    Height = 25
    Caption = 'Cancelar C'#225'lculo'
    TabOrder = 1
    OnClick = CancelarCalculoButtonClick
  end
  object LogMemo: TMemo
    Left = 8
    Top = 39
    Width = 608
    Height = 394
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 3
  end
  object ProgressBar: TProgressBar
    Left = 390
    Top = 8
    Width = 226
    Height = 25
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 2
  end
end
