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

  TInfoProc = reference to procedure(const Info: TCloudResponseInfo);
  TErrorProc = reference to procedure(const Error: TCloudResponseError);

  TCloudCore = class(TCloudDelegate)
  private
    Client: TCloudClient;
    FShowEventMessages: Boolean;
    procedure DoExcept(const Text: string);
    procedure DoConnection;
    procedure ExecuteBeginProc;
  private
    DoRegistrationProc: TProc;
    DoLoginProc: TProc;
    DoConnectProc: TProc;
    DoBeginProc: TProc;
    DoErrorProcDefault: TErrorProc;
    DoErrorProc: TErrorProc;
    DoInfoProc: TInfoProc;
    DoCreateAddressProc: TProc;
    DoSendToProc: TProc;
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

  DoErrorProcDefault:=procedure(const Error: TCloudResponseError)
  begin
    if Error.Code='816' then
      DoRegistrationProc
    else
      DoExcept(Error.ErrorString);
  end;

  SetAuth('','',0);

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

  UI.WaitCancel;
  UI.ShowException(Text);
  UI.WaitUnlock;

end;

procedure TCloudCore.DoConnection;
begin

  if not Client.Connected then
    Client.Connect
  else if not Client.Authorized then
    DoLoginProc
  else
    ExecuteBeginProc;

end;

procedure TCloudCore.OnEvent(Event: TCloudEvent; const Text: string);
begin

  ToLog(Text);

  if ShowEventMessages then

  case Event of
  EVENT_REQUEST: UI.ShowMessage('>'+Text);
  EVENT_RESPONSE: UI.ShowMessage('<'+Text);
  else UI.ShowMessage(Text);
  end;

end;

procedure TCloudCore.OnError(const Error: TCloudResponseError);
begin
  ToLog(Error);
  DoErrorProc(Error);
end;

procedure TCloudCore.OnInit(const Init: TCloudResponseInit);
begin
  DoConnectProc;
end;

procedure TCloudCore.OnRegistration(const Registration: TCloudResponseRegistration);
begin
  DoLoginProc;
end;

procedure TCloudCore.OnLogin(const Login: TCloudResponseLogin);
begin
  ExecuteBeginProc;
end;

procedure TCloudCore.OnInfo(const Info: TCloudResponseInfo);
begin
  DoInfoProc(Info);
end;

procedure TCloudCore.OnAddresses(const Addresses: TCloudResponseGetAddresses);
begin

end;

procedure TCloudCore.OnCreateAddress(const Address: TCloudResponseCreateAddress);
begin
  DoCreateAddressProc;
end;

procedure TCloudCore.OnTransactions(const Transactions: TCloudResponseTransactions);
begin

end;

procedure TCloudCore.OnAddress(const Address: TCloudResponseCurrentAddresses);
begin

end;

procedure TCloudCore.OnSendTo(const SendTo: TCloudResponseSendTo);
begin
  DoSendToProc;
end;

procedure TCloudCore.OnRatio(const Ratio: TCloudResponseRatio);
begin

  UI.WaitCancel;

  AppCore.DoCloudRatio(Ratio.RatioBTC,Ratio.RatioLTC,Ratio.RatioETH);

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

  if Forging.Result=1 then
  begin
    UI.WaitCancel;
    AppCore.DoCloudForgingResult(Forging.Tx);
    UI.WaitUnlock;
  end else
    DoExcept('error');

end;

procedure TCloudCore.Connect;
begin

  Cancel;

  DoConnectProc:=procedure begin end;

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
  DoBeginProc:=nil;
  Client.Cancel;
end;

procedure TCloudCore.ExecuteBeginProc;
begin
  if Assigned(DoBeginProc) then
  begin
    DoBeginProc;
    DoBeginProc:=nil;
  end;
end;

procedure TCloudCore.SetAuth(const Email,Password: string; AccountID: Int64);
begin

  Client.Unauthorized;

  DoConnectProc:=DoLoginProc;

  DoErrorProc:=DoErrorProcDefault;

  DoRegistrationProc:=procedure
  begin
    Client.SendRequestRegistration(Email,Password,AccountID);
  end;

  DoLoginProc:=procedure
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

  DoConnectProc:=DoLoginProc;

  DoErrorProc:=DoErrorProcDefault;

  DoBeginProc:=procedure
  begin
    UI.WaitUnlock;
  end;

  UI.WaitLock;

  DoConnection;

end;

procedure TCloudCore.SendRequestBalance(const Symbol: string);
var Port: string;
begin

  ToLog('Execute request balance '+Symbol);

  UI.WaitLock;

  Port:=SymbolToPort(Symbol);

  DoConnectProc:=DoLoginProc;

  DoErrorProc:=procedure(const Error: TCloudResponseError)
  begin
    if Error.Code='780' then
      Client.SendRequestCreateAddress(Port)
    else
      DoErrorProcDefault(Error);
  end;

  DoBeginProc:=procedure
  begin
    Client.SendRequestInfo(Port);
  end;

  DoCreateAddressProc:=DoBeginProc;

  DoInfoProc:=procedure(const Info: TCloudResponseInfo)
  begin
    UI.WaitCancel;
    AppCore.DoCloudBalance(Info.Address,Info.Amount,PortToSymbol(Info.Port,Symbol));
    UI.WaitUnlock;
  end;

  if Port='' then
    DoExcept('forbidden coin')
  else
    DoConnection;

end;

procedure TCloudCore.SendRequestTransfer(const Symbol,Address: string; Amount: Extended);
var Port: string;
begin

  ToLog('Execute request transfer '+AmountToStr(Amount)+' '+Symbol+' to '+ Address);

  UI.WaitLock;

  Port:=SymbolToPort(Symbol);

  DoConnectProc:=DoLoginProc;

  DoErrorProc:=DoErrorProcDefault;

  DoBeginProc:=procedure
  begin
    Client.SendRequestSendTo(Address,Amount,6,Port);
  end;

  DoInfoProc:=procedure(const Info: TCloudResponseInfo)
  begin
    UI.WaitCancel;
    AppCore.DoCloudBalance(Info.Address,Info.Amount,PortToSymbol(Info.Port,Symbol));
    UI.WaitUnlock;
  end;

  DoSendToProc:=procedure
  begin
    Client.SendRequestInfo(Port);
  end;

  if Port='' then
    DoExcept('forbidden coin')
  else
    DoConnection;

end;

procedure TCloudCore.SendRequestRatio;
begin

  ToLog('Execute request ratio');

  UI.WaitLock;

  DoConnectProc:=DoLoginProc;

  DoErrorProc:=DoErrorProcDefault;

  DoBeginProc:=procedure
  begin
    Client.SendRequestRatio;
  end;

  DoConnection;

end;

procedure TCloudCore.SendRequestForging(Owner,TokenID: Int64; const Symbol: string;
  BuyAmount,PayAmount,Ratio,Commission1,Commission2: Extended);
var Port: string;
begin

  ToLog('Execute request forging TokenID='+TokenID.ToString+' '+AmountToStr(BuyAmount)+' '+
    AmountToStr(PayAmount)+' '+Symbol+' to AccountID='+Owner.ToString);

  UI.WaitLock;

  Port:=SymbolToPort(Symbol);

  DoConnectProc:=DoLoginProc;

  DoErrorProc:=DoErrorProcDefault;

  DoBeginProc:=procedure
  begin
    Client.SendRequestForging(Owner,TokenID,Port,BuyAmount,PayAmount,Ratio,
      Commission1,Commission2);
  end;

  if Port='' then
    DoExcept('forbidden coin')
  else
    DoConnection;

end;

end.
