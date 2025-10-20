object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 
    'Delphi Multithreading Book - 8.3: Dados Compartilhados e Cole'#231#245'e' +
    's Thread-Safe: Garantindo a Integridade em Aplica'#231#245'es Multithrea' +
    'ded'
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
  object ProduzirMensagensButton: TButton
    Left = 8
    Top = 8
    Width = 281
    Height = 25
    Caption = 'Produzir Lote de Mensagens'
    TabOrder = 0
    OnClick = ProduzirMensagensButtonClick
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
