object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 
    'Delphi Multithreading Book - 8.2: Evitando Concorr'#234'ncia com `thr' +
    'eadvar` (Thread-Local Storage)'
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
  object StartNoSyncButton: TButton
    Left = 8
    Top = 8
    Width = 185
    Height = 25
    Caption = 'Sem Sincroniza'#231#227'o (Incorreto)'
    TabOrder = 0
    OnClick = StartNoSyncButtonClick
  end
  object StartCriticalSectionButton: TButton
    Left = 199
    Top = 8
    Width = 185
    Height = 25
    Caption = 'Com TCriticalSection (Lento)'
    TabOrder = 1
    OnClick = StartCriticalSectionButtonClick
  end
  object LogMemo: TMemo
    Left = 8
    Top = 39
    Width = 608
    Height = 394
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 3
  end
  object StartThreadVarButton: TButton
    Left = 390
    Top = 8
    Width = 185
    Height = 25
    Caption = 'Com threadvar (Otimizado)'
    TabOrder = 2
    OnClick = StartThreadVarButtonClick
  end
end
