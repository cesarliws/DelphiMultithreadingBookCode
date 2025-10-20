object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 
    'Delphi Multithreading Book - 2.4: Threads An'#244'nimas (TThread.Crea' +
    'teAnonymousThread)'
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
  object IniciarAnonymousMethodButton: TButton
    Left = 8
    Top = 8
    Width = 175
    Height = 25
    Caption = 'Iniciar M'#233'todo An'#244'nimo'
    TabOrder = 0
    OnClick = IniciarAnonymousMethodButtonClick
  end
  object LogMemo: TMemo
    Left = 8
    Top = 39
    Width = 608
    Height = 394
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 1
  end
  object IniciarAnonymousThreadButton: TButton
    Left = 189
    Top = 8
    Width = 175
    Height = 25
    Caption = 'Iniciar Thread An'#244'nima'
    TabOrder = 2
    OnClick = IniciarAnonymousThreadButtonClick
  end
  object PararAnonymousThreadButton: TButton
    Left = 370
    Top = 8
    Width = 175
    Height = 25
    Caption = 'Parar Thread An'#244'nima'
    TabOrder = 3
    OnClick = PararAnonymousThreadButtonClick
  end
end
