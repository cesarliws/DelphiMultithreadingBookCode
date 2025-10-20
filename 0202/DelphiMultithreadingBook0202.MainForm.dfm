object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 
    'Delphi Multithreading Book - 2.2: Comunicando com a Thread Princ' +
    'ipal (Synchronize e Queue)'
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
  object IniciarThreadSynchronizeButton: TButton
    Left = 8
    Top = 8
    Width = 249
    Height = 25
    Caption = 'Iniciar Thread (Synchronize)'
    TabOrder = 0
    OnClick = IniciarThreadSynchronizeButtonClick
  end
  object LogMemo: TMemo
    Left = 8
    Top = 39
    Width = 608
    Height = 394
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 1
  end
  object IniciarThreadQueueButton: TButton
    Left = 263
    Top = 8
    Width = 249
    Height = 25
    Caption = 'Iniciar Thread (Queue)'
    TabOrder = 2
    OnClick = IniciarThreadQueueButtonClick
  end
end
