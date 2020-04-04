unit Cloud.Utils;

interface

uses
  System.SysUtils;

function StrToAmount(const S: string): Extended;
function AmountToStr(Amount: Extended): string;

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

end.
