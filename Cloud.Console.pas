unit Cloud.Console;

interface

uses
  System.SysUtils,
  Cloud.Consts,
  Cloud.Types,
  Cloud.Client;

type
  TCloudConsole = class(TCloudDelegate)
  private
    CloudClient: TCloudClient;
    procedure DoPrintHelp(const Title: string);
    procedure OnEvent(Event: Integer; const Text: string); override;
    procedure OnInit(const Init: TCloudResponseInit); override;
    procedure OnError(const Error: TCloudResponseError); override;
    procedure OnRegistration(const Registration: TCloudResponseRegistration); override;
    procedure OnLogin(const Login: TCloudResponseLogin); override;
    procedure OnAddresses(const Addresses: TCloudResponseGetAddresses); override;
    procedure OnCreateAddress(const Address: TCloudResponseCreateAddress); override;
    procedure OnTransactions(const Transactions: TCloudResponseTransactions); override;
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

procedure TCloudConsole.OnEvent(Event: Integer; const Text: string);
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

procedure TCloudConsole.DoPrintHelp(const Title: string);
begin
  Writeln(Title);
  Writeln('reg <email> <password>');
  Writeln('login <email> <password>');
  Writeln('add <port>');
  Writeln('list <port>');
  Writeln('tx <port>');
  Writeln('exit');
end;

function TCloudConsole.DoConsoleCommand(const Command: string): Boolean;
var Args: TArray<string>;
begin

  if Command='exit' then Exit(False);

  Result:=True;

  Args:=Command.Split([' '])+['','',''];

  if Args[0]='reg' then
    CloudClient.SendRequestRegistration(Args[1],Args[2])
  else

  if Args[0]='login' then
    CloudClient.SendRequestLogin(Args[1],Args[2])
  else

  if Args[0]='add' then
    CloudClient.SendRequestCreateAddress(Args[1])
  else

  if Args[0]='list' then
    CloudClient.SendRequestAddresses(Args[1])
  else

  if Args[0]='tx' then
    CloudClient.SendRequestTransactions(Args[1])
  else

    DoPrintHelp('unknown command, use:');

end;

end.
