object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 
    'Delphi Multithreading Book - 3.5: TEvent - Sinaliza'#231#227'o entre Thr' +
    'eads'
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
  object IniciarProdutorConsumidorButton: TButton
    Left = 8
    Top = 8
    Width = 249
    Height = 25
    Caption = 'Iniciar Produtor/Consumidor'
    TabOrder = 0
    OnClick = IniciarProdutorConsumidorButtonClick
  end
  object PararConsumidorButton: TButton
    Left = 263
    Top = 8
    Width = 249
    Height = 25
    Caption = 'Parar Consumidor'
    TabOrder = 2
    OnClick = PararConsumidorButtonClick
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
