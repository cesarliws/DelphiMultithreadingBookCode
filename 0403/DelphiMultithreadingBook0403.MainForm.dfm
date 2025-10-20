object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 
    'Delphi Multithreading Book - 4.3: Cancelamento Cooperativo com `' +
    'TCancellationToken`'
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
    Width = 145
    Height = 25
    Caption = 'Iniciar Thread'
    TabOrder = 0
    OnClick = IniciarThreadButtonClick
  end
  object PausarThreadButton: TButton
    Left = 159
    Top = 8
    Width = 145
    Height = 25
    Caption = 'Pausar Thread'
    TabOrder = 1
    OnClick = PausarThreadButtonClick
  end
  object RetomarThreadButton: TButton
    Left = 310
    Top = 8
    Width = 145
    Height = 25
    Caption = 'Retomar Thread'
    TabOrder = 2
    OnClick = RetomarThreadButtonClick
  end
  object LogMemo: TMemo
    Left = 8
    Top = 39
    Width = 608
    Height = 394
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 4
  end
  object PararThreadButton: TButton
    Left = 461
    Top = 8
    Width = 145
    Height = 25
    Caption = 'Parar Thread'
    TabOrder = 3
    OnClick = PararThreadButtonClick
  end
end
