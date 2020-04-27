unit Cloud.Server;

interface
uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Net.Socket,
  Cloud.Types;

type
  TCloudServer = class
  private
    Server: TTCPSocket;
    Port: Word;
    procedure OnServerConnect(Sender: TObject);
    procedure OnServerException(Sender: TObject);
    procedure OnServerAccept(Sender: TObject);
    procedure SendRequest(Client: TTCPSocket; const C,A: string);
    procedure SendResponse(Client: TTCPSocket; const C,A: string);
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

end;

destructor TCloudServer.Destroy;
begin
  Server.Terminate;
  Server.Free;
  Clients.Free;
  inherited;
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

  SendResponse(Client,'c2','*');

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

  if Request.Command='GetCurAddresses' then SendResponse(Client,'_GetCurAddresses','*') else
  if Request.Command='CheckPW' then SendResponse(Client,'_StartClient','*') else
  if Request.Command='_GetAccountBalance' then else
  if Request.Command='_UTransfer' then else
  if Request.Command='URKError' then else

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
  S:=C+' '+Client.Name+' '+A;
  Writeln(Client.Name+'>'+S);
  Client.Send(S+#13#10);
end;

end.
