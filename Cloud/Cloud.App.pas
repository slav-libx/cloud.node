unit Cloud.App;

interface

uses
  System.Console,
  System.Classes,
  System.SysUtils,
  App.Intf,
  DEX.Types,
  Cloud.Consts,
  Cloud.Utils,
  Cloud.Core;

type
  TCloudApp = class(TInterfacedObject,IAppCore,IUI)
  private
    CloudCore: TCloudCore;
    Console: TConsole;
  public
    procedure ShowMessage(const AMessage: string);
    procedure ShowException(const AMessage: string);
    procedure ShowCommands(const Title: string);
    procedure WaitLock;
    procedure WaitCancel;
    procedure WaitUnlock;
    procedure DoCloudRequestBalance(const Symbol: string);
    procedure DoCloudBalance(const Address: string; Amount: Extended; const Symbol: string);
    procedure DoCloudRequestTransfer(const Symbol,Address: string; Amount: Extended);
    procedure DoCloudRequestRatio;
    procedure DoCloudRatio(RatioBTC,RatioLTC,RatioETH: Extended);
    procedure DoForging(Owner,Buyer,Token: Int64; Amount,Commission1,Commission2: Extended);
    procedure DoCloudRequestForging(const TokenSymbol,CryptoSymbol: string;
      TokenAmount,CryptoAmount,CryptoRatio,Commission: Extended);
    procedure DoCloudForgingResult(const Tx: string);
    procedure DoCloudResponseBalance;
    procedure DoCloudRequestCreateOffer(Direction: Integer; const Symbol1,Symbol2: string;
      Amount,Ratio: Extended; EndDate: TDateTime);
    procedure DoCloudRequestOffers(const Symbol1,Symbol2: string);
    procedure DoCloudCreateOffer(const OfferID: string);
    procedure DoCloudOffers(const Offers: TOffers);
    procedure DoOfferTransfer(Direction: Integer; const Symbol1,Symbol2: string;
      OfferAccount: Int64; Amount,Ratio: Extended);
    procedure DoTransferToken2(const TokenSymbol,ToAccount: string; Amount: Extended);
    procedure DoCloudRequestKillOffer(OfferID: Int64);
    procedure DoCloudKillOffer(const OfferID: string);
    procedure DoCloudRequestActiveOffers;
    procedure DoCloudActiveOffers(const Offers: TOffers);
    procedure DoCloudRequestClosedOffers(BeginDate,EndDate: TDateTime);
    procedure DoCloudClosedOffers(const Offers: TOffers);
    procedure DoCloudRequestHistoryOffers(BeginDate,EndDate: TDateTime);
    procedure DoCloudHistoryOffers(const Offers: TOffers);
    procedure DoCloudRequestPairsSummary;
    procedure DoCloudPairsSummary(const Pairs: TPairs);
    function GetSymbolBalance(const Symbol: string): Extended;
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

procedure TCloudApp.DoCloudRatio(RatioBTC,RatioLTC,RatioETH: Extended);
begin
  Writeln('Rate BTC='+AmountToStr(RatioBTC));
  Writeln('Rate LTC='+AmountToStr(RatioLTC));
  Writeln('Rate ETH='+AmountToStr(RatioETH));
end;

procedure TCloudApp.DoCloudResponseBalance;
begin
  CloudCore.SendResponseBalance(12,56);
end;

procedure TCloudApp.DoCloudRequestCreateOffer(Direction: Integer; const Symbol1,Symbol2: string;
  Amount,Ratio: Extended; EndDate: TDateTime);
begin
  CloudCore.SendRequestCreateOffer(Direction,Symbol1,Symbol2,Amount,Ratio,EndDate);
end;

procedure TCloudApp.DoCloudCreateOffer(const OfferID: string);
begin
  ShowMessage('Offer='+OfferID);
end;

procedure TCloudApp.DoCloudRequestOffers(const Symbol1,Symbol2: string);
begin
  CloudCore.SendRequestOffers(Symbol1,Symbol2);
end;

procedure TCloudApp.DoCloudOffers(const Offers: TOffers);
begin
  for var Offer in Offers.Sort do Writeln(string(Offer));
end;

function AnyOf(const S: string; const Values: array of string): Boolean;
begin
  Result:=False;
  for var V in Values do if SameText(S,V) then Exit(True);
end;

procedure Require(Condition: Boolean; const Text: string);
begin
  if not Condition then raise Exception.Create(Text);
end;

const
  ACCOUNT_INDEFINITE=0;

procedure TCloudApp.DoOfferTransfer(Direction: Integer; const Symbol1,Symbol2: string;
  OfferAccount: Int64; Amount,Ratio: Extended);
var PaySymbol: string;
begin

  Require(Ratio>0,'wrong ratio');
  Require(Amount>0,'wrong amount');
  Require(OfferAccount<>ACCOUNT_INDEFINITE,'indefinite offer account');

  if Direction=1 then PaySymbol:=Symbol1 else // buy
  if Direction=2 then PaySymbol:=Symbol2 else // sell
                      PaySymbol:='';

  if AnyOf(PaySymbol,['RLC','GTN']) then
  begin
    Require(Amount<=GetSymbolBalance(PaySymbol),'insufficient funds');
    DoTransferToken2(PaySymbol,OfferAccount.ToString,Amount);
  end;

end;

procedure TCloudApp.DoTransferToken2(const TokenSymbol,ToAccount: string; Amount: Extended);
begin

end;

procedure TCloudApp.DoCloudRequestKillOffer(OfferID: Int64);
begin
  CloudCore.SendRequestKillOffer(OfferID);
end;

procedure TCloudApp.DoCloudKillOffer(const OfferID: string);
begin
  ShowMessage('Killed offer='+OfferID);
end;

procedure TCloudApp.DoCloudRequestActiveOffers;
begin
  CloudCore.SendRequestActiveOffer;
end;

procedure TCloudApp.DoCloudActiveOffers(const Offers: TOffers);
begin
  for var Offer in Offers.SortByDate do Writeln(string(Offer));
end;

procedure TCloudApp.DoCloudRequestClosedOffers(BeginDate,EndDate: TDateTime);
begin
  CloudCore.SendRequestClosedOffer(BeginDate,EndDate);
end;

procedure TCloudApp.DoCloudClosedOffers(const Offers: TOffers);
begin
  for var Offer in Offers.SortByDate do Writeln(string(Offer));
end;

procedure TCloudApp.DoCloudRequestHistoryOffers(BeginDate,EndDate: TDateTime);
begin
  CloudCore.SendRequestHistoryOffer(BeginDate,EndDate);
end;

procedure TCloudApp.DoCloudHistoryOffers(const Offers: TOffers);
begin
  for var Offer in Offers.SortByDate do Writeln(string(Offer));
end;

procedure TCloudApp.DoCloudRequestPairsSummary;
begin
  CloudCore.SendRequestPairsSummary;
end;

procedure TCloudApp.DoCloudPairsSummary(const Pairs: TPairs);
begin
  for var Pair in Pairs do Writeln(string(Pair));
end;

function TCloudApp.GetSymbolBalance(const Symbol: string): Extended;
begin
  Result:=0;
  if Symbol='RLC' then Exit(100);
  if Symbol='GNT' then Exit(100);
end;

procedure TCloudApp.ShowException(const AMessage: string);
begin
  Writeln('except:'+AMessage);
end;

procedure TCloudApp.ShowMessage(const AMessage: string);
begin
  Writeln(AMessage);
end;

procedure TCloudApp.WaitCancel;
begin

end;

procedure TCloudApp.WaitLock;
begin

end;

procedure TCloudApp.WaitUnlock;
begin

end;

procedure TCloudApp.ShowCommands(const Title: string);
begin

  Writeln(Title+#10+
    '1 - login'#10+
    '2 - request balance'#10+
    '3 - transfer'#10+
    '4 - ratio'#10+
    '5 - forging'#10+
    '6 - create offer'#10+
    '7 - get offers'#10+
    '8 - kill offer'#10+
    '9 - active offers'#10+
    '0 - closed offers'#10+
    'q - offers history'#10+
    'w - pairs summary'#10+
    'c - connect'#10+
    'd - disconnect'#10+
    'u - unauthorized'#10+
    'h - commands');

end;

procedure TCloudApp.Run;
var Command: Word;
begin

  ShowCommands('Press command key...');

  Writeln;

  CloudCore.SetAuth('hoome@users.dev','0',4);
  CloudCore.SetKeepAlive(True,4000);

  //CloudCore.SetAuth('genesis48@users.dev','0',1);
  //CloudCore.SetAuth('','',1);

  TThread.CreateAnonymousThread(
  procedure
  begin

    while Command<>13 do
    begin

      Command:=Console.ReadKey;

      if Command<>13 then

      TThread.Synchronize(nil,
      procedure
      begin

        case Command of

        67: CloudCore.Connect;

        68: CloudCore.Disconnect;

        85: CloudCore.Unauthorized;

        49: CloudCore.SendRequestLogin;

        50: DoCloudRequestBalance('BTC');

        51: DoCloudRequestTransfer('BTC','2MzReLLxWt5a3Zsgq6hrvXTCg3xDXdHpqfe',0.00001);

        52: DoCloudRequestRatio;

        53: DoCloudRequestForging('RLC','BTC',25,0.00001,6456.543,0);

        //54: DoCloudRequestCreateOffer(DIRECTION_BUY,'RLC','BTC',22,0.00582,Now+20);
        54: DoCloudRequestCreateOffer(DIRECTION_SELL,'RLC','BTC',13,0.00681,Now+20);

        55: DoCloudRequestOffers('RLC','');//'BTC');

        56: DoCloudRequestKillOffer(0);

        57: DoCloudRequestActiveOffers;

        48: DoCloudRequestClosedOffers(Date-10,Date+1);

        81: DoCloudRequestHistoryOffers(Date-10,Date+1);

        87: DoCloudRequestPairsSummary;

        72: ShowCommands('Commands list:');


        79: begin
            DoCloudRequestActiveOffers;
            DoCloudRequestPairsSummary;
            DoCloudRequestActiveOffers;
            end;

        end;

      end);

    end;

  end).Start;

  while Command<>13 do CheckSynchronize(100);

end;

end.
