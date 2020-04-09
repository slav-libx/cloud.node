unit System.Console;

interface

type
  TConsole = class
  public
    function ReadKey: Word;
  end;

implementation

{$IFDEF MSWINDOWS}

uses
  Winapi.Windows;

function TConsole.ReadKey: Word;
var
  InputHandle: THandle;
  InputRecord: TInputRecord;
  Event: Cardinal;
begin
  Result:=0;
  InputHandle:=GetStdHandle(STD_INPUT_HANDLE);
  while ReadConsoleInput(InputHandle,InputRecord,1,Event) do
  if (InputRecord.EventType=KEY_EVENT) and InputRecord.Event.KeyEvent.bKeyDown then
    Exit(InputRecord.Event.KeyEvent.wVirtualKeyCode);
end;

{$ENDIF}

{$IFDEF LINUX}

function TConsole.ReadKey: Word;
begin
  Result:=0;
end;

{$ENDIF}

end.
