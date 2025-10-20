object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 
    'Delphi Multithreading Book - 7.1: Criando um Thread Pool Persona' +
    'lizado'
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
  object IniciarThreadPoolButton: TButton
    Left = 8
    Top = 8
    Width = 185
    Height = 25
    Caption = 'Iniciar Thread Pool'
    TabOrder = 0
    OnClick = IniciarThreadPoolButtonClick
  end
  object PararThreadPoolButton: TButton
    Left = 390
    Top = 8
    Width = 185
    Height = 25
    Caption = 'Parar Thread Pool'
    TabOrder = 2
    OnClick = PararThreadPoolButtonClick
  end
  object QueueTaskThreadPoolButton: TButton
    Left = 199
    Top = 8
    Width = 185
    Height = 25
    Caption = 'Enfileirar Tarefa'
    TabOrder = 1
    OnClick = QueueTaskThreadPoolButtonClick
  end
  object LogMemo: TMemo
    Left = 8
    Top = 39
    Width = 608
    Height = 394
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 3
  end
end
