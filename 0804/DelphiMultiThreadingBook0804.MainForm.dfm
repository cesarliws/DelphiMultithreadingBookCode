object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 
    'Delphi Multithreading Book - 8.4: Preven'#231#227'o de Problemas Comuns:' +
    ' Deadlocks e Race Conditions'
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
  object IniciarDeadlockExemploButton: TButton
    Left = 8
    Top = 8
    Width = 185
    Height = 25
    Caption = 'Iniciar Deadlock (Exemplo)'
    TabOrder = 0
    OnClick = IniciarDeadlockExemploButtonClick
  end
  object LogMemo: TMemo
    Left = 8
    Top = 39
    Width = 608
    Height = 394
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 1
  end
  object IniciarDeadlockPrevencaoButton: TButton
    Left = 199
    Top = 8
    Width = 185
    Height = 25
    Caption = 'Iniciar Deadlock (Preven'#231#227'o)'
    TabOrder = 2
    OnClick = IniciarDeadlockPrevencaoButtonClick
  end
end
