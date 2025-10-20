unit DelphiMultithreadingBook1004.PipelineTasks;

interface

uses
  System.Classes, System.Threading,
  DelphiMultithreadingBook.CancellationToken;

type
  TPipelineTasks = class
  public
    class function DownloadCustomerDataAsync(
      const Token: ICancellationToken): IFuture<TStrings>; static;
    class function DownloadProductDataAsync(
      const Token: ICancellationToken): IFuture<TStrings>; static;
    class function GenerateOrderReportAsync(const CustomerData, ProductData:
      TStrings; const Token: ICancellationToken): IFuture<string>; static;
  end;

implementation

uses
  System.SysUtils;

{ TPipelineTasks }

class function TPipelineTasks.DownloadCustomerDataAsync(
  const Token: ICancellationToken): IFuture<TStrings>;
begin
  Result := TTask.Future<TStrings>(
    function: TStrings
    var
      Customers: TStringList;
      i: Integer;
    begin
      // Simula trabalho, verificando o token periodicamente
      for i := 1 to 20 do
      begin
        // Lança exceção se cancelado
        Token.ThrowIfCancellationRequested;
        Sleep(100);
      end;
      Customers := TStringList.Create;
      Customers.Add('Cliente: 1 - Joao Silva');
      Customers.Add('Cliente: 2 - Maria Souza');
      Result := Customers;
    end);
end;

class function TPipelineTasks.DownloadProductDataAsync(
  const Token: ICancellationToken): IFuture<TStrings>;
begin
  Result := TTask.Future<TStrings>(
    function: TStrings
    var
      Products: TStringList;
      i: Integer;
    begin
      for i := 1 to 15 do
      begin
        Token.ThrowIfCancellationRequested;
        Sleep(100);
      end;
      Products := TStringList.Create;
      Products.Add('Produto: 101 - Notebook');
      Products.Add('Produto: 102 - Mouse');
      Result := Products;
    end);
end;

class function TPipelineTasks.GenerateOrderReportAsync(
  const CustomerData, ProductData: TStrings;
  const Token: ICancellationToken): IFuture<string>;
begin
  Result := TTask.Future<string>(
    function: string
    var
      i: Integer;
      Report: TStrings;
    begin
      for i := 1 to 10 do
      begin
        Token.ThrowIfCancellationRequested;
        Sleep(100);
      end;
      Report := TStringList.Create;
      try
        Report.Add(Format('Relatório Gerado: %d clientes e %d produtos.',
          [CustomerData.Count, ProductData.Count]));
        Report.Add('--- Clientes ---');
        Report.AddStrings(CustomerData);
        Report.Add('--- Produtos ---');
        Report.AddStrings(ProductData);
        Report.Add('----------------');
        Result :=  Report.Text;
      finally
        Report.Free;
      end;
    end);
end;

end.
