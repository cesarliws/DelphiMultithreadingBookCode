object MainForm: TMainForm
  Left = 551
  Top = 83
  Caption = 
    'Delphi Multithreading Book - 2.1: Criando e Gerenciando Threads ' +
    'Simples'
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
    Caption = 'Iniciar Thread'
    TabOrder = 0
    OnClick = IniciarThreadButtonClick
  end
  object LogMemo: TMemo
    Left = 8
    Top = 72
    Width = 608
    Height = 361
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 1
  end
  object PararThreadButton: TButton
    Left = 263
    Top = 8
    Width = 249
    Height = 25
    Caption = 'Parar Thread'
    TabOrder = 2
    OnClick = PararThreadButtonClick
  end
  object ProgressBar: TProgressBar
    Left = 8
    Top = 39
    Width = 608
    Height = 27
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 3
  end
end
