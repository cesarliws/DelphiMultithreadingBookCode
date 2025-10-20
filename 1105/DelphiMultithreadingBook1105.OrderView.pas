unit DelphiMultithreadingBook1105.OrderView;

interface

uses
  System.Classes, System.SysUtils, System.Variants, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Mask, Vcl.ComCtrls, Vcl.ExtCtrls,
  DelphiMultithreadingBook1105.Entities,
  DelphiMultithreadingBook1105.Interfaces;

type
  TOrderForm = class(TForm, IOrderCallbacks)
    ButtonsPanel: TPanel;
    SaveButton: TButton;
    CancelButton: TButton;
    ControlsPanel: TPanel;
    OrderInfoGroupBox: TGroupBox;
    CustomerIdEdit: TEdit;
    CustomerIDLabel: TLabel;
    EmployeeIdEdit: TEdit;
    EmployeeIDLabel: TLabel;
    FreightEdit: TMaskEdit;
    FreightLabel: TLabel;
    OrderDateDateTimePicker: TDateTimePicker;
    OrderDateLabel: TLabel;
    OrderIDEdit: TEdit;
    OrderIDLabel: TLabel;
    RequiredDateDateTimePicker: TDateTimePicker;
    RequiredDateLabel: TLabel;
    ShippedDateDateTimePicker: TDateTimePicker;
    ShippedDateLabel: TLabel;
    ShipViaEdit: TEdit;
    ShipViaLabel: TLabel;
    DeliveryInfoGroupBox: TGroupBox;
    ShipAddressEdit: TEdit;
    ShipAddressLabel: TLabel;
    ShipCityEdit: TEdit;
    ShipCityLabel: TLabel;
    ShipCountryEdit: TEdit;
    ShipCountryLabel: TLabel;
    ShipNameEdit: TEdit;
    ShipNameLabel: TLabel;
    ShipPostalCodeEdit: TEdit;
    ShipPostalCodeLabel: TLabel;
    ShipRegionEdit: TEdit;
    ShipRegionLabel: TLabel;
    procedure SaveButtonClick(Sender: TObject);
    procedure CancelButtonClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FController: IController;
    FOrder: TOrder;
    FIsNewOrder: Boolean;
    FCustomerID: string;
    FEmployeeID: Integer;
    procedure SetControlsState(IsRunning: Boolean);
    procedure LoadOrderData;
    procedure SaveOrderData;

    // IOrderCallbacks
    procedure OnOrdersLoaded(Orders: TOrderList);
    procedure OnOrderSaved(Order: TOrder);
    procedure OnOrderDeleted(OrderID: Integer);
    procedure OnError(const ErrorMessage: string);
  public
    class function CreateNewOrder(const CustomerID: string; EmployeeID: Integer;
      Controller: IController): TOrder; static;
    class function EditOrder(Order: TOrder; Controller: IController):
      Boolean; static;
  end;

var
  OrderForm: TOrderForm;

implementation

{$R *.dfm}

uses
  System.StrUtils,
  DelphiMultithreadingBook.Utils;

{ TOrderForm }

class function TOrderForm.CreateNewOrder(const CustomerID: string;
  EmployeeID: Integer; Controller: IController): TOrder;
begin
  Result := nil;
  var Form := TOrderForm.Create(Application);
  try
    Form.FController := Controller;
    Form.FCustomerID := CustomerID;
    Form.FEmployeeID := EmployeeID;
    Form.FIsNewOrder := True;
    var Order := TOrder.Create;
    // Configura informa��es iniciais
    Order.CustomerID := CustomerID;
    Order.EmployeeID := EmployeeID;
    Order.OrderDate := Now;
    // 7 dias prazo padr�o
    Order.RequiredDate := Now + 7;
    Order.ShippedDate := Now;
    Order.Freight := 0;
    Order.ShipVia := 1;
    Form.FOrder := Order;
    Form.LoadOrderData;

    if Form.ShowModal = mrOk then
      Result := Form.FOrder
    else
      Form.FOrder.Free;

  finally
    Form.Free;
  end;
end;

class function TOrderForm.EditOrder(Order: TOrder;
  Controller: IController): Boolean;
begin
  Result := False;
  var Form := TOrderForm.Create(Application);
  try
    Form.FController := Controller;
    Form.FOrder := Order;
    Form.FIsNewOrder := False;
    Form.FCustomerID := Order.CustomerID;
    Form.FEmployeeID := Order.EmployeeID;

    Form.LoadOrderData;

    if Form.ShowModal = mrOk then
      Result := True;

  finally
    Form.Free;
  end;
end;

procedure TOrderForm.LoadOrderData;
begin
  // Configura campos readonly
  OrderIDEdit.Text := IfThen(FOrder.OrderID > 0, FOrder.OrderID.ToString, 'NOVO');
  CustomerIdEdit.Text := FCustomerID;
  EmployeeIdEdit.Text := FEmployeeID.ToString;

  // Datas
  OrderDateDateTimePicker.Date := FOrder.OrderDate;
  RequiredDateDateTimePicker.Date := FOrder.RequiredDate;
  ShippedDateDateTimePicker.Date := FOrder.ShippedDate;

  // Demais campos
  ShipViaEdit.Text := FOrder.ShipVia.ToString;
  FreightEdit.Text := FormatFloat('0.00', FOrder.Freight);
  ShipNameEdit.Text := FOrder.ShipName;
  ShipAddressEdit.Text := FOrder.ShipAddress;
  ShipCityEdit.Text := FOrder.ShipCity;
  ShipRegionEdit.Text := FOrder.ShipRegion;
  ShipPostalCodeEdit.Text := FOrder.ShipPostalCode;
  ShipCountryEdit.Text := FOrder.ShipCountry;

  // Habilita/desabilita conforme novo/edicao
  OrderIDEdit.ReadOnly := True;
  CustomerIdEdit.ReadOnly := True;
  EmployeeIdEdit.ReadOnly := True;

  Caption := IfThen(FIsNewOrder, 'Novo Pedido - ', 'Editar Pedido - ')
    + FCustomerID;
end;

procedure TOrderForm.SaveOrderData;
begin
  // Datas
  FOrder.OrderDate := OrderDateDateTimePicker.Date;
  FOrder.RequiredDate := RequiredDateDateTimePicker.Date;
  FOrder.ShippedDate := ShippedDateDateTimePicker.Date;

  // Demais campos
  FOrder.ShipVia := StrToIntDef(ShipViaEdit.Text, 1);
  FOrder.Freight := StrToFloatDef(FreightEdit.Text, 0);
  FOrder.ShipName := ShipNameEdit.Text;
  FOrder.ShipAddress := ShipAddressEdit.Text;
  FOrder.ShipCity := ShipCityEdit.Text;
  FOrder.ShipRegion := ShipRegionEdit.Text;
  FOrder.ShipPostalCode := ShipPostalCodeEdit.Text;
  FOrder.ShipCountry := ShipCountryEdit.Text;
end;

procedure TOrderForm.SaveButtonClick(Sender: TObject);
begin
  SaveOrderData;

  if not FController.ValidateOrder(FOrder) then
  begin
    ShowMessage('Pedido inv�lido, verifique as informa��es.');
    Exit;
  end;

  SetControlsState(True);

  if FIsNewOrder then
    FController.CreateOrder(FOrder, Self)
  else
    FController.UpdateOrder(FOrder, Self);
end;

procedure TOrderForm.CancelButtonClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TOrderForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if ModalResult <> mrOk then
  begin
    if FIsNewOrder and Assigned(FOrder) then
      FOrder.Free;
  end;
end;

procedure TOrderForm.SetControlsState(IsRunning: Boolean);
begin
  SaveButton.Enabled := not IsRunning;
  CancelButton.Enabled := not IsRunning;
  ControlsPanel.Enabled := not IsRunning;
end;

{ IOrderCallbacks }

procedure TOrderForm.OnOrdersLoaded(Orders: TOrderList);
begin
  // N�o usado neste form
end;

procedure TOrderForm.OnOrderSaved(Order: TOrder);
begin
  TThread.Queue(nil,
    procedure
    begin
      if FIsNewOrder then
        ShowMessage('Pedido criado com sucesso! ID: ' + Order.OrderID.ToString)
      else
        ShowMessage('Pedido atualizado com sucesso!');

      ModalResult := mrOk;
    end);
end;

procedure TOrderForm.OnOrderDeleted(OrderID: Integer);
begin
  // N�o usado neste form
end;

procedure TOrderForm.OnError(const ErrorMessage: string);
begin
  TThread.Queue(nil,
    procedure
    begin
      ShowMessage('Erro: ' + ErrorMessage);
      SetControlsState(False);
    end);
end;

end.
