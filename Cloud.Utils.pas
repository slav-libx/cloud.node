unit Cloud.Utils;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Cloud.Consts;

function StrToAmount(const S: string): Extended;
function AmountToStr(Amount: Extended): string;
function SymbolToPort(const Symbol: string): string;

implementation

function StrToAmount(const S: string): Extended;
begin
  Result:=StrToFloat(S.Replace(',',FormatSettings.Invariant.DecimalSeparator),
    FormatSettings.Invariant);
end;

function AmountToStr(Amount: Extended): string;
begin
  Result:=FormatFloat('0.00######',Amount);
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

function SymbolToPort(const Symbol: string): string;
begin
  Result:=Map(Symbol,['BTC','LTC','ETH'],[PORT_BITCOIN,PORT_LIGHTCOIN,PORT_ETHEREUM]);
end;

end.
