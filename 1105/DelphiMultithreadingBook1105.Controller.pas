﻿unit DelphiMultithreadingBook1105.Controller;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  System.Threading,
  DelphiMultithreadingBook1105.Interfaces,
  DelphiMultithreadingBook1105.Entities,
  DelphiMultithreadingBook1105.Repository;

type
  TController = class(TInterfacedObject, IController)
  private
    FCustomers: TCustomerList;
    FOrders: TOrderList;

    function GetCustomers: TCustomerList;
    function GetOrders: TOrderList;
  protected
    function IsValidPhone(const Phone: string): Boolean;
    procedure RunAsync(const Proc: TProc; const Callbacks: ICallBacks);
  public
    constructor Create;
    destructor Destroy; override;

    // IController
    procedure LoadCustomers(const Callbacks: ICustomerCallbacks);
    procedure SaveCustomer(Customer: TCustomer;
      const Callbacks: ICustomerCallbacks);
    procedure DeleteCustomer(const CustomerID: string;
      const Callbacks: ICustomerCallbacks);
    procedure LoadOrdersForCustomer(const CustomerID: string;
      const Callbacks: IOrderCallbacks);
    procedure LoadAllOrders(const Callbacks: IOrderCallbacks);
    procedure CreateOrder(Order: TOrder; const Callbacks: IOrderCallbacks);
    procedure UpdateOrder(Order: TOrder; const Callbacks: IOrderCallbacks);
    procedure DeleteOrder(const OrderID: Integer;
      const Callbacks: IOrderCallbacks);

    function GetCachedOrders(const CustomerID: string): TOrderList;
    function ValidateCustomer(const Customer: TCustomer): Boolean;
    function ValidateOrder(const Order: TOrder): Boolean;

    property Customers: TCustomerList read GetCustomers;
    property Orders: TOrderList read GetOrders;
  end;

implementation

uses
  System.RegularExpressions,
  DelphiMultithreadingBook.Utils;

{ TController }

constructor TController.Create;
begin
  inherited;
  FCustomers := TCustomerList.Create(True);
  FOrders := TOrderList.Create(True);
end;

destructor TController.Destroy;
begin
  FOrders.Free;
  FCustomers.Free;
  inherited;
end;

procedure TController.RunAsync(const Proc: TProc; const Callbacks: ICallBacks);
begin
  TTask.Run(
    procedure
    var
      ExceptionObj: TObject;
    begin
      try
        try
          Proc();
        except
          ExceptionObj := AcquireExceptionObject;
          TThread.Queue(nil,
            procedure
            begin
              Callbacks.OnError((ExceptionObj as Exception).Message);
              (ExceptionObj as Exception).Free;
            end);
        end;
      finally
        TRepositoryFactory.CleanupThread;
      end;
    end);
end;

procedure TController.LoadCustomers(const Callbacks: ICustomerCallbacks);
var
  Repository: ICustomerRepository;
  CustomersFuture: IFuture<TCustomerList>;
begin
  Repository := TRepositoryFactory.CreateCustomerRepository;
  CustomersFuture := Repository.GetCustomersAsync;
  RunAsync(
    procedure
     var
      Customers: TCustomerList;
    begin
      Customers := CustomersFuture.Value;

      // Atualiza cache local
      TThread.Synchronize(nil,
        procedure
        begin
          FCustomers.Clear;
          FCustomers.AddRange(Customers);
          Customers.OwnsObjects := False; // Controller agora é o owner
        end);

      TThread.Queue(nil,
        procedure
        begin
          Callbacks.OnCustomersLoaded(Customers);
        end);
    end, Callbacks);
end;

procedure TController.SaveCustomer(Customer: TCustomer;
  const Callbacks: ICustomerCallbacks);
var
  Repository: ICustomerRepository;
  SaveTask: ITask;
begin
  if not ValidateCustomer(Customer) then
  begin
    Callbacks.OnError('Cliente inválido, verifique as informações.');
    Exit;
  end;

  Repository := TRepositoryFactory.CreateCustomerRepository;
  SaveTask := Repository.SaveCustomerAsync(Customer);

  RunAsync(
    procedure
    begin
      SaveTask.Wait;

      // Atualiza cache local
      TThread.Synchronize(nil,
        procedure
        var
          ExistingCustomer: TCustomer;
          I: Integer;
        begin
          ExistingCustomer := nil;
          for I := 0 to FCustomers.Count - 1 do
          begin
            if FCustomers[I].CustomerID = Customer.CustomerID then
            begin
              ExistingCustomer := FCustomers[I];
              Break;
            end;
          end;

          if Assigned(ExistingCustomer) then
          begin
            // Atualiza existente
            ExistingCustomer.Assign(Customer);
          end
          else
          begin
            // Adiciona novo
            FCustomers.Add(Customer);
            Customer := nil; // Prevent destruction
          end;
        end);

      TThread.Queue(nil,
        procedure
        begin
          if Assigned(Customer) then
            Callbacks.OnCustomerSaved(Customer)
          else
            Callbacks.OnCustomerSaved(FCustomers.Last);
        end);
    end, Callbacks);
end;

procedure TController.DeleteCustomer(const CustomerID: string;
  const Callbacks: ICustomerCallbacks);
var
  Repository: ICustomerRepository;
  DeleteTask: ITask;
begin
  Repository := TRepositoryFactory.CreateCustomerRepository;
  DeleteTask := Repository.DeleteCustomerAsync(CustomerID);

  RunAsync(
    procedure
    begin
      DeleteTask.Wait;

      // Remove do cache local
      TThread.Synchronize(nil,
        procedure
        var
          i: Integer;
        begin
          for i := FCustomers.Count - 1 downto 0 do
          begin
            if FCustomers[i].CustomerID = CustomerID then
            begin
              FCustomers.Delete(i);
              Break;
            end;
          end;
        end);

      TThread.Queue(nil,
        procedure
        begin
          Callbacks.OnCustomerDeleted(CustomerID);
        end);
    end, Callbacks);
end;

procedure TController.LoadOrdersForCustomer(const CustomerID: string;
  const Callbacks: IOrderCallbacks);
var
  Repository: IOrderRepository;
  OrdersFuture: IFuture<TOrderList>;
  Customer: TCustomer;
  I: Integer;
begin
  // Encontra o cliente no cache
  Customer := nil;
  for I := 0 to FCustomers.Count - 1 do
  begin
    if FCustomers[I].CustomerID = CustomerID then
    begin
      Customer := FCustomers[I];
      Break;
    end;
  end;

  if not Assigned(Customer) then
  begin
    Callbacks.OnError('Cliente năo encontrado no cache');
    Exit;
  end;

  Repository := TRepositoryFactory.CreateOrderRepository;
  OrdersFuture := Repository.GetOrdersForCustomerAsync(CustomerID);

  RunAsync(
    procedure
    var
      Orders: TOrderList;
    begin
      Orders := OrdersFuture.Value;

      // Atualiza cache local no cliente
      TThread.Synchronize(nil,
        procedure
        begin
          Customer.ClearOrders;
          for var Order in Orders do
          begin
            Customer.AddOrder(Order);
          end;
          Orders.OwnsObjects := False; // Cliente agora é o owner
        end);

      TThread.Queue(nil,
        procedure
        begin
          Callbacks.OnOrdersLoaded(Orders);
        end);
    end, Callbacks);
end;

function TController.ValidateCustomer(const Customer: TCustomer): Boolean;
begin
  Result := False;

  if Customer.CustomerID.Trim.IsEmpty then
    Exit;

  if Customer.CompanyName.Trim.IsEmpty then
    Exit;

  if Customer.ContactName.Trim.IsEmpty then
    Exit;

  // Validaçăo de telefone (formato básico)
  if not Customer.Phone.Trim.IsEmpty and not IsValidPhone(Customer.Phone) then
    Exit;

  Result := True;
end;

function TController.GetCachedOrders(const CustomerID: string): TOrderList;
var
  Customer: TCustomer;
  I: Integer;
begin
  Result := nil;
  for I := 0 to FCustomers.Count - 1 do
  begin
    if FCustomers[I].CustomerID = CustomerID then
    begin
      Customer := FCustomers[I];
      if Assigned(Customer.Orders) and (Customer.Orders.Count > 0) then
      begin
        Result := TOrderList.Create(False);
        Result.AddRange(Customer.Orders.ToArray);
      end;
      Break;
    end;
  end;
end;

procedure TController.LoadAllOrders(const Callbacks: IOrderCallbacks);
var
  Repository: IOrderRepository;
  OrdersFuture: IFuture<TOrderList>;
begin
  Repository := TRepositoryFactory.CreateOrderRepository;
  OrdersFuture := Repository.GetAllOrdersAsync;

  RunAsync(
    procedure
    var
      Orders: TOrderList;
    begin
      Orders := OrdersFuture.Value;

      // Atualiza cache local
      TThread.Synchronize(nil,
        procedure
        begin
          FOrders.Clear;
          FOrders.AddRange(Orders);
          Orders.OwnsObjects := False; // Controller agora é o owner
        end);

      TThread.Queue(nil,
        procedure
        begin
          Callbacks.OnOrdersLoaded(Orders);
        end);
    end, Callbacks);
end;

procedure TController.CreateOrder(Order: TOrder; const Callbacks: IOrderCallbacks);
var
  Repository: IOrderRepository;
  SaveTask: ITask;
begin
  if not ValidateOrder(Order) then
  begin
    Callbacks.OnError('Pedido inválido, verifique as informações.');
    Exit;
  end;

  Repository := TRepositoryFactory.CreateOrderRepository;
  SaveTask := Repository.SaveOrderAsync(Order);

  RunAsync(
    procedure
    begin
      SaveTask.Wait;

      // Atualiza cache local
      TThread.Synchronize(nil,
        procedure
        begin
          FOrders.Add(Order);
          Order := nil; // Prevent destruction
        end);

      TThread.Queue(nil,
        procedure
        begin
          if Assigned(Order) then
            Callbacks.OnOrderSaved(Order)
          else
            Callbacks.OnOrderSaved(FOrders.Last);
        end);
    end, Callbacks);
end;

procedure TController.UpdateOrder(Order: TOrder; const Callbacks: IOrderCallbacks);
var
  Repository: IOrderRepository;
  UpdateTask: ITask;
begin
  if not ValidateOrder(Order) then
  begin
    Callbacks.OnError('Pedido inválido, verifique as informações.');
    Exit;
  end;

  Repository := TRepositoryFactory.CreateOrderRepository;
  UpdateTask := Repository.UpdateOrderAsync(Order);

  RunAsync(
    procedure
    begin
      UpdateTask.Wait;

      // Atualiza cache local
      TThread.Synchronize(nil,
        procedure
        var
          ExistingOrder: TOrder;
        begin
          ExistingOrder := nil;
          for var I := 0 to FOrders.Count - 1 do
          begin
            if FOrders[I].OrderID = Order.OrderID then
            begin
              ExistingOrder := FOrders[I];
              Break;
            end;
          end;

          if Assigned(ExistingOrder) then
          begin
            // Atualiza existente
            ExistingOrder.Assign(Order);
          end;
        end);

      TThread.Queue(nil,
        procedure
        begin
          Callbacks.OnOrderSaved(Order);
        end);
    end, Callbacks);
end;

procedure TController.DeleteOrder(const OrderID: Integer;
  const Callbacks: IOrderCallbacks);
var
  Repository: IOrderRepository;
  DeleteTask: ITask;
begin
  Repository := TRepositoryFactory.CreateOrderRepository;
  DeleteTask := Repository.DeleteOrderAsync(OrderID);

  RunAsync(
    procedure
    begin
      DeleteTask.Wait;

      // Remove do cache local
      TThread.Synchronize(nil,
        procedure
        var
          i: Integer;
        begin
          for i := FOrders.Count - 1 downto 0 do
          begin
            if FOrders[i].OrderID = OrderID then
            begin
              FOrders.Delete(i);
              Break;
            end;
          end;
        end);

      TThread.Queue(nil,
        procedure
        begin
          Callbacks.OnOrderDeleted(OrderID);
        end);
    end, Callbacks);
end;

function TController.GetCustomers: TCustomerList;
begin
  Result := FCustomers;
end;

function TController.GetOrders: TOrderList;
begin
  Result := FOrders;
end;

function TController.ValidateOrder(const Order: TOrder): Boolean;
begin
  Result := False;

  if Order.CustomerID.Trim.IsEmpty then
    Exit;

  if Order.OrderDate = 0 then
    Exit;

  // Validaçăo de datas: OrderDate <= ShippedDate <= RequiredDate
  if (Order.ShippedDate > 0) and (Order.ShippedDate < Order.OrderDate) then
    Exit;

  if (Order.RequiredDate > 0) and (Order.RequiredDate < Order.OrderDate) then
    Exit;

  if (Order.ShippedDate > 0) and (Order.RequiredDate > 0) and
     (Order.ShippedDate > Order.RequiredDate) then
    Exit;

  // Validaçăo de frete
  if Order.Freight < 0 then
    Exit;

  Result := True;
end;

function TController.IsValidPhone(const Phone: string): Boolean;
begin
  // Validaçăo básica - permite números, espaços, paręnteses, hífens
  Result := TRegEx.IsMatch(Phone, '^[\d\s\(\)\-+]+$');
end;

end.
