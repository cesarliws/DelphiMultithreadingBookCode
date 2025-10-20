unit DelphiMultithreadingBook1105.MainForm;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ComCtrls,
  Vcl.ExtCtrls, System.Generics.Collections, System.Threading, Vcl.Grids,
  DelphiMultithreadingBook.Utils,
  DelphiMultithreadingBook1105.Interfaces,
  DelphiMultithreadingBook1105.Entities;

type
  TMainForm = class(TForm, ICustomerCallbacks, IOrderCallbacks)
    CustomerPanel: TPanel;
    CustomerButtonsPanel: TPanel;
    LoadCustomersButton: TButton;
    NewCustomerButton: TButton;
    EditCustomerButton: TButton;
    DeleteCustomerButton: TButton;
    CustomersStringGrid: TStringGrid;

    Splitter: TSplitter;

    LogMemo: TMemo;
    OrderPanel: TPanel;
    OrderButtonsPanel: TPanel;
    LoadOrdersButton: TButton;
    NewOrderButton: TButton;
    EditOrderButton: TButton;
    DeleteOrderButton: TButton;
    OrdersStringGrid: TStringGrid;

    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LoadCustomersButtonClick(Sender: TObject);
    procedure NewCustomerButtonClick(Sender: TObject);
    procedure EditCustomerButtonClick(Sender: TObject);
    procedure DeleteCustomerButtonClick(Sender: TObject);
    procedure LoadOrdersButtonClick(Sender: TObject);
    procedure NewOrderButtonClick(Sender: TObject);
    procedure EditOrderButtonClick(Sender: TObject);
    procedure DeleteOrderButtonClick(Sender: TObject);
    procedure CustomersStringGridClick(Sender: TObject);
    procedure OrdersStringGridClick(Sender: TObject);
    procedure CustomersStringGridDblClick(Sender: TObject);
    procedure OrdersStringGridDblClick(Sender: TObject);
  private
    FController: IController;
    FCurrentTask: ITask;
    FCustomers: TCustomerList;
    FOrders: TOrderList;

    procedure SetControlsState(IsRunning: Boolean);
    procedure DisplayCustomerInGrid(Customers: TCustomerList);
    procedure DisplayOrderInGrid(Orders: TOrderList);
    function GetSelectedCustomer: TCustomer;
    function GetSelectedOrder: TOrder;
    procedure ShowOrderFormForNewOrder;
    procedure ShowOrderFormForEdit;

    // ICustomerCallbacks
    procedure OnCustomersLoaded(Customers: TCustomerList);
    procedure OnCustomerSaved(Customer: TCustomer);
    procedure OnCustomerDeleted(CustomerID: string);
    procedure OnError(const ErrorMessage: string);

    // IOrderCallbacks
    procedure OnOrdersLoaded(Orders: TOrderList);
    procedure OnOrderSaved(Order: TOrder);
    procedure OnOrderDeleted(OrderID: Integer);
    procedure UpdateGridColsWidth(Grid: TStringGrid; Factor: Integer = 3);
  public
    destructor Destroy; override;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  System.SysUtils,
  System.UITypes,
  Vcl.Dialogs,
  WinApi.Windows,
  DelphiMultithreadingBook1105.Controller,
  DelphiMultithreadingBook1105.OrderView,
  DelphiMultithreadingBook1105.CustomerView,
  DelphiMultithreadingBook1105.Repository;

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
begin
  RegisterLogger(LogMemo.Lines);
  SetControlsState(False);
  FController := TController.Create;

  // Configurar grids
  CustomersStringGrid.ColCount := 5;
  CustomersStringGrid.Cells[0, 0] := 'Empresa';
  CustomersStringGrid.Cells[1, 0] := 'ID';
  CustomersStringGrid.Cells[2, 0] := 'Contato';
  CustomersStringGrid.Cells[3, 0] := 'Cidade';
  CustomersStringGrid.Cells[4, 0] := 'País';
  CustomersStringGrid.FixedRows := 1;
  CustomersStringGrid.RowCount := 1;

  OrdersStringGrid.ColCount := 5;
  OrdersStringGrid.Cells[0, 0] := 'Pedido ID';
  OrdersStringGrid.Cells[1, 0] := 'Data';
  OrdersStringGrid.Cells[2, 0] := 'Frete';
  OrdersStringGrid.Cells[3, 0] := 'Cidade';
  OrdersStringGrid.Cells[4, 0] := 'País';
  OrdersStringGrid.FixedRows := 1;
  OrdersStringGrid.RowCount := 1;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  TThread.ForceQueue(nil, procedure begin
    LoadCustomersButtonClick(nil);
  end);
end;

destructor TMainForm.Destroy;
begin
  UnregisterLogger;
  TRepositoryFactory.CleanupThread;

  // Cancela tasks pendentes
  if Assigned(FCurrentTask) then
  begin
    FCurrentTask.Cancel;
    try
      FCurrentTask.Wait(1000);
    except
      // Ignore exceptions durante cancelamento
    end;
  end;

  // Limpar listas
  if Assigned(FCustomers) then
    FCustomers.Free;
  if Assigned(FOrders) then
    FOrders.Free;

  inherited;
end;

procedure TMainForm.LoadCustomersButtonClick(Sender: TObject);
begin
  SetControlsState(True);
  LogWrite('Carregando clientes...');
  FController.LoadCustomers(Self);
end;

procedure TMainForm.NewCustomerButtonClick(Sender: TObject);
var
  NewCustomer: TCustomer;
begin
  NewCustomer := TCustomerForm.CreateNewCustomer(FController);
  if Assigned(NewCustomer) then
  begin
    LogWrite(Format('Novo cliente criado: %s - %s',
      [NewCustomer.CustomerID, NewCustomer.CompanyName]));
    LoadCustomersButtonClick(nil); // Recarrega a lista
  end;
end;

procedure TMainForm.EditCustomerButtonClick(Sender: TObject);
var
  Customer: TCustomer;
begin
  Customer := GetSelectedCustomer;
  if not Assigned(Customer) then
  begin
    LogWrite('Nenhum cliente selecionado para editar.');
    Exit;
  end;

  if TCustomerForm.EditCustomer(Customer, FController) then
  begin
    LogWrite(Format('Cliente %s atualizado.', [Customer.CustomerID]));
    LoadCustomersButtonClick(nil); // Recarrega a lista
  end;
end;

procedure TMainForm.DeleteCustomerButtonClick(Sender: TObject);
var
  Customer: TCustomer;
begin
  Customer := GetSelectedCustomer;
  if not Assigned(Customer) then
  begin
    LogWrite('Nenhum cliente selecionado para excluir.');
    Exit;
  end;

  if MessageDlg(Format('Confirma a exclusão do cliente %s?',
    [Customer.CustomerID]), mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    SetControlsState(True);
    LogWrite(Format('Excluindo cliente %s...', [Customer.CustomerID]));
    FController.DeleteCustomer(Customer.CustomerID, Self);
  end;
end;

procedure TMainForm.LoadOrdersButtonClick(Sender: TObject);
var
  Customer: TCustomer;
  CachedOrders: TOrderList;
begin
  Customer := GetSelectedCustomer;
  if not Assigned(Customer) then
  begin
    LogWrite('Nenhum cliente selecionado.');
    Exit;
  end;

  // Verifica se já tem em cache
  CachedOrders := FController.GetCachedOrders(Customer.CustomerID);
  if Assigned(CachedOrders) then
  begin
    LogWrite('Carregando pedidos do cache...');
    OnOrdersLoaded(CachedOrders);
  end
  else
  begin
    SetControlsState(True);
    LogWrite(Format('Carregando pedidos para %s...', [Customer.CustomerID]));
    FController.LoadOrdersForCustomer(Customer.CustomerID, Self);
  end;
end;

procedure TMainForm.NewOrderButtonClick(Sender: TObject);
begin
  ShowOrderFormForNewOrder;
end;

procedure TMainForm.EditOrderButtonClick(Sender: TObject);
begin
  ShowOrderFormForEdit;
end;

procedure TMainForm.DeleteOrderButtonClick(Sender: TObject);
var
  Order: TOrder;
begin
  Order := GetSelectedOrder;
  if not Assigned(Order) then
  begin
    LogWrite('Nenhum pedido selecionado para excluir.');
    Exit;
  end;

  if MessageDlg(Format('Confirma a exclusão do pedido %d?', [Order.OrderID]),
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    SetControlsState(True);
    LogWrite(Format('Excluindo pedido %d...', [Order.OrderID]));
    FController.DeleteOrder(Order.OrderID, Self);
  end;
end;

procedure TMainForm.SetControlsState(IsRunning: Boolean);
begin
  if csDestroying in ComponentState then Exit;

  LoadCustomersButton.Enabled := not IsRunning;
  NewCustomerButton.Enabled := not IsRunning;
  EditCustomerButton.Enabled := not IsRunning and (GetSelectedCustomer <> nil);
  DeleteCustomerButton.Enabled := not IsRunning and (GetSelectedCustomer <> nil);

  LoadOrdersButton.Enabled := not IsRunning and (GetSelectedCustomer <> nil);
  NewOrderButton.Enabled := not IsRunning and (GetSelectedCustomer <> nil);
  EditOrderButton.Enabled := not IsRunning and (GetSelectedOrder <> nil);
  DeleteOrderButton.Enabled := not IsRunning and (GetSelectedOrder <> nil);

  if not IsRunning then
    FCurrentTask := nil;
end;

procedure TMainForm.DisplayCustomerInGrid(Customers: TCustomerList);
begin
  CustomersStringGrid.BeginUpdate;
  try
    CustomersStringGrid.RowCount := Customers.Count + 1;

    for var I := 0 to Customers.Count - 1 do
    begin
      var Customer := Customers[I];
      CustomersStringGrid.Cells[0, I + 1] := Customer.CompanyName;
      CustomersStringGrid.Cells[1, I + 1] := Customer.CustomerID;
      CustomersStringGrid.Cells[2, I + 1] := Customer.ContactName;
      CustomersStringGrid.Cells[3, I + 1] := Customer.City;
      CustomersStringGrid.Cells[4, I + 1] := Customer.Country;
      CustomersStringGrid.Objects[0, I + 1] := Customer;
    end;

    UpdateGridColsWidth(CustomersStringGrid);
  finally
    CustomersStringGrid.EndUpdate
  end;
end;

procedure TMainForm.DisplayOrderInGrid(Orders: TOrderList);
begin
  OrdersStringGrid.BeginUpdate;
  try
    OrdersStringGrid.RowCount := Orders.Count + 1;

    for var I := 0 to Orders.Count - 1 do
    begin
      var Order := Orders[I];
      OrdersStringGrid.Cells[0, I + 1] := Order.OrderID.ToString;
      OrdersStringGrid.Cells[1, I + 1] := FormatDateTime('dd/mm/yyyy',
        Order.OrderDate);
      OrdersStringGrid.Cells[2, I + 1] := Format('%.2m', [Order.Freight]);
      OrdersStringGrid.Cells[3, I + 1] := Order.ShipCity;
      OrdersStringGrid.Cells[4, I + 1] := Order.ShipCountry;
      OrdersStringGrid.Objects[0, I + 1] := Order;
    end;

    UpdateGridColsWidth(OrdersStringGrid);
  finally
    OrdersStringGrid.EndUpdate;
  end;
end;

procedure TMainForm.UpdateGridColsWidth(Grid: TStringGrid; Factor: Integer = 3);
var
  ColWidth: Integer;
begin
  if Factor < 0 then Factor := 1;

  // Ajustar largura das colunas
  for var i := 0 to Grid.ColCount - 1 do
  begin
    ColWidth := Grid.Canvas.TextWidth(
      Grid.Cells[i, 1]) * Factor;
    Grid.ColWidths[i] := ColWidth;
  end;
end;

function TMainForm.GetSelectedCustomer: TCustomer;
begin
  Result := nil;
  if (CustomersStringGrid.Row > 0) and
     (CustomersStringGrid.Row < CustomersStringGrid.RowCount) then
    Result := TCustomer(CustomersStringGrid.Objects[0, CustomersStringGrid.Row]);
end;

function TMainForm.GetSelectedOrder: TOrder;
begin
  Result := nil;
  if (OrdersStringGrid.Row > 0) and
     (OrdersStringGrid.Row < OrdersStringGrid.RowCount) then
    Result := TOrder(OrdersStringGrid.Objects[0, OrdersStringGrid.Row]);
end;

procedure TMainForm.ShowOrderFormForNewOrder;
var
  Customer: TCustomer;
  NewOrder: TOrder;
begin
  Customer := GetSelectedCustomer;
  if not Assigned(Customer) then
  begin
    LogWrite('Selecione um cliente para criar um pedido.');
    Exit;
  end;

  // EmployeeID fixo
  NewOrder := TOrderForm.CreateNewOrder(Customer.CustomerID, 1, FController);

  if Assigned(NewOrder) then
  begin
    LogWrite(Format('Novo pedido criado: ID %d para cliente %s',
      [NewOrder.OrderID, Customer.CustomerID]));
    // Recarrega os pedidos
    LoadOrdersButtonClick(nil);
  end;
end;

procedure TMainForm.ShowOrderFormForEdit;
var
  Order: TOrder;
begin
  Order := GetSelectedOrder;
  if not Assigned(Order) then
  begin
    LogWrite('Selecione um pedido para editar.');
    Exit;
  end;

  if TOrderForm.EditOrder(Order, FController) then
  begin
    LogWrite(Format('Pedido %d atualizado.', [Order.OrderID]));
    // Atualiza a lista
    LoadOrdersButtonClick(nil);
  end;
end;

{ Event Handlers para StringGrid }

procedure TMainForm.CustomersStringGridClick(Sender: TObject);
begin
  SetControlsState(False);
  // Limpa a lista de pedidos quando seleciona outro cliente
  OrdersStringGrid.RowCount := 1;
  LoadOrdersButtonClick(nil);
end;

procedure TMainForm.OrdersStringGridClick(Sender: TObject);
begin
  SetControlsState(False);
end;

procedure TMainForm.CustomersStringGridDblClick(Sender: TObject);
begin
  EditCustomerButtonClick(nil);
end;

procedure TMainForm.OrdersStringGridDblClick(Sender: TObject);
begin
  EditOrderButtonClick(nil);
end;

{ ICustomerCallbacks }

procedure TMainForm.OnCustomersLoaded(Customers: TCustomerList);
begin
  try
    // Guarda referência para os objetos
    if Assigned(FCustomers) then
      FCustomers.Free;
    FCustomers := Customers;
    // Controller gerencia o lifetime
    FCustomers.OwnsObjects := False;

    DisplayCustomerInGrid(Customers);
    LogWrite(Format('%d clientes carregados.', [Customers.Count]));

    // Seleciona primeira linha
    if CustomersStringGrid.RowCount > 1 then
      CustomersStringGrid.Row := 1;

  except
    on E: Exception do
      LogWrite('Erro ao carregar clientes: ' + E.Message);
  end;
  SetControlsState(False);
end;

procedure TMainForm.OnCustomerSaved(Customer: TCustomer);
begin
  LogWrite('Cliente salvo com sucesso!');
  LoadCustomersButtonClick(nil); // Recarrega a lista
end;

procedure TMainForm.OnCustomerDeleted(CustomerID: string);
begin
  LogWrite(Format('Cliente %s excluído com sucesso!', [CustomerID]));
  LoadCustomersButtonClick(nil); // Recarrega a lista
end;

procedure TMainForm.OnError(const ErrorMessage: string);
begin
  LogWrite('ERRO: ' + ErrorMessage);
  SetControlsState(False);
end;

{ IOrderCallbacks }

procedure TMainForm.OnOrdersLoaded(Orders: TOrderList);
begin
  try
    // Guarda referência para os objetos
    if Assigned(FOrders) then
      FOrders.Free;
    FOrders := Orders;
    // Customer gerencia o lifetime
    FOrders.OwnsObjects := False;

    DisplayOrderInGrid(Orders);
    LogWrite(Format('%d pedidos carregados.', [Orders.Count]));

    // Seleciona primeira linha
    if OrdersStringGrid.RowCount > 1 then
      OrdersStringGrid.Row := 1;

  except
    on E: Exception do
      LogWrite('Erro ao carregar pedidos: ' + E.Message);
  end;
  SetControlsState(False);
end;

procedure TMainForm.OnOrderSaved(Order: TOrder);
begin
  LogWrite(Format('Pedido %d salvo com sucesso!', [Order.OrderID]));
  // Recarrega os pedidos para atualizar a lista
  LoadOrdersButtonClick(nil);
end;

procedure TMainForm.OnOrderDeleted(OrderID: Integer);
begin
  LogWrite(Format('Pedido %d excluído com sucesso!', [OrderID]));
  // Recarrega os pedidos para atualizar a lista
  LoadOrdersButtonClick(nil);
end;

end.
