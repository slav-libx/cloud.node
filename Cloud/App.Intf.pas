unit App.Intf;

interface

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
  end;

var
  UI: IUI;
  AppCore: IAppCore;

implementation

end.
