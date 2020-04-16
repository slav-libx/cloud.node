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

function IsSystemKey(VirtualKeyCode: Word): Boolean;
begin
  Result:=VirtualKeyCode in [VK_LWIN,VK_RWIN,VK_APPS,VK_SHIFT,VK_CONTROL,VK_MENU];
end;

function IsValidInputKeyEvent(const InputRecord: TInputRecord): Boolean;
begin
  Result:=(InputRecord.EventType=KEY_EVENT) and InputRecord.Event.KeyEvent.bKeyDown
    and not IsSystemKey(InputRecord.Event.KeyEvent.wVirtualKeyCode);
end;

function TConsole.ReadKey: Word;
var
  InputHandle: THandle;
  InputRecord: TInputRecord;
  Event: Cardinal;
begin
  Result:=0;
  InputHandle:=GetStdHandle(STD_INPUT_HANDLE);
  while ReadConsoleInput(InputHandle,InputRecord,1,Event) do
  if IsValidInputKeyEvent(InputRecord) then
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
