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
    function SortByDate: TOffers;
  end;

  TPair = record
    Symbol1: string;
    Symbol2: string;
    Ratio: Extended;
    Volume: Extended;
    LastDate: TDateTime;
    Ratio24hAgo: Extended;
    class operator Implicit(const Pair: TPair): string;
  end;

  TPairs = array of TPair;

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
    AmountToStr(Offer.StrtAmount).PadRight(10)+
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

function TOffersHelper.SortByDate: TOffers;
begin

  Result:=Copy;

  TArray.Sort<TOffer>(Result,TComparer<TOffer>.Construct(
  function(const Left,Right: TOffer): Integer
  begin
    Result:=CompareDateTime(Left.StartDate,Right.StartDate);
  end));

end;

class operator TPair.Implicit(const Pair: TPair): string;
var Change: Extended;
begin

  if Pair.Ratio24hAgo>0 then
    Change:=100*(1-Pair.Ratio/Pair.Ratio24hAgo)
  else
    Change:=0;

  Result:=
    (Pair.Symbol1+'/'+Pair.Symbol2).PadRight(10)+
    AmountToStr(Pair.Volume).PadRight(10)+
    AmountToStr(Pair.Ratio).PadRight(10)+
    FormatFloat('+0.0#%;-0.0#%',Change).PadRight(9)+
    DateTimeToStr(Pair.LastDate);

end;

end.
