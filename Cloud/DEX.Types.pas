unit DEX.Types;

interface

uses
  System.SysUtils,
  System.DateUtils,
  System.Math,
  System.Generics.Collections,
  System.Generics.Defaults;

type

  TOfferDirection = (Buy=1,Sell=2);

  TOffer = record
  public
    Status: Integer;
    ID: Integer;
    AccountID: Int64;
    Direction: Integer;
    Symbol1: string;
    Symbol2: string;
    Ratio: Extended;
    StrtAmount: Extended;
    CrrntAmount: Extended;
    StartDate: TDateTime;
    LastDate: TDateTime;
    EndDate: TDateTime;
    class operator Implicit(const Offer: TOffer): string;
  end;

  TOffers = array of TOffer;

  TOffersHelper = record helper for TOffers
    function Copy: TOffers;
    function Sort: TOffers;
    function SortByStartDate(Asc: Boolean=True): TOffers;
    function SortByLastDate(Asc: Boolean=True): TOffers;
    function SortByRatio(Asc: Boolean=True): TOffers;
    function GroupByRatio: TOffers;
  end;

  TPair = record
    Symbol1: string;
    Symbol2: string;
    Ratio: Extended;
    Volume: Extended;
    LastDate: TDateTime;
    Ratio24hAgo: Extended;
    Percent: Extended;
    Low: Extended;
    High: Extended;
    class operator Implicit(const Pair: TPair): string;
  end;

  TPairs = array of TPair;

  TDataCandle = record
    DateTime: TDateTime;
    Min: Extended;
    Max: Extended;
    Open: Extended;
    Close: Extended;
    Volume: Extended;
    Time: Int64;
    class operator Implicit(const Candle: TDataCandle): string;
  end;

  TDataCandles = array of TDataCandle;

  TDataTrade = record
    Ratio: Extended;
    Volume: Extended;
    Date: TDateTime;
    Direction: Integer;
    class operator Implicit(const Trade: TDataTrade): string;
  end;

  TDataTrades = array of TDataTrade;

  TDataTradesHelper = record helper for TDataTrades
    function Copy: TDataTrades;
    function SortByDate(Asc: Boolean=True): TDataTrades;
  end;

implementation

function AmountToStr(Amount: Extended): string;
begin
  Result:=FormatFloat('0.00######',Amount);
end;

class operator TOffer.Implicit(const Offer: TOffer): string;
begin

  case Offer.Direction of
  1: Result:='buy';
  2: Result:='sell';
  else Result:=Offer.Direction.ToString;
  end;

  Result:=
    Offer.ID.ToString.PadRight(6)+
    Offer.Status.ToString.PadRight(4)+
    Offer.AccountID.ToString.PadRight(6)+
    Result.PadRight(6)+
    (Offer.Symbol1+'/'+Offer.Symbol2).PadRight(10)+
    AmountToStr(Offer.CrrntAmount).PadRight(10)+
    AmountToStr(Offer.Ratio).PadRight(10)+
    DateTimeToStr(Offer.StartDate);

end;

function TOffersHelper.Copy: TOffers;
begin
  SetLength(Result,Length(Self));
  if Length(Self)>0 then TArray.Copy<TOffer>(Self,Result,Length(Self));
end;

function TOffersHelper.Sort: TOffers;
begin

  Result:=Copy;

  TArray.Sort<TOffer>(Result,TComparer<TOffer>.Construct(
  function(const Left,Right: TOffer): Integer
  begin

    Result:=CompareStr(Left.Symbol1,Right.Symbol1);
    if Result=0 then
    Result:=CompareText(Left.Symbol2,Right.Symbol2);
    if Result=0 then
    Result:=Right.Direction-Left.Direction;
    if Result=0 then
    Result:=-CompareValue(Left.Ratio,Right.Ratio);
    if Result=0 then
    begin
      Result:=CompareDateTime(Left.StartDate,Right.StartDate);
      if Left.Direction=2 then Result:=-Result;
    end;

  end));

end;

function TOffersHelper.SortByStartDate(Asc: Boolean=True): TOffers;
var A: Integer;
begin

  Result:=Copy;

  if Asc then A:=+1 else A:=-1;

  TArray.Sort<TOffer>(Result,TComparer<TOffer>.Construct(
  function(const Left,Right: TOffer): Integer
  begin
    Result:=A*CompareDateTime(Left.StartDate,Right.StartDate);
  end));

end;

function TOffersHelper.SortByLastDate(Asc: Boolean=True): TOffers;
var A: Integer;
begin

  Result:=Copy;

  if Asc then A:=+1 else A:=-1;

  TArray.Sort<TOffer>(Result,TComparer<TOffer>.Construct(
  function(const Left,Right: TOffer): Integer
  begin
    Result:=A*CompareDateTime(Left.LastDate,Right.LastDate);
  end));

end;

function TOffersHelper.SortByRatio(Asc: Boolean=True): TOffers;
var A: Integer;
begin

  Result:=Copy;

  if Asc then A:=+1 else A:=-1;

  TArray.Sort<TOffer>(Result,TComparer<TOffer>.Construct(
  function(const Left,Right: TOffer): Integer
  begin

    if Left.Ratio*Right.Ratio=0 then
    Result:=CompareValue(Left.Ratio,Right.Ratio) else
    Result:=A*CompareValue(Left.Ratio,Right.Ratio);

    if Result=0 then
    Result:=CompareDateTime(Left.StartDate,Right.StartDate);

  end));

end;

function TOffersHelper.GroupByRatio: TOffers;
begin
  Result:=nil;
  for var Offer in Self do
  if (Length(Result)>0) and (Offer.Ratio=Result[High(Result)].Ratio) then
  begin
    Result[High(Result)].StrtAmount:=Result[High(Result)].StrtAmount+Offer.StrtAmount;
    Result[High(Result)].CrrntAmount:=Result[High(Result)].CrrntAmount+Offer.CrrntAmount;
  end else
    Result:=Result+[Offer];
end;

class operator TPair.Implicit(const Pair: TPair): string;
begin

  Result:=
    (Pair.Symbol1+'/'+Pair.Symbol2).PadRight(10)+
    AmountToStr(Pair.Volume).PadRight(10)+
    AmountToStr(Pair.Ratio).PadRight(10)+
    FormatFloat('+0.0#%;-0.0#%',Pair.Percent).PadRight(9)+
    DateTimeToStr(Pair.LastDate);

end;

class operator TDataCandle.Implicit(const Candle: TDataCandle): string;
begin

  Result:=
    DateTimeToStr(Candle.DateTime).PadRight(22)+
    AmountToStr(Candle.Open).PadRight(12)+
    AmountToStr(Candle.Close).PadRight(12)+
    AmountToStr(Candle.Min).PadRight(12)+
    AmountToStr(Candle.Max).PadRight(12)+
    AmountToStr(Candle.Volume).PadRight(12);

end;

class operator TDataTrade.Implicit(const Trade: TDataTrade): string;
begin

  Result:=
    Trade.Direction.ToString.PadRight(5)+
    AmountToStr(Trade.Volume).PadRight(10)+
    AmountToStr(Trade.Ratio).PadRight(14)+
    DateTimeToStr(Trade.Date);

end;

function TDataTradesHelper.Copy: TDataTrades;
begin
  SetLength(Result,Length(Self));
  if Length(Self)>0 then TArray.Copy<TDataTrade>(Self,Result,Length(Self));
end;

function TDataTradesHelper.SortByDate(Asc: Boolean=True): TDataTrades;
var A: Integer;
begin

  Result:=Copy;

  if Asc then A:=+1 else A:=-1;

  TArray.Sort<TDataTrade>(Result,TComparer<TDataTrade>.Construct(
  function(const Left,Right: TDataTrade): Integer
  begin
    Result:=A*CompareDateTime(Left.Date,Right.Date);
  end));

end;

end.
