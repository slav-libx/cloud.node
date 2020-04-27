unit App.Intf;

interface

uses
  DEX.Types;

type
  IUI = interface
    procedure ShowMessage(const AMessage: string);
    procedure ShowException(const AMessage: string);
    procedure WaitLock;
    procedure WaitCancel;
    procedure WaitUnlock;
  end;

  IAppCore = interface
    procedure DoCloudRequestBalance(const Symbol: string);
    procedure DoCloudBalance(const Address: string; Amount: Extended; const Symbol: string);
    procedure DoCloudRequestTransfer(const Symbol,Address: string; Amount: Extended);
    procedure DoCloudRequestRatio;
    procedure DoCloudRatio(RatioBTC,RatioLTC,RatioETH: Extended);
    procedure DoForging(Owner,Buyer,Token: Int64; Amount,Commission1,Commission2: Extended);
    procedure DoCloudRequestForging(const TokenSymbol,CryptoSymbol: string;
      TokenAmount,CryptoAmount,CryptoRatio,Commission: Extended);
    procedure DoCloudForgingResult(const Tx: string);
    procedure DoCloudRequestCreateOffer(Direction: Integer; const Symbol1,Symbol2: string;
      Amount,Ratio: Extended; EndDate: TDateTime);
    procedure DoCloudCreateOffer(const OfferID: string);
    procedure DoCloudRequestOffers(const Symbol1,Symbol2: string);
    procedure DoCloudOffers(const Offers: TOffers);
    procedure DoOfferTransfer(Direction: Integer; const Symbol1,Symbol2: string;
      OfferAccount: Int64; Amount,Ratio: Extended);
    procedure DoTransferToken2(const TokenSymbol,ToAccount: string; Amount: Extended);
    function GetSymbolBalance(const Symbol: string): Extended;
    procedure DoCloudRequestKillOffer(OfferID: Int64);
    procedure DoCloudKillOffer(const OfferID: string);
    procedure DoCloudActiveOffers(const Offers: TOffers);
    procedure DoCloudClosedOffers(const Offers: TOffers);
    procedure DoCloudHistoryOffers(const Offers: TOffers);
    procedure DoCloudPairsSummary(const Pairs: TPairs);
  end;

var
  UI: IUI;
  AppCore: IAppCore;

implementation

end.
