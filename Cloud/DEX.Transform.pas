unit DEX.Transform;

interface

uses
  System.SysUtils,
  System.DateUtils,
  System.Math,
  Charts.Math,
  Candles.Types,
  Measures.Types,
  DEX.Types;

const
  CANDLE_DURATION = 1000;
type
  TCandlesTransform = class
  private const

    UNIX_MINUTE = 60;
    UNIX_5_MINUTE = 5*UNIX_MINUTE;
    UNIX_15_MINUTE = 15*UNIX_MINUTE;
    UNIX_30_MINUTE = 30*UNIX_MINUTE;
    UNIX_HOUR = 60*UNIX_MINUTE;
    UNIX_2_HOUR = 2*UNIX_HOUR;
    UNIX_6_HOUR = 6*UNIX_HOUR;
    UNIX_12_HOUR = 12*UNIX_HOUR;
    UNIX_DAY = 24*UNIX_HOUR;
    UNIX_WEEK = 7*UNIX_DAY;

    DIV_MINUTE_COUNT = 5;
    DIV_5_MINUTE_COUNT = 6;
    DIV_15_MINUTE_COUNT = 4;
    DIV_30_MINUTE_COUNT = 6;
    DIV_HOUR_COUNT = 6;
    DIV_2_HOUR_COUNT = 6;
    DIV_6_HOUR_COUNT = 8;
    DIV_12_HOUR_COUNT = 6;
    DIV_DAY_COUNT = 5;
    DIV_WEEK_COUNT = 6;
    DIV_MONTH_COUNT = 6;

  private
    IntervalCode: Integer;
    StartDateTime: TDateTime;
    EndDateTime: TDateTime;
    FirstTime: Int64;
    LastDateTime: TDateTime;
    LastTime: Int64;
    EndIntervalTime: Int64;
    LastClose: Extended;
    MinValue: Extended;
    MaxValue: Extended;
    procedure DoExceptionIntervalCode; inline;
    function UnixTimeToTime(UnixTime: Int64): Int64;
    function TimeToDateTime(Time: Int64): TDateTime;
    function DecOneInterval(UnixTime: Int64): Int64;
    function GetDivFirstTime: Int64;
    function GetAlignedTime(UnixTime: Int64): Int64;
    function GetDivDuration: Int64;
    function FormatTime(DateTime: TDateTime): string;
    function FormatTitleTime(DateTime: TDateTime): string;
  public
    constructor Create;
    function AddDataCandle(IntervalCode: Integer; const Candles: TDataCandles): TCandles;
    procedure Clear;
    function GetLastTime: Int64;
    function GetLastDateTime: TDateTime;
    function GetValueMeasure: TMeasures;
    function GetElapsesMeasure: TElapses;
    function GetIntervalCode: Integer;
    procedure InitStartInterval(IntervalCode: Integer);
    function GetStartDateTime: TDateTime;
    function GetTime: Int64;
  end;

implementation

constructor TCandlesTransform.Create;
begin
  Clear;
end;

function TCandlesTransform.GetIntervalCode: Integer;
begin
  Result:=IntervalCode;
end;

function TCandlesTransform.GetLastTime: Int64;
begin
  Result:=LastTime;
end;

function TCandlesTransform.GetTime: Int64;
begin
  if LastTime=0 then
    Result:=EndIntervalTime
  else
    Result:=LastTime;
end;

function TCandlesTransform.GetLastDateTime: TDateTime;
begin
  Result:=LastDateTime;
end;

procedure TCandlesTransform.DoExceptionIntervalCode;
begin
  raise Exception.Create('candles transform: invalid interval code: '+IntervalCode.ToString);
end;

procedure TCandlesTransform.InitStartInterval(IntervalCode: Integer);
begin

  case IntervalCode of
  1: StartDateTime:=IncMinute(Now,-60);
  2: StartDateTime:=IncMinute(Now,-80*5);
  3: StartDateTime:=IncMinute(Now,-60*15);
  4: StartDateTime:=IncMinute(Now,-40*30);
  5: StartDateTime:=IncHour(Now,-40);
  6: StartDateTime:=IncHour(Now,-40*2);
  7: StartDateTime:=IncHour(Now,-40*6);
  8: StartDateTime:=IncHour(Now,-40*12);
  9: StartDateTime:=IncDay(Now,-40);
  10: StartDateTime:=IncWeek(Now,-40);
  11: StartDateTime:=IncMonth(Now,-40);
  else DoExceptionIntervalCode;
  end;

  Clear;

  Self.IntervalCode:=IntervalCode;
  FirstTime:=GetAlignedTime(DateTimeToUnix(StartDateTime,False));
  EndIntervalTime:=UnixTimeToTime(DateTimeToUnix(Now,False));

end;

function TCandlesTransform.GetStartDateTime: TDateTime;
begin
  Result:=StartDateTime;
end;

function TCandlesTransform.GetAlignedTime(UnixTime: Int64): Int64;
begin

  case IntervalCode of
  1: Result:=(UnixTime div UNIX_MINUTE)*UNIX_MINUTE;
  2: Result:=(UnixTime div UNIX_5_MINUTE)*UNIX_5_MINUTE;
  3: Result:=(UnixTime div UNIX_15_MINUTE)*UNIX_15_MINUTE;
  4: Result:=(UnixTime div UNIX_30_MINUTE)*UNIX_30_MINUTE;
  5: Result:=(UnixTime div UNIX_HOUR)*UNIX_HOUR;
  6: Result:=(UnixTime div UNIX_2_HOUR)*UNIX_2_HOUR;
  7: Result:=(UnixTime div UNIX_6_HOUR)*UNIX_6_HOUR;
  8: Result:=(UnixTime div UNIX_12_HOUR)*UNIX_12_HOUR;
  9: Result:=(UnixTime div UNIX_DAY)*UNIX_DAY;
  10: Result:=(UnixTime div UNIX_WEEK)*UNIX_WEEK-UNIX_DAY*3; // unix 0 time is thursday
  11: Result:=DateTimeToUnix(StartOfTheYear(UnixToDateTime(UnixTime)));
  else DoExceptionIntervalCode;
  end;

end;

function TCandlesTransform.UnixTimeToTime(UnixTime: Int64): Int64;
begin

  case IntervalCode of
  1: Result:=((UnixTime-FirstTime) div UNIX_MINUTE)*CANDLE_DURATION;
  2: Result:=((UnixTime-FirstTime) div UNIX_5_MINUTE)*CANDLE_DURATION;
  3: Result:=((UnixTime-FirstTime) div UNIX_15_MINUTE)*CANDLE_DURATION;
  4: Result:=((UnixTime-FirstTime) div UNIX_30_MINUTE)*CANDLE_DURATION;
  5: Result:=((UnixTime-FirstTime) div UNIX_HOUR)*CANDLE_DURATION;
  6: Result:=((UnixTime-FirstTime) div UNIX_2_HOUR)*CANDLE_DURATION;
  7: Result:=((UnixTime-FirstTime) div UNIX_6_HOUR)*CANDLE_DURATION;
  8: Result:=((UnixTime-FirstTime) div UNIX_12_HOUR)*CANDLE_DURATION;
  9: Result:=((UnixTime-FirstTime) div UNIX_DAY)*CANDLE_DURATION;
  10: Result:=((UnixTime-FirstTime) div UNIX_WEEK)*CANDLE_DURATION;
  11: Result:=MonthsBetween(UnixToDateTime(FirstTime),StartOfTheMonth(UnixToDateTime(UnixTime)))*CANDLE_DURATION;
  else DoExceptionIntervalCode;
  end;

end;

function TCandlesTransform.TimeToDateTime(Time: Int64): TDateTime;
begin

  case IntervalCode of
  1: Time:=(Time div CANDLE_DURATION)*UNIX_MINUTE+FirstTime;
  2: Time:=(Time div CANDLE_DURATION)*UNIX_5_MINUTE+FirstTime;
  3: Time:=(Time div CANDLE_DURATION)*UNIX_15_MINUTE+FirstTime;
  4: Time:=(Time div CANDLE_DURATION)*UNIX_30_MINUTE+FirstTime;
  5: Time:=(Time div CANDLE_DURATION)*UNIX_HOUR+FirstTime;
  6: Time:=(Time div CANDLE_DURATION)*UNIX_2_HOUR+FirstTime;
  7: Time:=(Time div CANDLE_DURATION)*UNIX_6_HOUR+FirstTime;
  8: Time:=(Time div CANDLE_DURATION)*UNIX_12_HOUR+FirstTime;
  9: Time:=(Time div CANDLE_DURATION)*UNIX_DAY+FirstTime;
  10: Time:=(Time div CANDLE_DURATION)*UNIX_WEEK+FirstTime;
  11: begin
      Result:=UnixToDateTime(FirstTime,False);
      Exit(IncMonth(Result,Time div CANDLE_DURATION));
      end
  else DoExceptionIntervalCode;
  end;

  Result:=UnixToDateTime(Time,False);

end;

function TCandlesTransform.DecOneInterval(UnixTime: Int64): Int64;
begin

  case IntervalCode of
  1: Result:=UnixTime-UNIX_MINUTE;
  2: Result:=UnixTime-UNIX_5_MINUTE;
  3: Result:=UnixTime-UNIX_15_MINUTE;
  4: Result:=UnixTime-UNIX_30_MINUTE;
  5: Result:=UnixTime-UNIX_HOUR;
  6: Result:=UnixTime-UNIX_2_HOUR;
  7: Result:=UnixTime-UNIX_6_HOUR;
  8: Result:=UnixTime-UNIX_12_HOUR;
  9: Result:=UnixTime-UNIX_DAY;
  10: Result:=UnixTime-UNIX_WEEK;
  11: Result:=DateTimeToUnix(IncMonth(UnixToDateTime(UnixTime),-1));
  else DoExceptionIntervalCode;
  end;

end;


function TCandlesTransform.GetDivFirstTime: Int64;
begin
  case IntervalCode of
  1: Result:=-((FirstTime mod (UNIX_MINUTE*DIV_MINUTE_COUNT)) div UNIX_MINUTE)*CANDLE_DURATION;
  2: Result:=-((FirstTime mod (UNIX_5_MINUTE*DIV_5_MINUTE_COUNT)) div UNIX_5_MINUTE)*CANDLE_DURATION;
  3: Result:=-((FirstTime mod (UNIX_15_MINUTE*DIV_15_MINUTE_COUNT)) div UNIX_15_MINUTE)*CANDLE_DURATION;
  4: Result:=-((FirstTime mod (UNIX_30_MINUTE*DIV_30_MINUTE_COUNT)) div UNIX_30_MINUTE)*CANDLE_DURATION;
  5: Result:=-((FirstTime mod (UNIX_HOUR*DIV_HOUR_COUNT)) div UNIX_HOUR)*CANDLE_DURATION;
  6: Result:=-((FirstTime mod (UNIX_2_HOUR*DIV_2_HOUR_COUNT)) div UNIX_2_HOUR)*CANDLE_DURATION;
  7: Result:=-((FirstTime mod (UNIX_6_HOUR*DIV_6_HOUR_COUNT)) div UNIX_6_HOUR)*CANDLE_DURATION;
  8: Result:=-((FirstTime mod (UNIX_12_HOUR*DIV_12_HOUR_COUNT)) div UNIX_12_HOUR)*CANDLE_DURATION;
  9: Result:=-((FirstTime mod (UNIX_DAY*DIV_DAY_COUNT)) div UNIX_DAY)*CANDLE_DURATION;
  10: Result:=-((FirstTime mod (UNIX_WEEK*DIV_WEEK_COUNT)) div UNIX_WEEK)*CANDLE_DURATION;
  11: Result:=0;
  else DoExceptionIntervalCode;
  end;
end;

function TCandlesTransform.GetDivDuration: Int64;
begin
  case IntervalCode of
  1: Result:=DIV_MINUTE_COUNT*CANDLE_DURATION;
  2: Result:=DIV_5_MINUTE_COUNT*CANDLE_DURATION;
  3: Result:=DIV_15_MINUTE_COUNT*CANDLE_DURATION;
  4: Result:=DIV_30_MINUTE_COUNT*CANDLE_DURATION;
  5: Result:=DIV_HOUR_COUNT*CANDLE_DURATION;
  6: Result:=DIV_2_HOUR_COUNT*CANDLE_DURATION;
  7: Result:=DIV_6_HOUR_COUNT*CANDLE_DURATION;
  8: Result:=DIV_12_HOUR_COUNT*CANDLE_DURATION;
  9: Result:=DIV_DAY_COUNT*CANDLE_DURATION;
  10: Result:=DIV_WEEK_COUNT*CANDLE_DURATION;
  11: Result:=DIV_MONTH_COUNT*CANDLE_DURATION;
  else DoExceptionIntervalCode;
  end;
end;

function TCandlesTransform.FormatTime(DateTime: TDateTime): string;
begin
  case IntervalCode of
  1: Result:=FormatDateTime('hh:mm',DateTime);
  2: Result:=FormatDateTime('hh:mm',DateTime);
  3: Result:=FormatDateTime('hh:mm',DateTime);
  4: Result:=FormatDateTime('hh:mm',DateTime);
  5: Result:=FormatDateTime('dd.mm hh:mm',DateTime);
  6: Result:=FormatDateTime('dd.mm hh:mm',DateTime);
  7: Result:=FormatDateTime('dd.mm hh:mm',DateTime);
  8: Result:=FormatDateTime('dd.mm hh:mm',DateTime);
  9: Result:=FormatDateTime('dd.mm.yyyy',DateTime);
  10: Result:=FormatDateTime('dd.mm.yyyy',DateTime);
  11: Result:=FormatDateTime('mmm yyyy',DateTime);
  else DoExceptionIntervalCode;
  end;
end;

function TCandlesTransform.FormatTitleTime(DateTime: TDateTime): string;
begin
  case IntervalCode of
  1..8: Result:=FormatDateTime('dd.mm.yyyy hh:mm',DateTime);
  9,10: Result:=FormatDateTime('dd.mm.yyyy',DateTime);
  11:   Result:=FormatDateTime('mmmm yyyy',DateTime);
  else DoExceptionIntervalCode;
  end;
end;

procedure TCandlesTransform.Clear;
begin
  FirstTime:=0;
  LastTime:=0;
  LastClose:=0;
  LastDateTime:=0;
  MinValue:=0;
  MaxValue:=0;
end;

function TCandlesTransform.AddDataCandle(IntervalCode: Integer; const Candles: TDataCandles): TCandles;
var
  C: TCandle;
  Candle: TDataCandle;
  DateTime: TDateTime;
  CandleTime: Int64;
begin

  Result:=nil;

  for Candle in Candles do
  begin

    CandleTime:=DecOneInterval(Candle.Time);

    if LastTime=0 then
    begin
      MinValue:=Candle.Min;
      MaxValue:=Candle.Max;
    end else begin
      MinValue:=Min(MinValue,Candle.Min);
      MaxValue:=Max(MaxValue,Candle.Max);
    end;

    DateTime:=UnixToDateTime(CandleTime,False);

    LastTime:=UnixTimeToTime(CandleTime);

    C.Title:=FormatTitleTime(DateTime);
    C.DateTime:=DateTime;
    C.Min:=Candle.Min;
    C.Max:=Candle.Max;
    C.Open:=Candle.Open;
    C.Close:=Candle.Close;
    C.Volume:=Candle.Volume;
    C.Time:=LastTime;
    C.Duration:=CANDLE_DURATION;

    LastTime:=LastTime+C.Duration;
    LastDateTime:=Candle.DateTime;
    LastClose:=C.Close;

    Result:=Result+[C];

  end;

end;

function GetValueStep(Interval: Extended; Count: Integer; out Digits: Integer): Extended;
var M: Extended;
begin

  Result:=Interval;

  if Result=0 then Exit(0);

  M:=1;
  Digits:=1;

  while Result/M<1 do begin M:=M/10; Inc(Digits) end;
  while Result/M>10 do begin M:=M*10; Dec(Digits) end;

  Result:=FloatDiv(Result/Count,M/10*5);

  if Result=0 then Result:=M/10*5;

end;

function TCandlesTransform.GetValueMeasure: TMeasures;
var
  M: TMeasure;
  Value,Step: Extended;
  Digits: Integer;
  S: string;
begin

  Result:=nil;

  Step:=GetValueStep(Self.MaxValue-Self.MinValue,3,Digits);

  if Step<=0 then Exit;

  Value:=FloatDiv(Self.MaxValue,Step)+Step;

  S:='0.'+string.Create('0',Digits);

  repeat

    M.Value:=Value;
    M.Text:=FormatFloat(S,M.Value);

    Result:=Result+[M];

    Value:=Value-Step;

  until Value<MinValue-Step;

end;

function TCandlesTransform.GetElapsesMeasure: TElapses;
var
  C,DivDuration: Int64;
  E: TElapse;
begin

  Result:=nil;

  C:=GetDivFirstTime;

  DivDuration:=GetDivDuration;

  repeat

    E.Time:=C;
    E.DateTime:=TimeToDateTime(E.Time);
    E.Text:=FormatTime(E.DateTime);

    C:=C+DivDuration;

    Result:=Result+[E];

  until E.Time>GetTime;

end;

end.
