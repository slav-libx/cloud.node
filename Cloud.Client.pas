unit Cloud.Client;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.DateUtils,
  Net.Socket,
  Cloud.Consts,
  Cloud.Types,
  Cloud.Utils;

type
  TCloudClient = class
  private
    Delegate: TCloudDelegate;
    Client: TTCPSocket;
    Workload: Boolean;
    Host: string;
    Port: Word;
    ConnectionID: string;
    ReceiveString: string;
    AccessToken: string;
    function GetConnected: Boolean;
    procedure DoResponse(const S: string);
    procedure SendRequest(const Command,Args: string);
  private
    procedure OnClientConnect(Sender: TObject);
    procedure OnClientAfterConnect(Sender: TObject);
    procedure OnClientRead(Sender: TObject);
    procedure OnClientClose(Sender: TObject);
    procedure OnClientException(Sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
    function SetEndPoint(const Host: string; Port: Word): TCloudClient;
    procedure SetDelegate(Delegate: TCloudDelegate);
    procedure Connect;
    procedure SendRequestRegistration(const Email,Password: string);
    procedure SendRequestLogin(const Email,Password: string);
    procedure SendRequestAddresses(const Port: string);
    procedure SendRequestTransactions(const Port: string);
    procedure SendRequestCreateAddress(const Port: string);
    procedure SendRequestAddress();
    procedure SendRequestInfo(const Port: string);
    procedure SendRequestSendTo(const Address: string; Amount: Extended;
      Confirm: Integer; const Port: string);
    property Workloaded: Boolean read Workload;
    property Connected: Boolean read GetConnected;
    property ConnectID: string read ConnectionID;
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

end;

destructor TCloudClient.Destroy;
begin
  Client.Free;
  inherited;
end;

function TCloudClient.SetEndPoint(const Host: string; Port: Word): TCloudClient;
begin
  Self.Host:=Host;
  Self.Port:=Port;
  Result:=Self;
end;

procedure TCloudClient.SetDelegate(Delegate: TCloudDelegate);
begin
  Self.Delegate:=Delegate;
end;

function TCloudClient.GetConnected: Boolean;
begin
  Result:=Client.Connected;
end;

procedure TCloudClient.OnClientAfterConnect(Sender: TObject);
begin
end;

procedure TCloudClient.OnClientClose(Sender: TObject);
begin
  Delegate.OnEvent(EVENT_DISCONNECTED,'connection closed');
  ConnectionID:='';
end;

procedure TCloudClient.OnClientConnect(Sender: TObject);
begin
  Delegate.OnEvent(EVENT_CONNECTED,'client connected');
end;

procedure TCloudClient.OnClientException(Sender: TObject);
begin
  Delegate.OnEvent(EVENT_ERROR,'error:'+Client.E.Message);
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

  ReceiveString:='';
  Workload:=True;

  Delegate.OnEvent(EVENT_CONNECTING,'connecting... to '+Host+':'+Port.ToString);

  Client.Connect(Host,Port);

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

end;

procedure TCloudClient.SendRequest(const Command,Args: string);
var C: string;
begin
  C:=Command+' '+ConnectionID+' '+Args;
  Delegate.OnEvent(EVENT_REQUEST,C);
  Client.Send(C+#13);
  Workload:=True;
end;

procedure TCloudClient.SendRequestRegistration(const Email,Password: string);
begin
  SendRequest('RegLight',Email+' '+Password+' 1 '+Password);
end;

procedure TCloudClient.SendRequestLogin(const Email,Password: string);
begin
  SendRequest('CheckPW',Email+' '+Password+' ipa');
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
  SendRequest('SendFromTo',AccessToken+' '+Address+' '+AmountToStr(Amount)+' '+
    Confirm.ToString+' '+Port);
end;

end.
