program cloudserver;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  Cloud.Server in 'Cloud\Cloud.Server.pas',
  Net.Socket in '..\relictum.node\Library\Net.Socket.pas',
  Cloud.Types in 'Cloud\Cloud.Types.pas',
  Cloud.Utils in 'Cloud\Cloud.Utils.pas',
  Cloud.Consts in 'Cloud\Cloud.Consts.pas';

begin
  TCloudServer.Create(8765).Run;
end.


