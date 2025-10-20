object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 
    'Delphi Multithreading Book - 6.7: Estendendo a PPL: Padr'#245'es de E' +
    'ncapsulamento e Comunica'#231#227'o'
  ClientHeight = 441
  ClientWidth = 862
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
    862
    441)
  TextHeight = 15
  object IniciarTaskOnCompleteOnErrorButton: TButton
    Left = 8
    Top = 8
    Width = 200
    Height = 25
    Caption = 'Iniciar Task.OnComplete.OnError'
    TabOrder = 0
    OnClick = IniciarTaskOnCompleteOnErrorButtonClick
  end
  object LogMemo: TMemo
    Left = 8
    Top = 62
    Width = 846
    Height = 371
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 1
  end
  object IniciarFutureOnCompleteOnErrorButton: TButton
    Left = 214
    Top = 8
    Width = 200
    Height = 25
    Caption = 'Iniciar Future.OnComplete.OnError'
    TabOrder = 2
    OnClick = IniciarFutureOnCompleteOnErrorButtonClick
  end
  object IniciarTaskContinueWithButton: TButton
    Left = 420
    Top = 8
    Width = 200
    Height = 25
    Caption = 'Iniciar Task.ContinueWith'
    TabOrder = 3
    OnClick = IniciarTaskContinueWithButtonClick
  end
  object IniciarFutureContinueWithButton: TButton
    Left = 626
    Top = 8
    Width = 200
    Height = 25
    Caption = 'Iniciar Future.ContinueWith'
    TabOrder = 4
    OnClick = IniciarFutureContinueWithButtonClick
  end
  object ForceExceptionCheckBox: TCheckBox
    Left = 8
    Top = 39
    Width = 97
    Height = 17
    Caption = 'Force Exception'
    TabOrder = 5
  end
end
