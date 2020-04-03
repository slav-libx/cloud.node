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
  Cloud.Console in 'Cloud.Console.pas';

{ $DEFINE CLOUD}

var
  Client: TCloudClient;
  Command: string;

begin {main}

  Client:=TCloudClient.Create;

{$IFDEF CLOUD}

  var CloudCore:=TCloudCore.Create(Client);

  CloudCore.SetAuth('555b@1.com','555');

  Client.Connect;

  while True do CheckSynchronize(100);

{$ELSE}

  var CloudCore:=TCloudConsole.Create(Client);

  Client.Connect;

  repeat

    while Client.Workloaded do CheckSynchronize(100);

    if not Client.Connected then Break;

    Write('node>'); Readln(Command);

  until not CloudCore.DoConsoleCommand(Command);

{$ENDIF}

  Client.Free;
  CloudCore.Free;

end.


