Unit blockart_ansiloader;
{$MODE objfpc}

Interface

Uses
  xStrings,
  xAnsi,
  m_types;
  
Const 
  //mysMaxMsgLines = 25;
  mysMaxMsgLines = 5000;

Type
  RecMessageLine = Array[1..80] of Record
                     Ch   : Char;
                     Attr : Byte;
                   End;

  AnsiImage = Array[1..mysMaxMsgLines] of RecMessageLine;
  // make this a pointer...

  TMsgBaseAnsi = Class
    GotAnsi  : Boolean;
    GotPipe  : Boolean;
    PipeCode : String[2];
    Owner    : Pointer;
    Data     : AnsiImage;
    Code     : String;
    Lines    : Word;
    CurY     : Word;
    Escape   : Byte;
    SavedX   : Byte;
    SavedY   : Byte;
    CurX     : Byte;
    Attr     : Byte;

    Procedure   SetFore (Color: Byte);
    Procedure   SetBack (Color: Byte);
    Procedure   ResetControlCode;
    Function    ParseNumber (Var Line: String) : Integer;
    Function    AddChar (Ch: Char) : Boolean;
    Procedure   MoveXY (X, Y: Word);
    Procedure   MoveUP;
    Procedure   MoveDOWN;
    Procedure   MoveLEFT;
    Procedure   MoveRIGHT;
    Procedure   MoveCursor;
    Procedure   CheckCode (Ch: Char);
    Procedure   ProcessChar (Ch: Char);
    
    Constructor Create (O: Pointer; Msg: Boolean);
    Destructor  Destroy; Override;
    Function    ProcessBuf (Var Buf; BufLen: Word) : Boolean;
    Procedure   DrawLine (Y, Line: Word; Flush: Boolean);
    Procedure   Clear;
    Function    GetLineText (Line: Word) : String;
    Procedure   SetLineColor (Attri, Line: Word);
    Procedure   RemoveLine (Line: Word);
  End;
  
  RecPercent = Record
    BarLength : Byte;
    LoChar    : Char;
    LoAttr    : Byte;
    HiChar    : Char;
    HiAttr    : Byte;
    Format    : Byte;
    StartY    : Byte;
    Active    : Boolean;
    StartX    : Byte;
    LastPos   : Byte;
    Reserved  : Array[1..3] of Byte;
  End;


  Function AnsiGotoXY (X, Y: Byte) : String;
  Procedure LoadAnsi2Image (FName: String; Var Img:TConsoleImageRec; Var Sauce:RecSauceInfo);
  

Implementation

Uses 
  XCrt,
  xfileio;
  
Procedure LoadAnsi2Image (FName: String; Var Img:TConsoleImageRec; Var Sauce:RecSauceInfo);
Var
  Buf      : Array[1..4096] of Char;
  BufLen   : LongInt;
  TopLine  : LongInt;
  WinSize  : LongInt;
  Ansi     : TMsgBaseAnsi;
  AFile    : File;
  oFile    : File;
  Ch       : Char;
  FN       : String;
  Str      : String;
  //Sauce    : RecSauceInfo;
  x,y      : Byte;
  Res      : LongInt;


  Procedure ReDraw;
  Begin
    WinSize := 24;
    TopLine := 1;
  End;

Begin
  FN       := FName;

  Screen.TextAttr:=7;
  
  If Not FileExist(FN) Then Exit;
  FillByte(sauce,sizeof(sauce),0);
  ReadSauceInfo(FN, Sauce);
  {If ReadSauceInfo(FN, Sauce) Then Begin
    Assign  (AFile, FN);
    Assign  (oFile, FN+'.tmp');
    ioReset (AFile, 1, fmReadWrite + fmDenyNone);
    ioReWrite (oFile, 1, fmReadWrite + fmDenyNone);
    Res := 0;
    //While Not Eof(AFile) And (Res<=Sauce.Filesize+1) Do Begin
    While Not Eof(AFile) Do Begin
      ioBlockRead  (AFile, Buf, SizeOf(Buf), BufLen);
      ioBlockWrite (oFile, Buf, SizeOf(Buf), BufLen);
    End;
    Close (AFile);
    Close (oFile);
    Fn:=Fname+'.tmp';
  End;}
  
  Ansi := TMsgBaseAnsi.Create(nil, False);
  ansi.clear;

  Assign  (AFile, FN);
  ioReset (AFile, 1, fmReadWrite + fmDenyNone);

  While Not Eof(AFile) Do Begin
    ioBlockRead (AFile, Buf, SizeOf(Buf), BufLen);
    If Ansi.ProcessBuf (Buf, BufLen) Then Break;
  End;
  
  Close (AFile);
  ReDraw;
  
    for y:=1 to 25 do 
      for x:=1 to 80 do begin
        img.data[y][x].attributes:=ansi.data[y][x].attr;
        img.data[y][x].UnicodeChar:=ansi.data[y][x].Ch;
      end;
  
  Ansi.Free;
  If FileExist(Fname+'.tmp') Then FileErase(Fname+'.tmp');
End; 


Constructor TMsgBaseAnsi.Create (O: Pointer; Msg: Boolean);
Begin
  Inherited Create;

  Owner := O;
  Clear;
End;

Destructor TMsgBaseAnsi.Destroy;
Begin
  Inherited Destroy;
End;

Procedure TMsgBaseAnsi.Clear;
Begin
  Lines    := 1;
  CurX     := 1;
  CurY     := 1;
  Attr     := 7;
  GotAnsi  := False;
  GotPipe  := False;
  PipeCode := '';

  FillChar (Data, SizeOf(Data), 0);

  ResetControlCode;
End;

Procedure TMsgBaseAnsi.ResetControlCode;
Begin
  Escape := 0;
  Code   := '';
End;

Procedure TMsgBaseAnsi.SetFore (Color: Byte);
Begin
  Attr := Color + ((Attr SHR 4) AND 7) * 16;
End;

Procedure TMsgBaseAnsi.SetBack (Color: Byte);
Begin
  Attr := (Attr AND $F) + Color * 16;
End;

Function TMsgBaseAnsi.AddChar (Ch: Char) : Boolean;
Begin
  AddChar := False;

  Data[CurY][CurX].Ch   := Ch;
  Data[CurY][CurX].Attr := Attr;

  If CurX < 80 Then
    Inc (CurX)
  Else Begin
    If CurY = mysMaxMsgLines Then Begin
      AddChar := True;
      Exit;
    End Else Begin
      CurX := 1;
      Inc (CurY);
    End;
  End;
End;

Function TMsgBaseAnsi.ParseNumber (Var Line: String) : Integer;
Var
  A    : Integer;
  B    : LongInt;
  Str1 : String;
  Str2 : String;
Begin
  Str1 := Line;

  Val(Str1, A, B);

  If B = 0 Then
    Str1 := ''
  Else Begin
    Str2 := Copy(Str1, 1, B - 1);

    Delete (Str1, 1, B);
    Val    (Str2, A, B);
  End;

  Line        := Str1;
  ParseNumber := A;
End;

Procedure TMsgBaseAnsi.MoveXY (X, Y: Word);
Begin
  If X > 80             Then X := 80;
  If Y > mysMaxMsgLines Then Y := mysMaxMsgLines;

  CurX := X;
  CurY := Y;
End;

Procedure TMsgBaseAnsi.MoveCursor;
Var
  X : Byte;
  Y : Byte;
Begin
  X := ParseNumber(Code);
  Y := ParseNumber(Code);

  If X = 0 Then X := 1;
  If Y = 0 Then Y := 1;

  MoveXY (X, Y);

  ResetControlCode;
End;

Procedure TMsgBaseAnsi.MoveUP;
Var
  NewPos : Integer;
  Offset : Integer;
Begin
  Offset := ParseNumber (Code);

  If Offset = 0 Then Offset := 1;

  If (CurY - Offset) < 1 Then
    NewPos := 1
  Else
    NewPos := CurY - Offset;

  MoveXY (CurX, NewPos);
  ResetControlCode;
End;

Procedure TMsgBaseAnsi.MoveDOWN;
Var
  NewPos : Byte;
Begin
  NewPos := ParseNumber (Code);

  If NewPos = 0 Then NewPos := 1;

  MoveXY (CurX, CurY + NewPos);

  ResetControlCode;
End;

Procedure TMsgBaseAnsi.MoveLEFT;
Var
  NewPos : Integer;
  Offset : Integer;
Begin
  Offset := ParseNumber (Code);

  If Offset = 0 Then Offset := 1;

  If CurX - Offset < 1 Then
    NewPos := 1
  Else
    NewPos := CurX - Offset;

  MoveXY (NewPos, CurY);

  ResetControlCode;
End;

Procedure TMsgBaseAnsi.MoveRIGHT;
Var
  NewPos : Integer;
  Offset : Integer;
Begin
  Offset := ParseNumber(Code);

  If Offset = 0 Then Offset := 1;

  If CurX + Offset > 80 Then Begin
    NewPos := (CurX + Offset) - 80;
    Inc (CurY);
  End Else
    NewPos := CurX + Offset;

  MoveXY (NewPos, CurY);

  ResetControlCode;
End;

Procedure TMsgBaseAnsi.CheckCode (Ch: Char);
Var
  Temp1 : Byte;
  Temp2 : Byte;
Begin
  Case Ch of
    '0'..'9', ';', '?' : Code := Code + Ch;
    'H', 'f'      : MoveCursor;
    'A'           : MoveUP;
    'B'           : MoveDOWN;
    'C'           : MoveRIGHT;
    'D'           : MoveLEFT;
    'J'           : Begin
                      {ClearScreenData;}
                      ResetControlCode;
                    End;
    'K'           : Begin
                      Temp1 := CurX;
                      For Temp2 := CurX To 80 Do
                        AddChar(' ');
                      MoveXY (Temp1, CurY);
                      ResetControlCode;
                    End;
    'h'           : ResetControlCode;
    'm'           : Begin
                      While Length(Code) > 0 Do Begin
                        Case ParseNumber(Code) of
                          0 : Attr := 7;
                          1 : Attr := Attr OR $08;
                          5 : Attr := Attr OR $80;
                          7 : Begin
                                Attr := Attr AND $F7;
                                Attr := ((Attr AND $70) SHR 4) + ((Attr AND $7) SHL 4) + Attr AND $80;
                              End;
                          30: Attr := (Attr AND $F8) + 0;
                          31: Attr := (Attr AND $F8) + 4;
                          32: Attr := (Attr AND $F8) + 2;
                          33: Attr := (Attr AND $F8) + 6;
                          34: Attr := (Attr AND $F8) + 1;
                          35: Attr := (Attr AND $F8) + 5;
                          36: Attr := (Attr AND $F8) + 3;
                          37: Attr := (Attr AND $F8) + 7;
                          40: SetBack (0);
                          41: SetBack (4);
                          42: SetBack (2);
                          43: SetBack (6);
                          44: SetBack (1);
                          45: SetBack (5);
                          46: SetBack (3);
                          47: SetBack (7);
                        End;
                      End;

                      ResetControlCode;
                    End;
    's'           : Begin
                      SavedX := CurX;
                      SavedY := CurY;
                      ResetControlCode;
                    End;
    'u'           : Begin
                      MoveXY (SavedX, SavedY);
                      ResetControlCode;
                    End;
  Else
    ResetControlCode;
  End;
End;

Procedure TMsgBaseAnsi.ProcessChar (Ch: Char);
Begin
  If GotPipe Then Begin
    PipeCode := PipeCode + Ch;

    If Length(PipeCode) = 2 Then Begin

      Case Str2Int(PipeCode) of
        00..
        15 : SetFore(Str2Int(PipeCode));
        16..
        23 : SetBack(Str2Int(PipeCode) - 16);
      Else
        AddChar('|');
        AddChar(PipeCode[1]);
        AddChar(PipeCode[2]);
      End;

      GotPipe  := False;
      PipeCode := '';
    End;

    Exit;
  End;

  Case Escape of
    0 : Begin
          Case Ch of
            #27 : Escape := 1;
            #9  : MoveXY (CurX + 8, CurY);
            #12 : {Edit.ClearScreenData};
          Else
            If Ch = '|' Then
              GotPipe := True
            Else
              AddChar (Ch);

            ResetControlCode;
          End;
        End;
    1 : If Ch = '[' Then Begin
           Escape  := 2;
           Code    := '';
           GotAnsi := True;
         End Else
           Escape := 0;
    2 : CheckCode(Ch);
  Else
    ResetControlCode;
  End;
End;

Function TMsgBaseAnsi.ProcessBuf (Var Buf; BufLen: Word) : Boolean;
Var
  Count  : Word;
  Buffer : Array[1..4096] of Char Absolute Buf;
Begin
  Result := False;

  For Count := 1 to BufLen Do Begin
    If CurY > Lines Then Lines := CurY;
    Case Buffer[Count] of
      #10 : If CurY = mysMaxMsgLines Then Begin
              Result  := True;
              GotAnsi := False;
              Break;
            End Else Begin
              CurY:=CurY+1;
              CurX := 1;
            End;
              
      #13 : CurX := 1;
      #26 : Begin
              Result := True;
              Break;
            End;
    Else
      ProcessChar(Buffer[Count]);
    End;
  End;
End;

Procedure TMsgBaseAnsi.DrawLine (Y, Line: Word; Flush: Boolean);
Var
  Count : Byte;
Begin
  BufAddStr(AnsiGotoXY(1, Y));

  If Line > Lines Then Begin
    BufAddStr(AttrToAnsi(7) + #27 + '[K');
  End Else
    For Count := 1 to 80 Do Begin
      BufAddStr (AttrToAnsi(Data[Line][Count].Attr));
      If Data[Line][Count].Ch in [#0, #255] Then
        BufAddStr(' ')
      Else
        BufAddStr (Data[Line][Count].Ch);
    End;

  If Flush Then BufFlush;
End;

Function TMsgBaseAnsi.GetLineText (Line: Word) : String;
Var
  Count : Word;
Begin
  Result := '';

  If Line > Lines Then Exit;

  For Count := 1 to 80 Do
    Result := Result + Data[Line][Count].Ch;
End;

Procedure TMsgBaseAnsi.SetLineColor (Attri, Line: Word);
Var
  Count : Word;
Begin
  For Count := 1 to 80 Do
    Data[Line][Count].Attr := Attri;
End;

Procedure TMsgBaseAnsi.RemoveLine (Line: Word);
Var
  Count : Word;
Begin
  For Count := Line to Lines - 1 Do
    Data[Count] := Data[Count + 1];

  Dec (Lines);
End;

Function AnsiGotoXY (X, Y: Byte) : String;
Begin

  If X = 0 Then X := WhereX;
  If Y = 0 Then Y := WhereY;

  Result := #27 + '[' + Int2Str(Y) + ';' + Int2Str(X) + 'H';
End;

End.
