unit Cloud.App;

interface

uses
  System.Console,
  System.Classes,
  App.Intf,
  Cloud.Utils,
  Cloud.Core;

type
  TCloudApp = class(TInterfacedObject,IAppCore,IUI)
  private
    CloudCore: TCloudCore;
    Console: TConsole;
    Workload: Boolean;
    procedure Wait;
  public
    procedure ShowMessage(const AMessage: string);
    procedure ShowException(const AMessage: string);
    procedure WaitLock;
    procedure WaitCancel;
    procedure WaitUnlock;
    procedure DoCloudRequestBalance(const Symbol: string);
    procedure DoCloudBalance(const Address: string; Amount: Extended; const Symbol: string);
    procedure DoCloudRequestTransfer(const Symbol,Address: string; Amount: Extended);
    procedure DoCloudRequestRatio;
    procedure DoCloudRatio(const Symbol: string; Ratio: Extended);
    procedure DoForging(Owner,Buyer,Token: Int64; Amount,Commission1,Commission2: Extended);
    procedure DoCloudRequestForging(const TokenSymbol,CryptoSymbol: string;
      TokenAmount,CryptoAmount,CryptoRatio,Commission: Extended);
    procedure DoCloudForgingResult(const Tx: string);
    constructor Create;
    destructor Destroy; override;
    procedure Run;
  end;

implementation

constructor TCloudApp.Create;
begin

  Console:=TConsole.Create;
  CloudCore:=TCloudCore.Create;

  CloudCore.ShowEventMessages:=True;

  //CloudCore.SetAuth('xxx@1.com','xxx');
  CloudCore.SetAuth('genesis4@users.dev','0',1);

end;

destructor TCloudApp.Destroy;
begin
  CloudCore.Free;
  Console.Free;
  inherited;
end;

procedure TCloudApp.DoCloudBalance(const Address: string; Amount: Extended; const Symbol: string);
begin
  Writeln('Result: '+Address+' '+AmountToStr(Amount)+' '+Symbol);
end;

procedure TCloudApp.DoCloudRequestBalance(const Symbol: string);
begin
  CloudCore.SendRequestBalance(Symbol);
end;

procedure TCloudApp.DoCloudRequestTransfer(const Symbol,Address: string;
  Amount: Extended);
begin
  CloudCore.SendRequestTransfer(Symbol,Address,Amount);
end;

procedure TCloudApp.DoCloudRequestRatio;
begin
  CloudCore.SendRequestRatio;
end;

procedure TCloudApp.DoForging(Owner,Buyer,Token: Int64; Amount,Commission1,Commission2: Extended);
begin
  //
end;

procedure TCloudApp.DoCloudRequestForging(const TokenSymbol,CryptoSymbol: string;
  TokenAmount,CryptoAmount,CryptoRatio,Commission: Extended);
begin
  CloudCore.SendRequestForging(21,1,CryptoSymbol,TokenAmount,CryptoAmount,CryptoRatio,Commission,0);
end;

procedure TCloudApp.DoCloudForgingResult(const Tx: string);
begin
  Writeln('tx='+Tx);
end;

procedure TCloudApp.DoCloudRatio(const Symbol: string; Ratio: Extended);
begin
  Writeln('Rate '+Symbol+'='+AmountToStr(Ratio));
end;

procedure TCloudApp.ShowException(const AMessage: string);
begin
  Writeln('except:'+AMessage);
end;

procedure TCloudApp.ShowMessage(const AMessage: string);
begin
  Writeln(AMessage);
end;

procedure TCloudApp.Wait;
var C: Integer;
begin

  C:=60;

  while (Workload or CloudCore.Workloaded) and (C>0) do
  begin
    CheckSynchronize(100);
    Dec(C);
  end;

  if C=0 then
  begin
    Workload:=False;
    CloudCore.Cancel;
    Writeln('no response');
  end;

end;

procedure TCloudApp.WaitCancel;
begin

end;

procedure TCloudApp.WaitLock;
begin
  Workload:=True;
end;

procedure TCloudApp.WaitUnlock;
begin
  Workload:=False;
end;

procedure TCloudApp.Run;
var Command: Word;
begin

  Command:=55;

  while True do
  begin

    case Command of

    13:;

    55: begin
        CloudCore.Cancel;
        CloudCore.Connect;
        end;

    56: CloudCore.Disconnect;

    57: CloudCore.Unauthorized;

    49: CloudCore.SendRequestLogin;

    50: DoCloudRequestBalance('BTC');

    51: DoCloudRequestTransfer('BTC','2MyFRtCHMTzy5vALF1EKzDe5r5EdytcFkAz',0.00001);

    52: DoCloudRequestRatio;

    53: DoCloudRequestForging('RLC','BTC',25,0.0045,6456.543,0);

    else Break;
    end;

    Wait;

    Writeln;
    Write('Press command key... 1 - login, 2 - request balance, 3 - transfer, 4 - ratio, 5 - forging, 7 - connect, 8 - disconnect, 9 - unauthorized');

    Command:=Console.ReadKey; Writeln; Writeln;

  end;

end;

end.
