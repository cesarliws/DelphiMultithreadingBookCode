object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 
    'Delphi Multithreading Book - 3.7: `TCountdownEvent` - Sincroniza' +
    'ndo a Conclus'#227'o de M'#250'ltiplas Tarefas'
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
  object StartWorkersButton: TButton
    Left = 8
    Top = 8
    Width = 249
    Height = 25
    Caption = 'Disparar Tarefas e Aguardar'
    TabOrder = 0
    OnClick = StartWorkersButtonClick
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
