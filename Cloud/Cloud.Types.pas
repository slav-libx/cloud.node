unit Cloud.Types;

interface

uses
  System.SysUtils,
  System.DateUtils,
  System.JSON,
  Cloud.Utils;

type
  TCloudEvent = (EVENT_CONNECTING,EVENT_CONNECTED,EVENT_DISCONNECTED,
    EVENT_REQUEST,EVENT_RESPONSE,EVENT_EXCEPT);

  TCloudTransaction = record
  public
    ID: string;
    Address: string;
    Operation: string;
    Date: TDateTime;
    Amount: Extended;
    Confirmations: Int64;
    class operator Implicit(const S: string): TCloudTransaction;
    class operator Implicit(const Transaction: TCloudTransaction): string;
  end;

  TCloudResponse = record
    Command: string;
    Args: string;
    class operator Implicit(const S: string): TCloudResponse;
  end;

  TCloudResponseError = record
    Code: string;
    function ErrorString: string;
    class operator Implicit(const S: string): TCloudResponseError;
    class operator Implicit(const Response: TCloudResponse): TCloudResponseError;
    class operator Implicit(const Error: TCloudResponseError): string;
  end;

  TCloudResponseLogin = record
    AccountID: string;
    AccessToken: string;
    class operator Implicit(const S: string): TCloudResponseLogin;
    class operator Implicit(const Response: TCloudResponse): TCloudResponseLogin;
  end;

  TCloudAddress = string;

  TCloudAddresses = array of TCloudAddress;

  TCloudAddressesHelper = record helper for TCloudAddresses
    function IsEmpty: Boolean;
  end;

  TCloudResponseGetAddresses = record
    Addresses: TCloudAddresses;
    Error: Boolean;
    ErrorText: string;
    class operator Implicit(const S: string): TCloudResponseGetAddresses;
    class operator Implicit(const Response: TCloudResponse): TCloudResponseGetAddresses;
  end;

  TCloudTransactions = array of TCloudTransaction;

  TCloudResponseTransactions = record
    Transactions: TCloudTransactions;
    class operator Implicit(const S: string): TCloudResponseTransactions;
    class operator Implicit(const Response: TCloudResponse): TCloudResponseTransactions;
  end;

  TCloudResponseCreateAddress = record
    Address: TCloudAddress;
    Error: Boolean;
    ErrorText: string;
    class operator Implicit(const S: string): TCloudResponseCreateAddress;
    class operator Implicit(const Response: TCloudResponse): TCloudResponseCreateAddress;
  end;

  TCloudResponseInit = record
    ConnectionID: string;
    class operator Implicit(const S: string): TCloudResponseInit;
    class operator Implicit(const Response: TCloudResponse): TCloudResponseInit;
  end;

  TCloudResponseRegistration = record
    AccountID: string;
    class operator Implicit(const S: string): TCloudResponseRegistration;
    class operator Implicit(const Response: TCloudResponse): TCloudResponseRegistration;
  end;

  TCloudResponseCurrentAddresses = record
    AddressBTC: TCloudAddress;
    AddressLTC: TCloudAddress;
    AddressETH: TCloudAddress;
    class operator Implicit(const S: string): TCloudResponseCurrentAddresses;
    class operator Implicit(const Addresses: TCloudResponseCurrentAddresses): string;
    class operator Implicit(const Response: TCloudResponse): TCloudResponseCurrentAddresses;
  end;

  TCloudResponseInfo = record
    Address: TCloudAddress;
    Amount: Extended;
    Port: string;
    class operator Implicit(const S: string): TCloudResponseInfo;
    class operator Implicit(const Info: TCloudResponseInfo): string;
    class operator Implicit(const Response: TCloudResponse): TCloudResponseInfo;
  end;

  TCloudResponseSendTo = record
    Tx: string;
    class operator Implicit(const S: string): TCloudResponseSendTo;
    class operator Implicit(const SendTo: TCloudResponseSendTo): string;
    class operator Implicit(const Response: TCloudResponse): TCloudResponseSendTo;
  end;

  TCloudResponseRatio = record
    RatioBTC: Extended;
    RatioLTC: Extended;
    RatioETH: Extended;
    class operator Implicit(const S: string): TCloudResponseRatio;
    class operator Implicit(const Ratio: TCloudResponseRatio): string;
    class operator Implicit(const Response: TCloudResponse): TCloudResponseRatio;
  end;

  TCloudRequestForging = record
    Owner: Int64;
    Buyer: Int64;
    BuyToken: Int64;
    PayPort: string;
    BuyAmount: Extended;
    PayAmount: Extended;
    Ratio: Extended;
    Commission1: Extended;
    Commission2: Extended;
    Request: string;
    class operator Implicit(const S: string): TCloudRequestForging;
    class operator Implicit(const Forging: TCloudRequestForging): string;
    class operator Implicit(const Response: TCloudResponse): TCloudRequestForging;
  end;

  TCloudResponseForging = record
    Tx: string;
    Result: Integer;
    class operator Implicit(const S: string): TCloudResponseForging;
    class operator Implicit(const Forging: TCloudResponseForging): string;
    class operator Implicit(const Response: TCloudResponse): TCloudResponseForging;
  end;

  TCloudDelegate = class abstract
    procedure OnEvent(Event: TCloudEvent; const Text: string); virtual; abstract;
    procedure OnInit(const Init: TCloudResponseInit); virtual; abstract;
    procedure OnError(const Error: TCloudResponseError); virtual; abstract;
    procedure OnRegistration(const Registration: TCloudResponseRegistration); virtual; abstract;
    procedure OnLogin(const Login: TCloudResponseLogin); virtual; abstract;
    procedure OnAddresses(const Addresses: TCloudResponseGetAddresses); virtual; abstract;
    procedure OnCreateAddress(const Address: TCloudResponseCreateAddress); virtual; abstract;
    procedure OnTransactions(const Transactions: TCloudResponseTransactions); virtual; abstract;
    procedure OnAddress(const Address: TCloudResponseCurrentAddresses); virtual; abstract;
    procedure OnInfo(const Info: TCloudResponseInfo); virtual; abstract;
    procedure OnSendTo(const SendTo: TCloudResponseSendTo); virtual; abstract;
    procedure OnRatio(const Ratio: TCloudResponseRatio); virtual; abstract;
    procedure OnRequestForging(const Forging: TCloudRequestForging); virtual; abstract;
    procedure OnForging(const Forging: TCloudResponseForging); virtual; abstract;
end;

implementation

{ TCloudTransaction }

class operator TCloudTransaction.Implicit(const S: string): TCloudTransaction;
var Args: TArray<string>;
begin

  // 2MtTqBASvfDoyx7QZCRFcdj3EcRB8bDzKqz receive 1585731173 0.00010000 282
  // 3a78181b4dbb4c84e6e057c85c8ad832c3938f6102e7dc4eda217107d6867c05

  Args:=S.Split([' ']);

  Result.ID:=Args[5];
  Result.Address:=Args[0];
  Result.Operation:=Args[1];
  Result.Date:=UnixToDateTime(Args[2].ToInt64,False);
  Result.Amount:=StrToFloat(Args[3],FormatSettings.Invariant);
  Result.Confirmations:=StrToInt64(Args[4]);

end;

class operator TCloudTransaction.Implicit(const Transaction: TCloudTransaction): string;
begin

  Result:='tx:'+Transaction.ID+
    ' address:'+Transaction.Address+
    ' operation:'+Transaction.Operation+
    ' date:'+DateToISO8601(Transaction.Date)+
    ' amount:'+AmountToStr(Transaction.Amount)+
    ' confirmations:'+Transaction.Confirmations.ToString;

end;

{ TCloudResponse }

class operator TCloudResponse.Implicit(const S: string): TCloudResponse;
var I: Integer;
begin

  I:=S.IndexOfAny([' ']);
  if I=-1 then I:=Length(S);

  Result.Command:=S.Substring(0,I);
  Result.Args:=S.Substring(I+1);

end;

{ TCloudResponseError }

function TCloudResponseError.ErrorString: string;
begin

  if Code='20' then Exit('not authorized');
  if Code='23' then Exit('invalid email');
  if Code='93' then Exit('wrong password');
  if Code='211' then Exit('invalid refer');
  if Code='444' then Exit('account not have address');
  if Code='780' then Exit('address not found');
  if Code='781' then Exit('incorrect response from server');
  if Code='782' then Exit('insufficient funds');
  if Code='783' then Exit('no unspent transactions');
  if Code='816' then Exit('account not found');
  if Code='829' then Exit('duplicate email');

  if Code='1001' then Exit('wrong pay coin');
  if Code='1002' then Exit('wrong buy coin');
  if Code='1003' then Exit('wrong pay amount');
  if Code='1006' then Exit('owner offline');
  if Code='1007' then Exit('wrong destination');
  if Code='1008' then Exit('wrong ratio');

  Result:='';

end;

class operator TCloudResponseError.Implicit(const S: string): TCloudResponseError;
var Args: TArray<string>;
begin

  // U20 * 829

  Args:=S.Split([' '],'<','>');

  Result.Code:=Args[2];

end;

class operator TCloudResponseError.Implicit(const Response: TCloudResponse): TCloudResponseError;
begin
  Result:=Response.Args;
end;

class operator TCloudResponseError.Implicit(const Error: TCloudResponseError): string;
begin

  Result:=Error.ErrorString;

  if Result='' then
    Result:=Error.Code
  else
    Result:=Error.Code+':'+Result;

end;

{ TCloudResponseStartClient }

class operator TCloudResponseLogin.Implicit(const S: string): TCloudResponseLogin;
var Args: TArray<string>;
begin

  // U24 ipaltEriXoUVSDF7EC7xNmq7RhUnK1rH6h 1 23

  Args:=S.Split([' '],'<','>');

  Result.AccountID:=Args[3];
  Result.AccessToken:=Args[1];

end;

class operator TCloudResponseLogin.Implicit(const Response: TCloudResponse): TCloudResponseLogin;
begin
  Result:=Response.Args;
end;

{ TCloudAddressesHelper }

function TCloudAddressesHelper.IsEmpty: Boolean;
begin
  Result:=Length(Self)=0;
end;

{ TCloudResponseGetCloudAdreses }

class operator TCloudResponseGetAddresses.Implicit(const S: string): TCloudResponseGetAddresses;
var
  jsObject: TJSONObject;
  Args: TArray<string>;
begin

  // U25 ipaSPCvJPlJSCkWJSJhMe1mBwjgAfBt4kD
  // {"result":{"2MtTqBASvfDoyx7QZCRFcdj3EcRB8bDzKqz":{"purpose":"receive"},
  // "2MwmFMxzDavxgyYE69p5yw2xNyvRJ9f5Mtc":{"purpose":"receive"}},"error":null,"id":"BTCExposed"}

  Args:=S.Split([' '],'{','}');

  Result:=Default(TCloudResponseGetAddresses);

  jsObject:=TJSONObject.ParseJSONValue(Args[2]) as TJSONObject;

  if Assigned(jsObject) then
  begin

    Result.Error:=not jsObject.Values['error'].Null;

    if Result.Error then

      Result.ErrorText:=jsObject.GetValue<string>('error')

    else

      for var P in jsObject.GetValue<TJSONObject>('result') do
        Result.Addresses:=Result.Addresses+[P.JsonString.Value];

    jsObject.Free;

  end;

end;

class operator TCloudResponseGetAddresses.Implicit(const Response: TCloudResponse): TCloudResponseGetAddresses;
begin
  Result:=Response.Args;
end;

{ TCloudResponseListTransactions }

class operator TCloudResponseTransactions.Implicit(const S: string): TCloudResponseTransactions;
var Args: TArray<string>;
begin

  // U36 ipaebikmPfPya3jUixEHnSbCvAiKifRolN 3 <tx1> <tx2> <tx3>

  Args:=S.Split([' '],'<','>');

  Result:=Default(TCloudResponseTransactions);

  if Length(Args)>2 then
  for var I:=0 to StrToIntDef(Args[2],0)-1 do
  Result.Transactions:=Result.Transactions+[Args[3+I].Trim(['<','>'])];

end;

class operator TCloudResponseTransactions.Implicit(const Response: TCloudResponse): TCloudResponseTransactions;
begin
  Result:=Response.Args;
end;

{ TCloudResponseCreateNewAdres }

class operator TCloudResponseCreateAddress.Implicit(const S: string): TCloudResponseCreateAddress;
var
  jsObject: TJSONObject;
  Args: TArray<string>;
begin

  // U7 ipal2N680aCjPEam94DCjjL1RwtVb7VL6i {"result":"2MwmFMxzDavxgyYE69p5yw2xNyvRJ9f5Mtc",
  // "error":null,"id":"BTCExposed"}

  Args:=S.Split([' '],'{','}');

  Result:=Default(TCloudResponseCreateAddress);

  jsObject:=TJSONObject.ParseJSONValue(Args[2]) as TJSONObject;

  if Assigned(jsObject) then
  begin

    Result.Error:=not jsObject.Values['error'].Null;

    if Result.Error then

      Result.ErrorText:=jsObject.GetValue<string>('error')

    else

      Result.Address:=jsObject.GetValue<string>('result');

    jsObject.Free;

  end;

end;

class operator TCloudResponseCreateAddress.Implicit(const Response: TCloudResponse): TCloudResponseCreateAddress;
begin
  Result:=Response.Args;
end;

{ TCloudResponseInit }

class operator TCloudResponseInit.Implicit(const S: string): TCloudResponseInit;
var Args: TArray<string>;
begin

  // U101 *

  Args:=S.Split([' ']);

  Result.ConnectionID:=Args[0];

end;

class operator TCloudResponseInit.Implicit(const Response: TCloudResponse): TCloudResponseInit;
begin
  Result:=Response.Args;
end;

{ TCloudResponseRegLight }

class operator TCloudResponseRegistration.Implicit(const S: string): TCloudResponseRegistration;
var Args: TArray<string>;
begin

  // U7 23

  Args:=S.Split([' ']);

  Result.AccountID:=Args[1];

end;

class operator TCloudResponseRegistration.Implicit(const Response: TCloudResponse): TCloudResponseRegistration;
begin
  Result:=Response.Args;
end;

{ TCloudResponseGetAddress }

class operator TCloudResponseCurrentAddresses.Implicit(const S: string): TCloudResponseCurrentAddresses;
var
  Args: TArray<string>;
  L: Integer;
begin

  // U9 23 <2N7FbG7FkUpXtYJcRXe5wuM68wBv5bPEADT> <> <>

  Args:=S.Split([' '],'<','>');

  L:=Length(Args);

  Result:=Default(TCloudResponseCurrentAddresses);

  if L>2 then Result.AddressBTC:=Args[2].Trim(['<','>']);
  if L>3 then Result.AddressLTC:=Args[3].Trim(['<','>']);
  if L>4 then Result.AddressETH:=Args[4].Trim(['<','>']);

end;

class operator TCloudResponseCurrentAddresses.Implicit(const Addresses: TCloudResponseCurrentAddresses): string;
begin
  Result:=
    'BTC:'+Addresses.AddressBTC+' '+
    'LTC:'+Addresses.AddressLTC+' '+
    'ETH:'+Addresses.AddressETH;
end;

class operator TCloudResponseCurrentAddresses.Implicit(const Response: TCloudResponse): TCloudResponseCurrentAddresses;
begin
  Result:=Response.Args;
end;

{ TCloudResponseInfo }

class operator TCloudResponseInfo.Implicit(const S: string): TCloudResponseInfo;
var
  Args: TArray<string>;
  Value: string;
  P,L: Integer;
begin

  // U9 ipaVrAtleElE5ocnduDxylVeM20g58vfxm 2N7FbG7FkUpXtYJcRXe5wuM68wBv5bPEADT=0,00200000 18332

  Args:=S.Split([' ']);

  Result:=Default(TCloudResponseInfo);

  L:=Length(Args);

  if L>2 then
  begin

    Value:=Args[2];

    P:=Value.IndexOf('=');

    Result.Address:=Value.Substring(0,P);
    Result.Amount:=StrToAmount(Value.Substring(P+1));

  end;

  if L>3 then Result.Port:=Args[3];

end;

class operator TCloudResponseInfo.Implicit(const Info: TCloudResponseInfo): string;
begin
  Result:=Info.Address+'='+AmountToStr(Info.Amount)+' '+PortToSymbol(Info.Port);
end;

class operator TCloudResponseInfo.Implicit(const Response: TCloudResponse): TCloudResponseInfo;
begin
  Result:=Response.Args;
end;

{ TCloudResponseSendTo }

class operator TCloudResponseSendTo.Implicit(const S: string): TCloudResponseSendTo;
var Args: TArray<string>;
begin

  // U9 ipaVrAtleElE5ocnduDxylVeM20g58vfxm 308d8e07787bc9351250e1b714c39adb55177e53870ad6d944319e9ab52b28a0

  Args:=S.Split([' ']);

  Result.Tx:=Args[2];

end;

class operator TCloudResponseSendTo.Implicit(const SendTo: TCloudResponseSendTo): string;
begin
  Result:='tx:'+SendTo.Tx;
end;

class operator TCloudResponseSendTo.Implicit(const Response: TCloudResponse): TCloudResponseSendTo;
begin
  Result:=Response.Args;
end;


{ TCloudResponseRatio }

class operator TCloudResponseRatio.Implicit(const S: string): TCloudResponseRatio;
var
  Args: TArray<string>;
  L: Integer;
begin

  // U2 6879.295 * *

  Args:=S.Split([' '],'<','>');

  L:=Length(Args);

  Result:=Default(TCloudResponseRatio);

  if L>1 then Result.RatioBTC:=StrToAmountDef(Args[1],0);
  if L>2 then Result.RatioLTC:=StrToAmountDef(Args[2],0);
  if L>3 then Result.RatioETH:=StrToAmountDef(Args[3],0);

end;

class operator TCloudResponseRatio.Implicit(const Ratio: TCloudResponseRatio): string;
begin
  Result:=
    'BTC/USD='+AmountToStr(Ratio.RatioBTC)+' '+
    'LTC/USD='+AmountToStr(Ratio.RatioLTC)+' '+
    'ETH/USD='+AmountToStr(Ratio.RatioETH);
end;

class operator TCloudResponseRatio.Implicit(const Response: TCloudResponse): TCloudResponseRatio;
begin
  Result:=Response.Args;
end;

{ TCloudRequestForging }

class operator TCloudRequestForging.Implicit(const S: string): TCloudRequestForging;
var
  Args: TArray<string>;
  L: Integer;
begin

  // U2 * ipaSmp9xou4UhksvmK9iBxFXb0WcerHd8C 21 1 18332 25.00 0.000045 6456.543 0.00 0.00 12

  Args:=S.Split([' '],'<','>');

  L:=Length(Args);

  Result:=Default(TCloudRequestForging);

  Result.Request:=Skip(S,[' '],2);

  if L>3 then Result.Owner:=StrToInt64Def(Args[3],0);
  if L>4 then Result.BuyToken:=StrToInt64Def(Args[4],0);
  if L>5 then Result.PayPort:=Args[5];
  if L>6 then Result.BuyAmount:=StrToAmountDef(Args[6],0);
  if L>7 then Result.PayAmount:=StrToAmountDef(Args[7],0);
  if L>8 then Result.Ratio:=StrToAmountDef(Args[8],0);
  if L>9 then Result.Commission1:=StrToAmountDef(Args[9],0);
  if L>10 then Result.Commission2:=StrToAmountDef(Args[10],0);
  if L>11 then Result.Buyer:=StrToInt64Def(Args[11],0);

end;

class operator TCloudRequestForging.Implicit(const Forging: TCloudRequestForging): string;
begin
  Result:=
    AmountToStr(Forging.PayAmount)+' '+Forging.PayPort+' -> '+
    AmountToStr(Forging.BuyAmount)+' '+Forging.BuyToken.ToString;
end;

class operator TCloudRequestForging.Implicit(const Response: TCloudResponse): TCloudRequestForging;
begin
  Result:=Response.Args;
end;

{ TCloudResponseForging }

class operator TCloudResponseForging.Implicit(const S: string): TCloudResponseForging;
var
  Args: TArray<string>;
  L: Integer;
begin

  // U14 * 1

  Args:=S.Split([' '],'<','>');

  L:=Length(Args);

  Result:=Default(TCloudResponseForging);

  if L>2 then Result.Result:=StrToInt(Args[2]);
  if L>3 then Result.Tx:=Args[3];

end;

class operator TCloudResponseForging.Implicit(const Forging: TCloudResponseForging): string;
begin
  Result:=Forging.Result.ToString;
end;

class operator TCloudResponseForging.Implicit(const Response: TCloudResponse): TCloudResponseForging;
begin
  Result:=Response.Args;
end;

end.
