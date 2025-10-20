object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 
    'Delphi Multithreading Book - 10.4: Orquestra'#231#227'o de Fluxos de Tra' +
    'balho Complexos com Depend'#234'ncias'
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
  object StartPipelineButton: TButton
    Left = 8
    Top = 8
    Width = 185
    Height = 25
    Caption = 'Iniciar Pipeline de Importa'#231#227'o'
    TabOrder = 0
    OnClick = StartPipelineButtonClick
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
    Left = 199
    Top = 8
    Width = 185
    Height = 25
    Caption = 'Cancelar'
    TabOrder = 1
    OnClick = CancelButtonClick
  end
end
