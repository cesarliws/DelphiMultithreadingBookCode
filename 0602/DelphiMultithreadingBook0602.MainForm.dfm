object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 
    'Delphi Multithreading Book - 6.2: TTask e ITask - O Cora'#231#227'o da P' +
    'PL'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  ShowHint = True
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    624
    441)
  TextHeight = 15
  object IniciarTaskButton: TButton
    Left = 8
    Top = 8
    Width = 185
    Height = 25
    Caption = 'Iniciar Tarefa (TTask)'
    TabOrder = 0
    OnClick = IniciarTaskButtonClick
  end
  object CalcularTaskButton: TButton
    Left = 199
    Top = 8
    Width = 185
    Height = 25
    Caption = 'Calcular (IFuture)'
    TabOrder = 1
    OnClick = CalcularTaskButtonClick
  end
  object LogMemo: TMemo
    Left = 8
    Top = 39
    Width = 598
    Height = 394
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 3
  end
  object ForceExceptionCheckBox: TCheckBox
    Left = 390
    Top = 10
    Width = 211
    Height = 17
    Hint = 'For'#231'ar Exception quando Calcular (IFuture)'
    Caption = 'For'#231'ar Exception quando Calcular'
    TabOrder = 2
  end
end
