object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 
    'Delphi Multithreading Book - 6.5: Cancelamento de Tarefas PPL (I' +
    'Task.Cancel e ITask.CheckCanceled)'
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
  object IniciarTarefaButton: TButton
    Left = 8
    Top = 8
    Width = 185
    Height = 25
    Caption = 'Iniciar Tarefa (Cancel'#225'vel)'
    TabOrder = 0
    OnClick = IniciarTarefaButtonClick
  end
  object LogMemo: TMemo
    Left = 8
    Top = 39
    Width = 608
    Height = 394
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 2
  end
  object CancelarTarefaButton: TButton
    Left = 199
    Top = 8
    Width = 185
    Height = 25
    Caption = 'Cancelar Tarefa'
    TabOrder = 1
    OnClick = CancelarTarefaButtonClick
  end
end
