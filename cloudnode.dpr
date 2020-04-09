program cloudnode;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.DateUtils,
  System.Console,
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
  Console: TConsole;
  Command: Word;

begin

  Console:=TConsole.Create;

  CloudCore:=TCloudCore.Create;

  CloudCore.SetAuth('xxx@1.com','xxx');

  Command:=49;

  while True do
  begin

    case Command of
    13:;
    49:
    begin
      Writeln;
      CloudCore.SendRequestBalance('BTC');
      CloudCore.Wait;
      Writeln;
    end;

    else Break;
    end;

    Write('Press command key... 1 - request balance, 2 - transfer');

    Command:=Console.ReadKey; Writeln;

  end;

  CloudCore.Free;
  Console.Free;

{$ELSE}

var
  Client: TCloudClient;
  Command: string;

begin

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

{$ENDIF}

end.




