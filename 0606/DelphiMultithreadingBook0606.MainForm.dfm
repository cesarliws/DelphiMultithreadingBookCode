object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 
    'Delphi Multithreading Book - 6.6: Outros Recursos da PPL: TParal' +
    'lelArray'
  ClientHeight = 441
  ClientWidth = 732
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
    732
    441)
  TextHeight = 15
  object OrdenarArraySequencialButton: TButton
    Left = 8
    Top = 8
    Width = 175
    Height = 25
    Caption = 'Ordenar Array (Sequencial)'
    TabOrder = 0
    OnClick = OrdenarArraySequencialButtonClick
  end
  object LogMemo: TMemo
    Left = 8
    Top = 39
    Width = 718
    Height = 394
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 1
  end
  object OrdenarArrayParaleloButton: TButton
    Left = 189
    Top = 8
    Width = 175
    Height = 25
    Caption = 'Ordenar Array (Paralelo)'
    TabOrder = 2
    OnClick = OrdenarArrayParaleloButtonClick
  end
  object ProcessarArraySequencialButton: TButton
    Left = 370
    Top = 8
    Width = 175
    Height = 25
    Caption = 'Processar Array (Sequencial)'
    TabOrder = 3
    OnClick = ProcessarArraySequencialButtonClick
  end
  object ProcessarArrayParaleloButton: TButton
    Left = 551
    Top = 8
    Width = 175
    Height = 25
    Caption = 'Processar Array (Paralelo)'
    TabOrder = 4
    OnClick = ProcessarArrayParaleloButtonClick
  end
end
