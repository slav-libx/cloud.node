unit Cloud.Core;

interface

uses
  System.Classes,
  Cloud.Types,
  Cloud.Consts,
  Cloud.Client,
  Cloud.Utils,
  Cloud.Script.Balance;

type
  TCloudCore = class
  private
    Client: TCloudClient;
    Email: string;
    Password: string;
    BalanceScript: TBalanceScript;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Wait;
    procedure SendRequestBalance(const Port: string);
    procedure SetAuth(const Email,Password: string);
  end;

implementation

constructor TCloudCore.Create;
begin
  Client:=TCloudClient.Create;
  BalanceScript:=TBalanceScript.Create(Client);
end;

destructor TCloudCore.Destroy;
begin
  Client.Free;
  BalanceScript.Free;
  inherited;
end;

procedure TCloudCore.Wait;
begin
  while Client.Workloaded do CheckSynchronize(100);
  while CheckSynchronize(100) do;
end;

procedure TCloudCore.SetAuth(const Email,Password: string);
begin
  Self.Email:=Email;
  Self.Password:=Password;
end;

procedure TCloudCore.SendRequestBalance(const Port: string);
begin

  Client.SetDelegate(BalanceScript);

  BalanceScript.Execute(Email,Password,Port);

end;

end.
