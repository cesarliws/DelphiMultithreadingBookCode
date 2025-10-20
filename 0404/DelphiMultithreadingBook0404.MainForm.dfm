object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 
    'Delphi Multithreading Book - 4.4: Gerenciando a Prioridade de Ex' +
    'ecu'#231#227'o (`TThread.Priority`)'
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
  object IniciarThreadButton: TButton
    Left = 8
    Top = 8
    Width = 249
    Height = 25
    Caption = 'Iniciar Threads com Prioridades Diferentes'
    TabOrder = 0
    OnClick = IniciarThreadButtonClick
  end
  object LogMemo: TMemo
    Left = 8
    Top = 39
    Width = 608
    Height = 394
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 1
  end
  object TestTimer: TTimer
    Enabled = False
    Interval = 5000
    OnTimer = TestTimerTimer
    Left = 304
    Top = 224
  end
end
