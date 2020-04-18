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
    procedure SendRequestForging(Owner,BuyToken: Int64; const PayPort: string;
      BuyAmount,PayAmount,Ratio,Commission1,Commission2: Extended);
    procedure SendResponseForging(const Request,Result: string);
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
  SendRequest('GetCloudAdreses',AccessToken+' * '+Port);
end;

procedure TCloudClient.SendRequestTransactions(const Port: string);
begin
  SendRequest('listtransactions',AccessToken+' * '+Port);
end;

procedure TCloudClient.SendRequestCreateAddress(const Port: string);
begin
  SendRequest('CreateNewAdres',AccessToken+' * '+Port);
end;

procedure TCloudClient.SendRequestAddress();
begin
  SendRequest('GetCurAddresses',AccessToken);
end;

procedure TCloudClient.SendRequestInfo(const Port: string);
begin
  SendRequest('GetWaletFullInfo',AccessToken+' * '+Port);
end;

procedure TCloudClient.SendRequestSendTo(const Address: string; Amount: Extended;
  Confirm: Integer; const Port: string);
begin
  SendRequest('SendFromTo',AccessToken+' '+Address+' '+AmountToStrI(Amount)+' '+
    Confirm.ToString+' '+Port);
end;

procedure TCloudClient.SendRequestRatio();
begin
  SendRequest('GetCrRatio',AccessToken);
end;

procedure TCloudClient.SendRequestForging(Owner,BuyToken: Int64; const PayPort: string;
  BuyAmount,PayAmount,Ratio,Commission1,Commission2: Extended);
begin
  SendRequest('UForging',AccessToken+' '+Owner.ToString+' '+BuyToken.ToString+' '+PayPort+' '+
    AmountToStrI(BuyAmount)+' '+AmountToStrI(PayAmount)+' '+AmountToStrI(Ratio)+' '+
    AmountToStrI(Commission1)+' '+AmountToStrI(Commission2));
end;

procedure TCloudClient.SendResponseForging(const Request,Result: string);
begin
  SendResponse('_UForging2',AccessToken+' <'+Request+'> '+Result);
end;

end.
