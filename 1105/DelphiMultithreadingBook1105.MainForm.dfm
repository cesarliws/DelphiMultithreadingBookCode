object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 
    'Delphi Multithreading Book - 11.5: Construindo uma Arquitetura C' +
    'oncorrente Completa com PPL, Banco de Dados e Padr'#245'es de Design'
  ClientHeight = 600
  ClientWidth = 955
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 15
  object Splitter: TSplitter
    Left = 0
    Top = 242
    Width = 955
    Height = 3
    Cursor = crVSplit
    Align = alBottom
    ExplicitLeft = 8
    ExplicitTop = 252
  end
  object LogMemo: TMemo
    AlignWithMargins = True
    Left = 3
    Top = 482
    Width = 949
    Height = 115
    Align = alBottom
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object OrderPanel: TPanel
    AlignWithMargins = True
    Left = 3
    Top = 248
    Width = 949
    Height = 228
    Align = alBottom
    BevelEdges = [beBottom]
    BevelOuter = bvNone
    TabOrder = 1
    object OrderButtonsPanel: TPanel
      Left = 0
      Top = 0
      Width = 949
      Height = 31
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      object LoadOrdersButton: TButton
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 100
        Height = 25
        Align = alLeft
        Caption = 'Carregar Pedidos'
        TabOrder = 0
        OnClick = LoadOrdersButtonClick
      end
      object NewOrderButton: TButton
        AlignWithMargins = True
        Left = 109
        Top = 3
        Width = 100
        Height = 25
        Align = alLeft
        Caption = 'Novo Pedido'
        TabOrder = 1
        OnClick = NewOrderButtonClick
      end
      object EditOrderButton: TButton
        AlignWithMargins = True
        Left = 215
        Top = 3
        Width = 100
        Height = 25
        Align = alLeft
        Caption = 'Alterar Pedido'
        TabOrder = 2
        OnClick = EditOrderButtonClick
      end
      object DeleteOrderButton: TButton
        AlignWithMargins = True
        Left = 321
        Top = 3
        Width = 100
        Height = 25
        Align = alLeft
        Caption = 'Excluir Pedido'
        TabOrder = 3
        OnClick = DeleteOrderButtonClick
      end
    end
    object OrdersStringGrid: TStringGrid
      AlignWithMargins = True
      Left = 3
      Top = 34
      Width = 943
      Height = 191
      Align = alClient
      ColCount = 1
      FixedCols = 0
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goRowSelect]
      TabOrder = 1
      OnClick = OrdersStringGridClick
      OnDblClick = OrdersStringGridDblClick
    end
  end
  object CustomerPanel: TPanel
    Left = 0
    Top = 0
    Width = 955
    Height = 242
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object CustomerButtonsPanel: TPanel
      Left = 0
      Top = 0
      Width = 955
      Height = 31
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      ExplicitLeft = 1
      ExplicitTop = 1
      ExplicitWidth = 953
      object LoadCustomersButton: TButton
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 100
        Height = 25
        Align = alLeft
        Caption = 'Carregar Clientes'
        TabOrder = 0
        OnClick = LoadCustomersButtonClick
      end
      object NewCustomerButton: TButton
        AlignWithMargins = True
        Left = 109
        Top = 3
        Width = 100
        Height = 25
        Align = alLeft
        Caption = 'Novo Cliente'
        TabOrder = 1
        OnClick = NewCustomerButtonClick
      end
      object EditCustomerButton: TButton
        AlignWithMargins = True
        Left = 215
        Top = 3
        Width = 100
        Height = 25
        Align = alLeft
        Caption = 'Alterar Cliente'
        TabOrder = 2
        OnClick = EditCustomerButtonClick
      end
      object DeleteCustomerButton: TButton
        AlignWithMargins = True
        Left = 321
        Top = 3
        Width = 100
        Height = 25
        Align = alLeft
        Caption = 'Excluir Cliente'
        TabOrder = 3
        OnClick = DeleteCustomerButtonClick
      end
    end
    object CustomersStringGrid: TStringGrid
      AlignWithMargins = True
      Left = 3
      Top = 34
      Width = 949
      Height = 205
      Align = alClient
      ColCount = 1
      FixedCols = 0
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected, goRowSelect]
      TabOrder = 1
      OnClick = CustomersStringGridClick
      OnDblClick = CustomersStringGridDblClick
      ExplicitLeft = 4
      ExplicitTop = 35
      ExplicitWidth = 947
      ExplicitHeight = 203
    end
  end
end
