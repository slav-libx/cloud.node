unit Cloud.Console;

interface

uses
  System.SysUtils,
  Cloud.Consts,
  Cloud.Types,
  Cloud.Utils,
  Cloud.Client;

type
  TCloudConsole = class(TCloudDelegate)
  private
    CloudClient: TCloudClient;
    procedure DoPrintHelp(const Title: string);
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
    constructor Create(CloudClient: TCloudClient);
    function DoConsoleCommand(const Command: string): Boolean;
  end;

implementation

constructor TCloudConsole.Create(CloudClient: TCloudClient);
begin
  Self.CloudClient:=CloudClient;
  CloudClient.SetDelegate(Self);
end;

procedure TCloudConsole.OnEvent(Event: TCloudEvent; const Text: string);
begin
  case Event of
  EVENT_REQUEST: Writeln('>'+Text);
  EVENT_RESPONSE: Writeln('<'+Text);
  else Writeln(Text);
  end;
end;

procedure TCloudConsole.OnInit(const Init: TCloudResponseInit);
begin
end;

procedure TCloudConsole.OnError(const Error: TCloudResponseError);
begin
  Writeln(string(Error));
end;

procedure TCloudConsole.OnRegistration(const Registration: TCloudResponseRegistration);
begin
  Writeln('registered');
end;

procedure TCloudConsole.OnLogin(const Login: TCloudResponseLogin);
begin
  Writeln('login successful');
end;

procedure TCloudConsole.OnAddresses(const Addresses: TCloudResponseGetAddresses);
begin
  if not Addresses.Error then
  begin
    Writeln('----Addresses----');
    for var S in Addresses.Addresses do Writeln(S);
  end else
    Writeln(Addresses.ErrorText);
end;

procedure TCloudConsole.OnCreateAddress(const Address: TCloudResponseCreateAddress);
begin
  if not Address.Error then
    Writeln('Address: '+Address.Address)
  else
    Writeln(Address.ErrorText);
end;

procedure TCloudConsole.OnTransactions(const Transactions: TCloudResponseTransactions);
begin
  Writeln('----Transactions----');
  for var Transaction in Transactions.Transactions do Writeln(string(Transaction));
end;

procedure TCloudConsole.OnAddress(const Address: TCloudResponseCurrentAddresses);
begin
  Writeln(string(Address));
end;

procedure TCloudConsole.OnInfo(const Info: TCloudResponseInfo);
begin
  Writeln(string(Info));
end;

procedure TCloudConsole.OnSendTo(const SendTo: TCloudResponseSendTo);
begin
  Writeln(string(SendTo));
end;

procedure TCloudConsole.OnRatio(const Ratio: TCloudResponseRatio);
begin
  Writeln(string(Ratio));
end;

procedure TCloudConsole.OnRequestForging(const Forging: TCloudRequestForging);
begin
  Writeln(string(Forging));
end;

procedure TCloudConsole.OnForging(const Forging: TCloudResponseForging);
begin
  Writeln('tx:'+Forging.Tx);
end;

procedure TCloudConsole.DoPrintHelp(const Title: string);
begin
  Writeln(Title);
  Writeln('reg <email> <password> <ref>'#9#9'- registration account');
  Writeln('login <email> <password> '#9#9'- login account');
  Writeln('add <btc|ltc|eth> '#9#9#9'- add new address');
  Writeln('list <btc|ltc|eth> '#9#9#9'- get addresses list');
  Writeln('tx <btc|ltc|eth> '#9#9#9'- get transactions list');
  Writeln('get'#9#9#9#9#9'- get current addresses list');
  Writeln('info <btc|ltc|eth> '#9#9#9'- get current wallet info');
  Writeln('send <btc|ltc|eth> <address> <amount> '#9'- send coins to address');
  Writeln('ratio'#9#9#9#9#9'- get USD ratio coins');
  Writeln('forg <rlc|gtn> <btc|ltc|eth>'#9#9'- forging');
  Writeln('exit'#9#9#9#9#9'- terminated');
end;

function GetPort(const Symbol: string): string;
begin
  Result:=SymbolToPort(Symbol,PORT_BITCOIN);
end;

function GetToken(const Symbol: string): Integer;
begin
  Result:=Map(Symbol,['rlc','gtn'],['1','2'],'1').ToInteger;
end;

function TCloudConsole.DoConsoleCommand(const Command: string): Boolean;
var Args: TArray<string>;
begin

  Result:=True;

  Args:=Command.Split([' '])+['','',''];

  if Args[0]='' then
  else

  if Command='exit' then
    Exit(False)
  else

  if Args[0]='reg' then
    CloudClient.SendRequestRegistration(Args[1],Args[2],StrToIntDef(Args[3],1))
  else

  if Args[0]='login' then
    CloudClient.SendRequestLogin(Args[1],Args[2])
  else

  if Args[0]='add' then
    CloudClient.SendRequestCreateAddress(GetPort(Args[1]))
  else

  if Args[0]='list' then
    CloudClient.SendRequestAddresses(GetPort(Args[1]))
  else

  if Args[0]='tx' then
    CloudClient.SendRequestTransactions(GetPort(Args[1]))
  else

  if Args[0]='get' then
    CloudClient.SendRequestAddress()
  else

  if Args[0]='info' then
    CloudClient.SendRequestInfo(GetPort(Args[1]))
  else

  if Args[0]='send' then
    CloudClient.SendRequestSendTo(Args[2],StrToAmount(Args[3]),6,GetPort(Args[1]))
  else

  if Args[0]='ratio' then
    CloudClient.SendRequestRatio()
  else

  if Args[0]='forg' then
    CloudClient.SendRequestForging(21,GetToken(Args[1]),GetPort(Args[2]),25,0.0045,6456.543,1.00000,1.00000)
  else

    DoPrintHelp('unknown command, use:');

end;

end.
