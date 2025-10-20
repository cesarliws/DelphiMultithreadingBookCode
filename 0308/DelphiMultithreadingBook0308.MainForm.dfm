object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 
    'Delphi Multithreading Book - 3.8 `WaitForMultipleObjects`: Esper' +
    'a Coordenada em M'#250'ltiplos Eventos'
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
  object StartButton: TButton
    Left = 8
    Top = 8
    Width = 120
    Height = 25
    Caption = 'Iniciar Tarefa'
    TabOrder = 0
    OnClick = StartButtonClick
  end
  object LogMemo: TMemo
    Left = 8
    Top = 39
    Width = 608
    Height = 394
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 2
  end
  object CancelButton: TButton
    Left = 134
    Top = 8
    Width = 120
    Height = 25
    Caption = 'Cancelar Tarefa'
    Enabled = False
    TabOrder = 1
    OnClick = CancelButtonClick
  end
end
