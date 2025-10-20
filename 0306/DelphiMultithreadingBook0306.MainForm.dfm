object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 
    'Delphi Multithreading Book - 3.6: Otimizando Acesso Concorrente:' +
    ' O Padr'#227'o Leitores-Escritores'
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
  object IniciarCriticalSectionButton: TButton
    Left = 8
    Top = 8
    Width = 249
    Height = 25
    Caption = 'Teste com TCriticalSection'
    TabOrder = 0
    OnClick = IniciarCriticalSectionButtonClick
  end
  object IniciarMREWButton: TButton
    Left = 263
    Top = 8
    Width = 249
    Height = 25
    Caption = 'Teste com TLightweightMREW'
    TabOrder = 1
    OnClick = IniciarMREWButtonClick
  end
  object LogMemo: TMemo
    Left = 8
    Top = 39
    Width = 608
    Height = 394
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 2
  end
end
