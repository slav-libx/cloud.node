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
    procedure OnRequestAccountBalance(const AccountBalance: TCloudRequestAccountBalance); override;
    procedure OnCreateOffer(const Offer: TCloudResponseCreateOffer); override;
    procedure OnOffers(const Offers: TCloudResponseOffers); override;
    procedure OnOfferAccount(const Account: TCloudResponseOfferAccount); override;
    procedure OnKillOffers(const Offers: TCloudResponseKillOffers); override;
    procedure OnActiveOffers(const Offers: TCloudResponseOffers); override;
    procedure OnClosedOffers(const Offers: TCloudResponseOffers); override;
    procedure OnHistoryOffers(const Offers: TCloudResponseOffers); override;
    procedure OnPairsSummary(const Pairs: TCloudResponsePairs); override;
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

procedure TCloudConsole.OnRequestAccountBalance(const AccountBalance: TCloudRequestAccountBalance);
begin
  Writeln('request account balance: args='+AccountBalance.Args);
  CloudClient.SendResponseAccountBalance(340.2,10.705);
end;


procedure TCloudConsole.OnCreateOffer(const Offer: TCloudResponseCreateOffer);
begin
  Writeln(string(Offer));
end;

procedure TCloudConsole.OnOffers(const Offers: TCloudResponseOffers);
begin
  for var O in Offers.Offers do Writeln(string(O));
end;

procedure TCloudConsole.OnOfferAccount(const Account: TCloudResponseOfferAccount);
begin
  Writeln('offer account='+Account.AccountID.ToString);
end;

procedure TCloudConsole.OnKillOffers(const Offers: TCloudResponseKillOffers);
begin
  Writeln(string(Offers));
end;

procedure TCloudConsole.OnActiveOffers(const Offers: TCloudResponseOffers);
begin
  for var O in Offers.Offers do Writeln(string(O));
end;

procedure TCloudConsole.OnClosedOffers(const Offers: TCloudResponseOffers);
begin
  for var O in Offers.Offers do Writeln(string(O));
end;

procedure TCloudConsole.OnHistoryOffers(const Offers: TCloudResponseOffers);
begin
  for var O in Offers.Offers do Writeln(string(O));
end;

procedure TCloudConsole.OnPairsSummary(const Pairs: TCloudResponsePairs);
begin
  for var P in Pairs.Pairs do Writeln(string(P));
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
  Writeln('cof <b|s> <btc|ltc|eth|rlc|gtn> <btc|ltc|eth|rlc|gtn> <amount> <ratio>'#9#9'- create offer');
  Writeln('of <btc|ltc|eth|rlc|gtn> <btc|ltc|eth|rlc|gtn>'#9#9#9#9#9'- list offers');
  Writeln('ca'#9#9#9#9#9'- get offer account');
  Writeln('aaof'#9#9#9#9#9'- get active account offers');
  Writeln('acof <begin date> <end date>'#9#9'- get closed account offers');
  Writeln('ahof <begin date> <end date>'#9#9'- get history account offers');
  Writeln('cp'#9#9#9#9#9'- show pairs summary');
  Writeln('raw <Command>'#9#9#9#9'- execute any command');
  Writeln('exit'#9#9#9#9#9'- terminated');
end;

function GetPort(const Symbol: string): string;
begin
  Result:=SymbolToPort(Symbol,PORT_BITCOIN);
end;

function GetDate(const S: string; Default: TDateTime): TDateTime;
begin
  Result:=StrToDateTimeDef(S,Default);
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

  if Args[0]='raw' then
    CloudClient.SendRequestRaw(Skip(Command,[' '],1))
  else

  if Args[0]='reg' then
    CloudClient.SendRequestRegistration(Args[1],Args[2],StrToIntDef(Args[3],0))
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
    CloudClient.SendRequestForging(1,SymbolID(Args[1],1),GetPort(Args[2]),25,0.0001,6456.543,1.00000,1.00000)
  else

  if Args[0]='cof' then
    CloudClient.SendRequestCreateOffer(Map(Args[1],['b','s'],['1','2'],'1').ToInteger,SymbolID(Args[2]),SymbolID(Args[3]),StrToAmount(Args[4]),StrToAmount(Args[5]),Now+20)
  else

  if Args[0]='ca' then
    CloudClient.SendRequestOfferAccount
  else

  if Args[0]='of' then
    CloudClient.SendRequestOffers(SymbolID(Args[1]),SymbolID(Args[2]))
  else

  if Args[0]='aaof' then
    CloudClient.SendRequestActiveOffers
  else

  if Args[0]='acof' then
    CloudClient.SendRequestClosedOffers(GetDate(Args[1],Date-10),GetDate(Args[2],Date))
  else

  if Args[0]='ahof' then
    CloudClient.SendRequestHistoryOffers(GetDate(Args[1],Date-10),GetDate(Args[2],Date))
  else

  if Args[0]='cp' then
    CloudClient.SendRequestPairsSummary
  else

    DoPrintHelp('unknown command, use:');

end;

end.
