program cloudnode;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.DateUtils,
  Net.Socket in '..\relictum.node\Library\Net.Socket.pas',
  Cloud.Core in 'Cloud.Core.pas',
  Cloud.Types in 'Cloud.Types.pas',
  Cloud.Consts in 'Cloud.Consts.pas',
  Cloud.Client in 'Cloud.Client.pas',
  Cloud.Console in 'Cloud.Console.pas',
  Cloud.Utils in 'Cloud.Utils.pas';

{ $DEFINE CLOUD}


{$IFDEF CLOUD}

var
  CloudCore: TCloudCore;

begin {main}

  CloudCore:=TCloudCore.Create;

  CloudCore.SetAuth('xxx@1.com','xxx');

  CloudCore.SendRequestBalance('BTC');

  while True do CheckSynchronize(100);

  CloudCore.Free;

end.

{$ELSE}

var
  Client: TCloudClient;
  Command: string;

begin {main}

  Client:=TCloudClient.Create;

  var CloudCore:=TCloudConsole.Create(Client);

  Client.Connect;

  repeat

    while Client.Workloaded do CheckSynchronize(100);

    while CheckSynchronize(100) do;

    if not Client.Connected then Break;

    Write('node>'); Readln(Command);

  until not CloudCore.DoConsoleCommand(Command);

  Client.Free;
  CloudCore.Free;

end.

{$ENDIF}



