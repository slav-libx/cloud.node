unit Cloud.Client;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.DateUtils,
  Net.Socket,
  Lib.Timer,
  Cloud.Consts,
  Cloud.Types,
  Cloud.Utils;

type
  TCloudClient = class
  private
    KeepAliveTimer: TTimer;
    Delegate: TCloudDelegate;
    Client: TTCPSocket;
    Workload: Boolean;
    Host: string;
    Port: Word;
    ConnectionID: string;
    ReceiveString: string;
    AccessToken: string;
    function GetConnected: Boolean;
    function GetAuthorized: Boolean;
    function GetReady: Boolean;
    function GetAccessToken: string;
    procedure DoResponse(const S: string);
    procedure DoRecoveryConnection;
    procedure SendRequest(const Command,Args: string; const ShowArgs: string='');
    procedure SendResponse(const Command,Args: string);
    procedure OnKeepAliveTimer(Sender: TObject);
  private
    procedure OnClientConnect(Sender: TObject);
    procedure OnClientAfterConnect(Sender: TObject);
    procedure OnClientRead(Sender: TObject);
    procedure OnClientClose(Sender: TObject);
    procedure OnClientException(Sender: TObject);
  public
    KeepAlive: Boolean;
    constructor Create;
    destructor Destroy; override;
    procedure SetEndPoint(const Host: string; Port: Word);
    procedure SetRecoveryInterval(Interval: Cardinal);
    procedure SetDelegate(Delegate: TCloudDelegate);
    procedure Connect;
    procedure Disconnect;
    procedure Unauthorized;
    procedure Cancel;
    procedure SendRequestRaw(const Command: string);
    procedure SendRequestRegistration(const Email,Password: string; AccountID: Int64);
    procedure SendRequestLogin(const Email,Password: string);
    procedure SendRequestAddresses(const Port: string);
    procedure SendRequestTransactions(const Port: string);
    procedure SendRequestCreateAddress(const Port: string);
    procedure SendRequestAddress();
    procedure SendRequestInfo(const Port: string);
    procedure SendRequestSendTo(const Address: string; Amount: Extended;
      Confirm: Integer; const Port: string);
    procedure SendRequestRatio();
    procedure SendRequestForging(Owner,SymbolID: Integer; const PayPort: string;
      BuyAmount,PayAmount,Ratio,Commission1,Commission2: Extended);
    procedure SendResponseForging(const Request,Result: string);
    procedure SendResponseAccountBalance(AmountRLC,AmountGTN: Extended);
    procedure SendRequestCreateOffer(Direction,Coin1,Coin2: Integer;
      Amount,Ratio: Extended; EndDate: TDateTime);
    procedure SendRequestOffers(SymbolID1,SymbolID2: Integer);
    procedure SendRequestOfferAccount;
    procedure SendResponseTransfer;
    procedure SendResponseError(Code: Integer; const Text: string='');
    procedure SendRequestKillOffer(OfferID: Int64);
    procedure SendRequestActiveOffers;
    procedure SendRequestClosedOffers(BeginDate,EndDate: TDateTime);
    procedure SendRequestHistoryOffers(BeginDate,EndDate: TDateTime);
    procedure SendRequestPairsSummary;
    property Workloaded: Boolean read Workload;
    property Ready: Boolean read GetReady;
    property Connected: Boolean read GetConnected;
    property Authorized: Boolean read GetAuthorized;
  end;

implementation

{ TCloudClient }

constructor TCloudClient.Create;
begin

  Host:=CLOUD_DEFAULT_HOST;
  Port:=CLOUD_DEFAULT_PORT;

  Client:=TTCPSocket.Create;

  Client.OnConnect:=OnClientConnect;
  Client.OnAfterConnect:=OnClientAfterConnect;
  Client.OnReceived:=OnClientRead;
  Client.OnClose:=OnClientClose;
  Client.OnExcept:=OnClientException;

  KeepAliveTimer:=TTimer.Create(nil);
  KeepAliveTimer.Enabled:=False;
  KeepAliveTimer.OnTimer:=OnKeepAliveTimer;

  SetRecoveryInterval(4000);

end;

destructor TCloudClient.Destroy;
begin
  Client.Free;
  KeepAliveTimer.Free;
  inherited;
end;

procedure TCloudClient.SetEndPoint(const Host: string; Port: Word);
begin
  Self.Host:=Host;
  Self.Port:=Port;
end;

procedure TCloudClient.SetRecoveryInterval(Interval: Cardinal);
begin
  KeepAliveTimer.Interval:=Interval;
end;

procedure TCloudClient.SetDelegate(Delegate: TCloudDelegate);
begin
  Self.Delegate:=Delegate;
end;

function TCloudClient.GetConnected: Boolean;
begin
  Result:=Client.Connected;
end;

function TCloudClient.GetAuthorized: Boolean;
begin
  Result:=AccessToken<>'';
end;

function TCloudClient.GetReady: Boolean;
begin
  Result:=Connected and Authorized;
end;

function TCloudClient.GetAccessToken: string;
begin
  Result:=AccessToken;
  if Result.IsEmpty then Result:='*';
end;

procedure TCloudClient.Unauthorized;
begin
  AccessToken:='';
end;

procedure TCloudClient.Cancel;
begin
  Workload:=False;
end;

procedure TCloudClient.OnKeepAliveTimer(Sender: TObject);
begin
  KeepAliveTimer.Enabled:=False;
  Connect;
end;

procedure TCloudClient.DoRecoveryConnection;
begin
  KeepAliveTimer.Enabled:=True;
end;

procedure TCloudClient.OnClientAfterConnect(Sender: TObject);
begin
end;

procedure TCloudClient.OnClientClose(Sender: TObject);
begin

  Delegate.OnEvent(EVENT_DISCONNECTED,'connection closed');

  ConnectionID:='';

  if KeepAlive then DoRecoveryConnection;

end;

procedure TCloudClient.OnClientConnect(Sender: TObject);
begin
  Delegate.OnEvent(EVENT_CONNECTED,'client connected');
end;

procedure TCloudClient.OnClientException(Sender: TObject);
begin

  Delegate.OnEvent(EVENT_EXCEPT,Client.E.Message);

  if KeepAlive then
    DoRecoveryConnection
  else
    Workload:=False;

end;

procedure TCloudClient.OnClientRead(Sender: TObject);
var
  P: Integer;
  Command: string;
begin

  ReceiveString:=ReceiveString+Client.ReceiveString;

  P:=ReceiveString.IndexOfAny([#10,#13]);

  Workload:=not ReceiveString.EndsWith(#10);

  while P<>-1 do
  begin

    Command:=ReceiveString.Substring(0,P);
    ReceiveString:=ReceiveString.Substring(P+1);

    if not Command.Trim.IsEmpty then DoResponse(Command);

    P:=ReceiveString.IndexOfAny([#10,#13]);

  end;

end;

procedure TCloudClient.Connect;
begin

  if Client.Connected then Exit;

  ReceiveString:='';
  Workload:=True;

  Delegate.OnEvent(EVENT_CONNECTING,'connecting... to '+Host+':'+Port.ToString);

  Client.Connect(Host,Port);

end;

procedure TCloudClient.Disconnect;
begin

  ReceiveString:='';
  Workload:=False;

  ConnectionID:='';
  AccessToken:='';

  Client.Disconnect;

end;

procedure TCloudClient.DoResponse(const S: string);
var Response: TCloudResponse;
begin

  Delegate.OnEvent(EVENT_RESPONSE,S);

  Response:=S;

  if Response.Command='c2' then
  begin
    var Init:=TCloudResponseInit(Response);
    ConnectionID:=Init.ConnectionID;
    Delegate.OnInit(Init);
  end else

  if Response.Command='URKError' then
    Delegate.OnError(Response)
  else

  if Response.Command='_RegLight' then
    Delegate.OnRegistration(Response)
  else

  if Response.Command='_StartClient' then
  begin
    var StartClient:=TCloudResponseLogin(Response);
    AccessToken:=StartClient.AccessToken;
    Delegate.OnLogin(StartClient);
  end else

  if Response.Command='GetCloudAdreses' then
    Delegate.OnAddresses(Response)
  else

  if Response.Command='CreateNewAdres' then
    Delegate.OnCreateAddress(Response)
  else

  if Response.Command='listtransactions' then
    Delegate.OnTransactions(Response)
  else

  if Response.Command='_GetCurAddresses' then
    Delegate.OnAddress(Response)
  else

  if Response.Command='GetWaletFullInfo' then
    Delegate.OnInfo(Response)
  else

  if Response.Command='SendFrom' then
    Delegate.OnSendTo(Response)
  else

  if Response.Command='_GetCrRatio' then
    Delegate.OnRatio(Response)
  else

  if Response.Command='UForging2' then
    Delegate.OnRequestForging(Response)
  else

  if Response.Command='_UForging' then
    Delegate.OnForging(Response)
  else

  if Response.Command='GetAccountBalance' then
    Delegate.OnRequestAccountBalance(Response)
  else

  if Response.Command='_CreateOffer' then
    Delegate.OnCreateOffer(Response)
  else

  if Response.Command='_GetOffersD' then
    Delegate.OnOffers(Response)
  else

  if Response.Command='_GetOfferAccount' then
    Delegate.OnOfferAccount(Response)
  else

  if Response.Command='UTransfer' then
    Delegate.OnRequestTransfer(Response)
  else

  if Response.Command='_UTransfer' then
    // Delegate.
  else

  if Response.Command='_KillOffer' then
    Delegate.OnKillOffer(Response)
  else

  if Response.Command='_GetActiveOffers' then
    Delegate.OnActiveOffers(Response)
  else

  if Response.Command='_GetClosedOffers' then
    Delegate.OnClosedOffers(Response)
  else

  if Response.Command='_GetHistoryOffers' then
    Delegate.OnHistoryOffers(Response)
  else

  if Response.Command='_GetPairsSummary' then
    Delegate.OnPairsSummary(Response)
  else

    Delegate.OnError('* * 0');

end;

procedure TCloudClient.SendRequest(const Command,Args: string; const ShowArgs: string='');
var C,S: string;
begin
  C:=Command+' '+ConnectionID+' '+Args;
  if ShowArgs='' then S:=C else S:=Command+' '+ConnectionID+' '+ShowArgs;
  Delegate.OnEvent(EVENT_REQUEST,S);
  Workload:=True;
  Client.Send(C+#13);
end;

procedure TCloudClient.SendResponse(const Command,Args: string);
var C: string;
begin
  C:=Command+' '+ConnectionID+' '+Args;
  Delegate.OnEvent(EVENT_REQUEST,C);
  Workload:=False;
  Client.Send(C+#13);
end;

procedure TCloudClient.SendRequestRaw(const Command: string);
var Request: TCloudRequest;
begin
  Request:=Command;
  SendRequest(Request.Command,GetAccessToken+' '+Request.Args);
end;

procedure TCloudClient.SendRequestRegistration(const Email,Password: string; AccountID: Int64);
begin
  SendRequest('RegLight',Email+' '+Password+' '+AccountID.ToString+' '+Password,
    Email+' ****** '+AccountID.ToString+' ******');
end;

procedure TCloudClient.SendRequestLogin(const Email,Password: string);
begin
  SendRequest('CheckPW',Email+' '+Password+' ipa',Email+' ****** ipa');
end;

procedure TCloudClient.SendRequestAddresses(const Port: string);
begin
  SendRequest('GetCloudAdreses',GetAccessToken+' * '+Port);
end;

procedure TCloudClient.SendRequestTransactions(const Port: string);
begin
  SendRequest('listtransactions',GetAccessToken+' * '+Port);
end;

procedure TCloudClient.SendRequestCreateAddress(const Port: string);
begin
  SendRequest('CreateNewAdres',GetAccessToken+' * '+Port);
end;

procedure TCloudClient.SendRequestAddress();
begin
  SendRequest('GetCurAddresses',GetAccessToken);
end;

procedure TCloudClient.SendRequestInfo(const Port: string);
begin
  SendRequest('GetWaletFullInfo',GetAccessToken+' * '+Port);
end;

procedure TCloudClient.SendRequestSendTo(const Address: string; Amount: Extended;
  Confirm: Integer; const Port: string);
begin
  SendRequest('SendFromTo',GetAccessToken+' '+Address+' '+AmountToStrI(Amount)+' '+
    Confirm.ToString+' '+Port);
end;

procedure TCloudClient.SendRequestRatio();
begin
  SendRequest('GetCrRatio',GetAccessToken);
end;

procedure TCloudClient.SendRequestForging(Owner,SymbolID: Integer; const PayPort: string;
  BuyAmount,PayAmount,Ratio,Commission1,Commission2: Extended);
begin
  SendRequest('UForging',GetAccessToken+' '+Owner.ToString+' '+SymbolID.ToString+' '+PayPort+' '+
    AmountToStrI(BuyAmount)+' '+AmountToStrI(PayAmount)+' '+AmountToStrI(Ratio)+' '+
    AmountToStrI(Commission1)+' '+AmountToStrI(Commission2));
end;

procedure TCloudClient.SendResponseForging(const Request,Result: string);
begin
  SendResponse('_UForging2',GetAccessToken+' <'+Request+'> '+Result);
end;

procedure TCloudClient.SendResponseAccountBalance(AmountRLC,AmountGTN: Extended);
begin
  SendResponse('_GetAccountBalance',GetAccessToken+' '+AmountToStrI(AmountRLC)+' '+
    AmountToStrI(AmountGTN));
end;

procedure TCloudClient.SendRequestCreateOffer(Direction,Coin1,Coin2: Integer;
  Amount,Ratio: Extended; EndDate: TDateTime);
begin
  SendRequest('CreateOffer',GetAccessToken+' 1 '+Direction.ToString+' '+Coin1.ToString+' '+
    Coin2.ToString+' '+AmountToStrI(Amount)+' '+AmountToStrI(Ratio)+' '+DateTimeToUnix(EndDate,False).ToString);
end;                                                                    // False - local date to UTC

function DefValue(Value: Integer; Default: string='*'): string;
begin
  if Value=0 then Result:=Default else Result:=Value.ToString;
end;

procedure TCloudClient.SendRequestOffers(SymbolID1,SymbolID2: Integer);
begin
  SendRequest('GetOffersD',GetAccessToken+' '+DefValue(SymbolID1)+' '+DefValue(SymbolID2));
end;

procedure TCloudClient.SendRequestOfferAccount;
begin
  SendRequest('GetOfferAccount',GetAccessToken);
end;

procedure TCloudClient.SendResponseTransfer;
begin
  SendResponse('_UTransfer',GetAccessToken);
end;

function Join(Condition: Boolean; const S: string): string;
begin
  if Condition then Result:=S else Result:='';
end;

procedure TCloudClient.SendResponseError(Code: Integer; const Text: string);
begin
  SendResponse('URKError',GetAccessToken+' '+Code.ToString+Join(not Text.IsEmpty,' "'+Text+'"'));
end;

procedure TCloudClient.SendRequestKillOffer(OfferID: Int64);
begin
  SendRequest('KillOffer',GetAccessToken+' '+OfferID.ToString);
end;

procedure TCloudClient.SendRequestActiveOffers;
begin
  SendRequest('GetActiveOffers',GetAccessToken);
end;

procedure TCloudClient.SendRequestClosedOffers(BeginDate,EndDate: TDateTime);
begin
  SendRequest('GetClosedOffers',GetAccessToken+' '+DateTimeToUnix(BeginDate,False).ToString+' '+
    DateTimeToUnix(EndDate,False).ToString);
end;

procedure TCloudClient.SendRequestHistoryOffers(BeginDate,EndDate: TDateTime);
begin
  SendRequest('GetHistoryOffers',GetAccessToken+' '+DateTimeToUnix(BeginDate,False).ToString+' '+
    DateTimeToUnix(EndDate,False).ToString);
end;

procedure TCloudClient.SendRequestPairsSummary;
begin
  SendRequest('GetPairsSummary',GetAccessToken);
end;

end.
