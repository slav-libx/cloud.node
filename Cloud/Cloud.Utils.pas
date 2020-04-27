unit Cloud.Utils;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Cloud.Consts;

function StrToAmount(const S: string): Extended;
function StrToAmountDef(const S: string; Default: Extended): Extended;
function AmountToStr(Amount: Extended): string;
function AmountToStrI(Amount: Extended): string;
function SymbolToPort(const Symbol: string; const Default: string=''): string;
function PortToSymbol(const Port: string; const Default: string=''): string;
function SymbolID(const Symbol: string; const Default: Integer=0): Integer;
function SymbolBy(SymbolID: Integer; const Default: string=''): string;
function Skip(const S: string; const SkipChars: array of Char; Count: Integer): string;
function Map(const Value: string; const A,B: TArray<string>; const Default: string=''): string;

implementation

var
  Invariant: TFormatSettings;

function StrToAmount(const S: string): Extended;
begin
  Result:=StrToFloat(S.Replace(',',Invariant.DecimalSeparator),Invariant);
end;

function StrToAmountDef(const S: string; Default: Extended): Extended;
begin
  Result:=StrToFloatDef(S.Replace(',',Invariant.DecimalSeparator),
    Default,Invariant);
end;

function AmountToStr(Amount: Extended): string;
begin
  Result:=FormatFloat('0.00######',Amount);
end;

function AmountToStrI(Amount: Extended): string;
begin
  Result:=FormatFloat('0.00######',Amount,Invariant);
end;

function IndexOf(const Value: string; const A: TArray<string>): Integer;
begin
  for Result:=0 to High(A) do if SameText(A[Result],Value) then Exit;
  Result:=-1;
end;

function Map(const Value: string; const A,B: TArray<string>; const Default: string=''): string;
var I: Integer;
begin
  Result:=Default;
  I:=IndexOf(Value,A);
  if I<>-1 then Result:=B[I];
end;

function SymbolToPort(const Symbol: string; const Default: string=''): string;
begin
  Result:=Map(Symbol,['BTC','LTC','ETH'],[PORT_BITCOIN,PORT_LIGHTCOIN,PORT_ETHEREUM],Default);
end;

function PortToSymbol(const Port: string; const Default: string=''): string;
begin
  Result:=Map(Port,[PORT_BITCOIN,PORT_LIGHTCOIN,PORT_ETHEREUM],['BTC','LTC','ETH'],Default);
end;

function SymbolID(const Symbol: string; const Default: Integer=0): Integer;
begin
  Result:=Map(Symbol,['BTC','LTC','ETH','RLC','GTN'],['1','2','3','4','5'],Default.ToString).ToInteger;
end;

function SymbolBy(SymbolID: Integer; const Default: string=''): string;
begin
  Result:=Map(SymbolID.ToString,['1','2','3','4','5'],['BTC','LTC','ETH','RLC','GTN'],Default);
end;

function Skip(const S: string; const SkipChars: array of Char; Count: Integer): string;
var P: Integer;
begin
  P:=0;
  while Count>0 do
  begin
    P:=S.IndexOfAny(SkipChars,P);
    if P=-1 then Exit('');
    Dec(Count);
    Inc(P);
  end;
  Result:=S.Substring(P);
end;

initialization
  Invariant:=TFormatSettings.Invariant;

end.
