unit Cloud.Script.Balance;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.DateUtils,
  Net.Socket,
  Cloud.Consts,
  Cloud.Types,
  Cloud.Client,
  Cloud.Utils;

type
  TBalanceScript = class(TCloudDelegate)
  private
    CloudClient: TCloudClient;
    Email: string;
    Password: string;
    Port: string;
    procedure DoError(const Text: string);
  public
    procedure OnEvent(Event: Integer; const Text: string); override;
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
    constructor Create(CloudClient: TCloudClient);
    procedure Execute(const Email,Password,Port: string);
  end;

implementation

constructor TBalanceScript.Create(CloudClient: TCloudClient);
begin
  Self.CloudClient:=CloudClient;
end;

procedure TBalanceScript.DoError(const Text: string);
begin
  Writeln('Impossible: '+Text);
end;

procedure TBalanceScript.Execute(const Email,Password,Port: string);
begin

  Writeln('Execute request balance '+Email+' '+Port);

  //Self.Port:=Map(Port,['BTC','LTC','ETH'],[PORT_BITCOIN,PORT_LIGHTCOIN,PORT_ETHEREUM]);

  Self.Port:=Map(Port,['BTC','LTC'],[PORT_BITCOIN,PORT_LIGHTCOIN]); // so far only bitcoin
                                                                    // the code above is for everyone
  if Self.Port='' then

    DoError('forbidden coin')

  else begin

    Self.Email:=Email;
    Self.Password:=Password;

    if CloudClient.ConnectID='' then
      CloudClient.Connect
    else
      CloudClient.SendRequestLogin(Email,Password);

  end;

end;

procedure TBalanceScript.OnEvent(Event: Integer; const Text: string);
begin

  case Event of
  EVENT_REQUEST: Writeln('>'+Text);
  EVENT_RESPONSE: Writeln('<'+Text);
  EVENT_ERROR: DoError(Text);
  else Writeln(Text);
  end;

end;

procedure TBalanceScript.OnInit(const Init: TCloudResponseInit);
begin
  CloudClient.SendRequestLogin(Email,Password);
end;

procedure TBalanceScript.OnError(const Error: TCloudResponseError);
begin

  if Error.Code='816' then
    CloudClient.SendRequestRegistration(Email,Password)
  else

  if Error.Code='780' then
    CloudClient.SendRequestCreateAddress(Port)
  else

    DoError(Error.ErrorString);

end;

procedure TBalanceScript.OnRegistration(const Registration: TCloudResponseRegistration);
begin
  CloudClient.SendRequestLogin(Email,Password);
end;

procedure TBalanceScript.OnLogin(const Login: TCloudResponseLogin);
begin
  CloudClient.SendRequestInfo(Port);
end;

procedure TBalanceScript.OnAddresses(const Addresses: TCloudResponseGetAddresses);
begin
end;

procedure TBalanceScript.OnCreateAddress(const Address: TCloudResponseCreateAddress);
begin
  CloudClient.SendRequestInfo(Port);
end;

procedure TBalanceScript.OnTransactions(const Transactions: TCloudResponseTransactions);
begin
end;

procedure TBalanceScript.OnAddress(const Address: TCloudResponseCurrentAddresses);
begin
end;

procedure TBalanceScript.OnInfo(const Info: TCloudResponseInfo);
begin
  Writeln('Result: '+Info.Address+'='+AmountToStr(Info.Amount));
end;

procedure TBalanceScript.OnSendTo(const SendTo: TCloudResponseSendTo);
begin
end;

end.

