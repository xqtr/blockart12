Unit blockart_types;
{$mode objfpc}

interface

Const
  ANSIClrScr = #27+'[2J';
  ANSIHome   = #27+'[1;1H';
  MysticClrScr  = '|CL';
  MysticNoPause = '|PO';
  MysticHome    = '|[X01|[Y01';

Type
  TLayerRec = Record
    Name      : String[12];
    idx       : Byte;
    BFlags    : LongInt;
    AFlags    : LongInt;
    delay     : Longint;
    Reserved  : Array[1..100] of byte;
  End;
  
TCharSet = Array[1..10] Of String[10];
  
  TGrChar = Record
    Ch          : Char;
    Color       : Byte;
    SelCharSet  : Byte;
    CharSet     : Array[1..10] Of String[10];
    OldX,
    OldY        : Byte;
    Tabs        : Byte;
    Ins         : Boolean;
    PX,PY       : Byte;
    FontFX      : String;
    FontFxSel   : Byte;
    FontFxCnt   : Byte;
    FontFxIdx   : Byte;
    CaseFXCap   : String;
    CaseFXLow   : String;
    CaseFXNum   : String;
    CaseFXSym   : String;
    CaseFxSel   : Byte;
    TDF         : String;
    TDFs        : byte;
    TDF_LWidth  : Byte;
    TDF_LHeight : Byte;
    SaveCur     : Boolean;
    Mouse       : Boolean;
    MouseBut    : Byte;
  End;
  
  TUndo = Record
    Index : Byte;
    Count : Byte;
    Max   : Byte;
  End;
  
  TSettings = Record
    Artist  : String[30];
    Group   : String[30];
    Title   : String[40];
    Sauce   : Boolean;
    CharSet : Byte;
    Folder  : String;
    PGKeys  : Boolean;
    TransChar : Char;
    TransAttr : Byte;
    Tab       : String[80];
  End;

implementation

begin
end.
