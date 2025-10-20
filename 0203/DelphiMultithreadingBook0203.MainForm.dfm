object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 
    'Delphi Multithreading Book - 2.3: Lidando com M'#250'ltiplas Threads ' +
    'e Dados Compartilhados (Introdu'#231#227'o '#224' Sincroniza'#231#227'o)'
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
  object IniciarSemSincronizacaoButton: TButton
    Left = 8
    Top = 8
    Width = 249
    Height = 25
    Caption = 'Iniciar sem Sincroniza'#231#227'o'
    TabOrder = 0
    OnClick = IniciarSemSincronizacaoButtonClick
  end
  object LogMemo: TMemo
    Left = 8
    Top = 39
    Width = 608
    Height = 394
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 1
  end
  object IniciarComSincronizacaoButton: TButton
    Left = 263
    Top = 8
    Width = 249
    Height = 25
    Caption = 'Iniciar com Sincroniza'#231#227'o'
    TabOrder = 2
    OnClick = IniciarComSincronizacaoButtonClick
  end
end
