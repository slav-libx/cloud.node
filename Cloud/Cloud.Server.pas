unit Cloud.Server;

interface
uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.DateUtils,
  Net.Socket,
  Lib.Timer,
  Cloud.Types;

type
  TCloudServer = class
  private
    Server: TTCPSocket;
    NotifyTimer: TTimer;
    Port: Word;
    procedure OnServerConnect(Sender: TObject);
    procedure OnServerException(Sender: TObject);
    procedure OnServerAccept(Sender: TObject);
    procedure SendRequest(Client: TTCPSocket; const C,A: string);
    procedure SendResponse(Client: TTCPSocket; const C,A: string);
    procedure SetNotifications(Client: TTCPSocket; const Request: TCloudRequest);
  private
    Clients: TObjectList<TTCPSocket>;
    procedure OnClientReceived(Sender: TObject);
    procedure OnClientClose(Sender: TObject);
    procedure OnClientException(Sender: TObject);
  private
    procedure ExecCommand(const C: string);
  public
    constructor Create(Port: Word);
    destructor Destroy; override;
    procedure Run;
  end;

implementation

{ TCloudServer }

constructor TCloudServer.Create(Port: Word);
begin

  Self.Port:=Port;

  Clients:=TObjectList<TTCPSocket>.Create;

  Server:=TTCPSocket.Create;
  Server.OnConnect:=OnServerConnect;
  Server.OnAccept:=OnServerAccept;
  Server.OnExcept:=OnServerException;

  NotifyTimer:=TTimer.Create;
  NotifyTimer.Interval:=6000;
  NotifyTimer.OnTimerProc:=

  procedure
  begin
    for var C in Clients do SendResponse(C,'NotifyEvent','2');
  end;

end;

destructor TCloudServer.Destroy;
begin
  Server.Terminate;
  Server.Free;
  Clients.Free;
  inherited;
end;

procedure TCloudServer.SetNotifications(Client: TTCPSocket; const Request: TCloudRequest);
begin
  var A:=Request.Args.Split([' ',#13,#10])[2];
  if A='1' then
  begin
    NotifyTimer.Enabled:=True;
    SendResponse(Client,'_SetNotifications','1');
  end else begin
    NotifyTimer.Enabled:=False;
    SendResponse(Client,'_SetNotifications','0');
  end;
end;

procedure TCloudServer.Run;
begin

  Server.Start(Port);

  TThread.CreateAnonymousThread(
  procedure
  var Command: string;
  begin

    while True do
    begin

      Readln(Command);

      if Command<>'' then
      
      TThread.Synchronize(nil,
      procedure
      begin
        try
          ExecCommand(Command);
        except on E: Exception do Writeln(E.Message);
        end;
      end);

    end;

  end).Start;

  while True do CheckSynchronize(100);

end;

procedure TCloudServer.OnServerConnect(Sender: TObject);
begin
  Writeln('server started on port '+Port.ToString);
end;

procedure TCloudServer.OnServerException(Sender: TObject);
begin
  Writeln('server except: '+Server.E.Message);
end;

var ClientIdentity: Integer;

procedure TCloudServer.OnServerAccept(Sender: TObject);
var Client: TTCPSocket;
begin

  Inc(ClientIdentity);

  Client:=TTCPSocket.Create(Server.Accept);
  Client.Name:='U'+ClientIdentity.ToString;

  Client.OnReceived:=OnClientReceived;
  Client.OnClose:=OnClientClose;
  Client.OnExcept:=OnClientException;

  Client.Connect;

  Clients.Add(Client);

  Writeln('client ('+Client.Name+') connected');

  SendResponse(Client,'c2','');

end;

function TruncSeconds(Value: TDateTime): TDateTime;
var AYear, AMonth, ADay, AHour, AMinute, ASecond, AMilliSecond: Word;
begin
  DecodeDateTime(Value,AYear,AMonth,ADay,AHour,AMinute,ASecond,AMilliSecond);
  Result:=EncodeDateTime(AYear,AMonth,ADay,AHour,AMinute,0,0);
end;

procedure TCloudServer.OnClientReceived(Sender: TObject);
var
  S: string;
  Client: TTCPSocket;
  Request: TCloudResponse;
begin

  Client:=TTCPSocket(Sender);

  S:=Client.ReceiveString;

  Writeln(Client.Name+'<'+S);

  Request:=S;

  if Request.Command='GetCurAddresses' then SendResponse(Client,'_GetCurAddresses','') else
  if Request.Command='CheckPW' then SendResponse(Client,'_StartClient','') else
  if Request.Command='_GetAccountBalance' then else
  if Request.Command='_UTransfer' then else
  if Request.Command='URKError' then else
  if Request.Command='GetCandles' then SendResponse(Client,'_GetCandles','4 1 1 <'+DateTimeToUnix(TruncSeconds(Now),False).ToString+' 0.0343 0.0356 0.0333 0.041 2.4323>') else
  if Request.Command='SetNotifications' then SetNotifications(Client,Request) else

    SendResponse(Client,'URKError','* 0')

end;

procedure TCloudServer.OnClientClose(Sender: TObject);
begin
  Writeln('client ('+TTCPSocket(Sender).Name+') closed');
  Clients.Remove(TTCPSocket(Sender));
end;

procedure TCloudServer.OnClientException(Sender: TObject);
begin
  Writeln('client ('+TTCPSocket(Sender).Name+') except: '+TTCPSocket(Sender).E.Message);
end;

procedure TCloudServer.ExecCommand(const C: string);
var
  Client: TTCPSocket;
  Request: TCloudResponse;
begin

  Request:=C;

  if Request.Command='gb' then Request:='GetAccountBalance' else
  if Request.Command='tr' then Request:='UTransfer 3 4 20.00' else
  ;

  for Client in Clients do SendRequest(Client,Request.Command,Request.Args);

end;

procedure TCloudServer.SendRequest(Client: TTCPSocket; const C,A: string);
var S: string;
begin
  S:=C+' '+Client.Name+' '+A;
  Writeln(Client.Name+'>'+S);
  Client.Send(S+#13#10);
end;

procedure TCloudServer.SendResponse(Client: TTCPSocket; const C,A: string);
var S: string;
begin
  S:=C+' '+Client.Name+' * '+A;
  Writeln(Client.Name+'>'+S);
  Client.Send(S+#13#10);
end;

end.
