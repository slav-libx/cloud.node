unit Cloud.Core;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.DateUtils,
  Net.Socket,
  Cloud.Consts,
  Cloud.Types,
  Cloud.Client;

type
  TCloudCore = class(TCloudDelegate)
  private
    CloudClient: TCloudClient;
    Email: string;
    Password: string;
    Addresses: TCloudAddresses;
    Transactions: TCloudTransactions;
  public
    procedure OnEvent(Event: Integer; const Text: string); override;
    procedure OnInit(const Init: TCloudResponseInit); override;
    procedure OnError(const Error: TCloudResponseError); override;
    procedure OnRegistration(const Registration: TCloudResponseRegistration); override;
    procedure OnLogin(const Login: TCloudResponseLogin); override;
    procedure OnAddresses(const Addresses: TCloudResponseGetAddresses); override;
    procedure OnCreateAddress(const Address: TCloudResponseCreateAddress); override;
    procedure OnTransactions(const Transactions: TCloudResponseTransactions); override;
    constructor Create(CloudClient: TCloudClient);
    procedure SetAuth(const Email,Password: string);
  end;

implementation

constructor TCloudCore.Create(CloudClient: TCloudClient);
begin
  Self.CloudClient:=CloudClient;
  CloudClient.SetDelegate(Self);
end;

procedure TCloudCore.SetAuth(const Email,Password: string);
begin
  Self.Email:=Email;
  Self.Password:=Password;
end;

procedure TCloudCore.OnEvent(Event: Integer; const Text: string);
begin
 {$IFDEF CONSOLE}
  case Event of
  EVENT_REQUEST: Writeln('>'+Text);
  EVENT_RESPONSE: Writeln('<'+Text);
  else Writeln(Text);
  end;
 {$ENDIF}
end;

procedure TCloudCore.OnInit(const Init: TCloudResponseInit);
begin
  CloudClient.SendRequestLogin(Email,Password);
end;

procedure TCloudCore.OnError(const Error: TCloudResponseError);
begin
  if Error.Code='816' then
    CloudClient.SendRequestRegistration(Email,Password);
end;

procedure TCloudCore.OnRegistration(const Registration: TCloudResponseRegistration);
begin
  CloudClient.SendRequestLogin(Email,Password);
end;

procedure TCloudCore.OnLogin(const Login: TCloudResponseLogin);
begin
  CloudClient.SendRequestAddresses(PORT_BITCOIN);
end;

procedure TCloudCore.OnAddresses(const Addresses: TCloudResponseGetAddresses);
begin

  Self.Addresses:=Addresses.Addresses;

  if not Addresses.Error then

  if Addresses.Addresses.IsEmpty then
    CloudClient.SendRequestCreateAddress(PORT_BITCOIN)
  else
    CloudClient.SendRequestTransactions(PORT_BITCOIN)

end;

procedure TCloudCore.OnCreateAddress(const Address: TCloudResponseCreateAddress);
begin
end;

procedure TCloudCore.OnTransactions(const Transactions: TCloudResponseTransactions);
begin
  Self.Transactions:=Transactions.Transactions;
end;

end.
