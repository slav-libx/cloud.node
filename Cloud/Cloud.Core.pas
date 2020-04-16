unit Cloud.Core;

interface

uses
  System.SysUtils,
  System.Classes,
  App.Intf,
  Cloud.Types,
  Cloud.Consts,
  Cloud.Client,
  Cloud.Log,
  Cloud.Utils;

type
  TCloudCore = class(TCloudDelegate)
  private type
    TRequest = (None,Login,Balance,Transfer,Ratio,Forging);
  private
    Client: TCloudClient;
    Request: TRequest;
    FShowEventMessages: Boolean;
    procedure DoExcept(const Text: string);
    function DoConnected: Boolean;
  private
    RegistrationProc: TProc;
    LoginProc: TProc;
    BalanceProc: TProc;
    CreateAddressProc: TProc;
    RatioProc: TProc;
    TransferProc: TProc;
    ForgingProc: TProc;
  private
    procedure OnEvent(Event: TCloudEvent; const Text: string); override;
    procedure OnInit(const Init: TCloudResponseInit); override;
    procedure OnError(const Error: TCloudResponseError); override;
    procedure OnRegistration(const Registration: TCloudResponseRegistration); override;
    procedure OnLogin(const Login: TCloudResponseLogin); override;
    procedure OnAddresses(const Addresses: TCloudResponseGetAddresses); override;
    procedure OnCreateAddress(const Address: TCloudResponseCreateAddress); override;
    procedure OnTransactions(const Transactions: TCloudResponseTransactions); override;
    procedure OnAddress(const Address: TCloudResponseCurrentAddresses); override;
    procedure OnInfo(const Info: TCloudResponseInfo); override;
    procedure OnSendTo(const SendTo: TCloudResponseSendTo); override;
    procedure OnRatio(const Ratio: TCloudResponseRatio); override;
    procedure OnRequestForging(const Forging: TCloudRequestForging); override;
    procedure OnForging(const Forging: TCloudResponseForging); override;
  public
    constructor Create; overload;
    constructor Create(const Host: string; Port: Word); overload;
    destructor Destroy; override;
    function Workloaded: Boolean;
    procedure Connect;
    procedure Disconnect;
    procedure Unauthorized;
    procedure Cancel;
    procedure SetAuth(const Email,Password: string; AccountID: Int64);
    procedure SetKeepAlive(KeepAlive: Boolean; RecoveryInterval: Cardinal);
    procedure SendRequestLogin;
    procedure SendRequestBalance(const Symbol: string);
    procedure SendRequestTransfer(const Symbol,Address: string; Amount: Extended);
    procedure SendRequestRatio;
    procedure SendRequestForging(Owner,TokenID: Int64; const Symbol: string;
      BuyAmount,PayAmount,Ratio,Commission1,Commission2: Extended);
    property ShowEventMessages: Boolean read FShowEventMessages write FShowEventMessages;
  end;

implementation

constructor TCloudCore.Create;
begin
  Client:=TCloudClient.Create;
  Client.SetDelegate(Self);
end;

constructor TCloudCore.Create(const Host: string; Port: Word);
begin
  Create;
  Client.SetEndPoint(Host,Port);
end;

destructor TCloudCore.Destroy;
begin
  Client.Free;
  inherited;
end;

function TCloudCore.Workloaded: Boolean;
begin
  Result:=Client.Workloaded;
end;

procedure TCloudCore.DoExcept(const Text: string);
begin

  ToLog('error:'+Text);

  Request:=None;

  UI.WaitCancel;

  UI.ShowException(Text);

  UI.WaitUnlock;

end;

function TCloudCore.DoConnected: Boolean;
begin

  Result:=True;

  if not Client.Connected then
    Client.Connect
  else

  if not Client.Authorized then

    LoginProc

  else
    Result:=False;

end;

procedure TCloudCore.OnEvent(Event: TCloudEvent; const Text: string);
begin

  ToLog(Text);

  if ShowEventMessages then

  case Event of
  EVENT_REQUEST: UI.ShowMessage('>'+Text);
  EVENT_RESPONSE: UI.ShowMessage('<'+Text);
  EVENT_EXCEPT: UI.ShowMessage(Text);
  else UI.ShowMessage(Text);
  end;

end;

procedure TCloudCore.OnError(const Error: TCloudResponseError);
begin

  ToLog(Error);

  if Error.Code='816' then RegistrationProc;

  case Request of
  Balance:

    if Error.Code='780' then CreateAddressProc;

  Transfer:
  begin

    if Error.Code='781' then DoExcept(Error.ErrorString);
    if Error.Code='782' then DoExcept(Error.ErrorString);
    if Error.Code='783' then DoExcept(Error.ErrorString);

  end;

  Ratio: ;

  end;

end;

procedure TCloudCore.OnInit(const Init: TCloudResponseInit);
begin
  if Request<>None then LoginProc;
end;

procedure TCloudCore.OnRegistration(const Registration: TCloudResponseRegistration);
begin
  LoginProc;
end;

procedure TCloudCore.OnLogin(const Login: TCloudResponseLogin);
begin

  case Request of
  TRequest.Login: UI.WaitUnlock;
  Balance: BalanceProc;
  Transfer: TransferProc;
  Ratio: RatioProc;
  Forging: ForgingProc;
  end;

end;

procedure TCloudCore.OnInfo(const Info: TCloudResponseInfo);
begin

  case Request of
  Balance,Transfer:
  begin
    Request:=None;
    UI.WaitCancel;
    AppCore.DoCloudBalance(Info.Address,Info.Amount,PortToSymbol(Info.Port));
    UI.WaitUnlock;
  end;
  end;

end;

procedure TCloudCore.OnAddresses(const Addresses: TCloudResponseGetAddresses);
begin

end;

procedure TCloudCore.OnCreateAddress(const Address: TCloudResponseCreateAddress);
begin

  case Request of
  Balance: BalanceProc;
  end;

end;

procedure TCloudCore.OnTransactions(const Transactions: TCloudResponseTransactions);
begin

end;

procedure TCloudCore.OnAddress(const Address: TCloudResponseCurrentAddresses);
begin

end;

procedure TCloudCore.OnSendTo(const SendTo: TCloudResponseSendTo);
begin

  case Request of
  Transfer: BalanceProc;
  end;

end;

procedure TCloudCore.OnRatio(const Ratio: TCloudResponseRatio);
begin

  Request:=None;

  UI.WaitCancel;

  AppCore.DoCloudRatio('BTC',Ratio.RatioBTC);
  AppCore.DoCloudRatio('LTC',Ratio.RatioLTC);
  AppCore.DoCloudRatio('ETH',Ratio.RatioETH);

  UI.WaitUnlock;

end;

procedure TCloudCore.OnRequestForging(const Forging: TCloudRequestForging);
var R: string;
begin

  R:='0';

  try

    AppCore.DoForging(Forging.Owner,Forging.Buyer,Forging.BuyToken,Forging.BuyAmount,
      Forging.Commission1,Forging.Commission2);

    R:='1';

  except on E: Exception do
    ToLog('Exception: '+E.Message);
  end;

  Client.SendResponseForging(Forging.Request,R);

end;

procedure TCloudCore.OnForging(const Forging: TCloudResponseForging);
begin

  Request:=None;

  UI.WaitCancel;

  AppCore.DoCloudForgingResult(Forging.Tx);

  UI.WaitUnlock;

end;

procedure TCloudCore.Connect;
begin
  Client.Connect;
end;

procedure TCloudCore.Disconnect;
begin
  UI.ShowMessage('Disconnected');
  Client.Disconnect;
end;

procedure TCloudCore.Unauthorized;
begin
  UI.ShowMessage('Unauthorized');
  Client.Unauthorized;
end;

procedure TCloudCore.Cancel;
begin
  Request:=None;
  Client.Cancel;
end;

procedure TCloudCore.SetAuth(const Email,Password: string; AccountID: Int64);
begin

  Client.Unauthorized;

  RegistrationProc:=procedure
  begin
    Client.SendRequestRegistration(Email,Password,AccountID);
  end;

  LoginProc:=procedure
  begin
    Client.SendRequestLogin(Email,Password);
  end;

end;

procedure TCloudCore.SetKeepAlive(KeepAlive: Boolean; RecoveryInterval: Cardinal);
begin
  Client.KeepAlive:=KeepAlive;
  Client.SetRecoveryInterval(RecoveryInterval);
end;

procedure TCloudCore.SendRequestLogin;
begin

  ToLog('Execute login');

  Client.Unauthorized;

  Request:=Login;

  UI.WaitLock;

  DoConnected;

end;

procedure TCloudCore.SendRequestBalance(const Symbol: string);
var Port: string;
begin

  ToLog('Execute request balance '+Symbol);

  Request:=Balance;

  UI.WaitLock;

  Port:=SymbolToPort(Symbol);

  BalanceProc:=procedure
  begin
    Client.SendRequestInfo(Port);
  end;

  CreateAddressProc:=procedure
  begin
    Client.SendRequestCreateAddress(Port);
  end;

  if Port='' then

    DoExcept('forbidden coin')

  else

    if not DoConnected then BalanceProc;

end;

procedure TCloudCore.SendRequestTransfer(const Symbol,Address: string; Amount: Extended);
var Port: string;
begin

  ToLog('Execute request transfer '+AmountToStr(Amount)+' '+Symbol+' to '+ Address);

  Request:=Transfer;

  UI.WaitLock;

  Port:=SymbolToPort(Symbol);

  TransferProc:=procedure
  begin
    Client.SendRequestSendTo(Address,Amount,6,Port);
  end;

  BalanceProc:=procedure
  begin
    Client.SendRequestInfo(Port);
  end;

  if Port='' then

    DoExcept('forbidden coin')

  else

    if not DoConnected then TransferProc;

end;

procedure TCloudCore.SendRequestRatio;
begin

  ToLog('Execute request ratio');

  Request:=Ratio;

  UI.WaitLock;

  RatioProc:=procedure
  begin
    Client.SendRequestRatio;
  end;

  if not DoConnected then RatioProc;

end;

procedure TCloudCore.SendRequestForging(Owner,TokenID: Int64; const Symbol: string;
  BuyAmount,PayAmount,Ratio,Commission1,Commission2: Extended);
var Port: string;
begin

  ToLog('Execute request forging TokenID='+TokenID.ToString+' '+AmountToStr(BuyAmount)+' '+
    AmountToStr(PayAmount)+' '+Symbol+' to AccountID='+Owner.ToString);

  Request:=Forging;

  UI.WaitLock;

  Port:=SymbolToPort(Symbol);

  ForgingProc:=procedure
  begin

    Client.SendRequestForging(Owner,TokenID,Port,BuyAmount,PayAmount,Ratio,
      Commission1,Commission2);

  end;

  if Port='' then

    DoExcept('forbidden coin')

  else

    if not DoConnected then ForgingProc;

end;

end.
