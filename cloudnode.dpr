program cloudnode;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.DateUtils,
  System.Console in 'Cloud\System.Console.pas',
  Net.Socket in '..\relictum.node\Library\Net.Socket.pas',
  Lib.Timer in '..\relictum.node\Library\Lib.Timer.pas',
  Cloud.Core in 'Cloud\Cloud.Core.pas',
  Cloud.Types in 'Cloud\Cloud.Types.pas',
  Cloud.Consts in 'Cloud\Cloud.Consts.pas',
  Cloud.Client in 'Cloud\Cloud.Client.pas',
  Cloud.Console in 'Cloud\Cloud.Console.pas',
  Cloud.Utils in 'Cloud\Cloud.Utils.pas',
  App.Intf in 'Cloud\App.Intf.pas',
  Cloud.Log in 'Cloud\Cloud.Log.pas',
  Cloud.App in 'Cloud\Cloud.App.pas',
  DEX.Types in 'Cloud\DEX.Types.pas';

{$DEFINE CLOUD}

{$IFDEF CLOUD}

var
  CloudApp: TCloudApp;

begin

  CloudApp:=TCloudApp.Create;

  AppCore:=CloudApp;
  UI:=CloudApp;

  CloudApp.Run;

{$ELSE}

var
  Console: TConsole;
  Client: TCloudClient;
  CloudCore: TCloudConsole;
  Command: string;
  C: Integer;

begin

  Console:=TConsole.Create;

  Client:=TCloudClient.Create;

  CloudCore:=TCloudConsole.Create(Client);

//  Client.SetEndPoint('localhost',8765);

  Client.Connect;

  repeat

    C:=60;

    CheckSynchronize(100);

    while Client.Workloaded and (C>0) do
    begin
      CheckSynchronize(100);
      Dec(C);
    end;

    if C=0 then
    begin
      Writeln('no response');
      Client.Cancel;
    end;

    if not Client.Connected then
    begin
      Write('Press any key...');
      Console.ReadKey; Break;
    end;

    Write('node>'); Readln(Command);

  until not CloudCore.DoConsoleCommand(Command);

  Client.Free;
  CloudCore.Free;
  Console.Free;

{$ENDIF}

end.




