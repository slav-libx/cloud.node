unit Cloud.Log;

interface

procedure ToLog(const S: string);

implementation

uses
  System.SysUtils,
  System.IOUtils;

procedure ToLog(const S: string);
begin
  TFile.AppendAllText('cloud.log',
    FormatDateTime('[dd.mm.yyyy hh:nn:ss.zzz] ',Now)+S+#13#10,TEncoding.UTF8);
end;

end.


