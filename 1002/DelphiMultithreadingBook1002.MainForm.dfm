object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 
    'Delphi Multithreading Book - 10.2: Requisi'#231#245'es de Rede Ass'#237'ncron' +
    'as e Paralelas'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    624
    441)
  TextHeight = 15
  object FetchButton: TButton
    Left = 8
    Top = 8
    Width = 250
    Height = 25
    Caption = 'Buscar Personagens de Rick and Morty'
    TabOrder = 0
    OnClick = FetchButtonClick
  end
  object LogMemo: TMemo
    Left = 8
    Top = 39
    Width = 608
    Height = 394
    Anchors = [akLeft, akTop, akRight, akBottom]
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object CancelButton: TButton
    Left = 264
    Top = 8
    Width = 250
    Height = 25
    Caption = 'Cancelar'
    TabOrder = 1
    OnClick = CancelButtonClick
  end
end
