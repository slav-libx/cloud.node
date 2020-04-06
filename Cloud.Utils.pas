unit Cloud.Utils;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

function StrToAmount(const S: string): Extended;
function AmountToStr(Amount: Extended): string;
function Map(const Value: string; const A,B: TArray<string>; const Default: string=''): string;

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

function Map(const Value: string; const A,B: TArray<string>; const Default: string=''): string;
var I: Integer;
begin
  Result:=Default;
  if TArray.BinarySearch<string>(A,Value,I) then Result:=B[I];
end;

end.
