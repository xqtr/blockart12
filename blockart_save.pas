// ====================================================================
// BlockArt ANSI Editor                                written by xqtr
//                                                 xqtr.xqtr#gmail.com
// ====================================================================
//
// This file is part of BlockArt ANSI Editor.
//
// BlockArt is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// BlockArt, is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// For additional info of the license see <http://www.gnu.org/licenses/>.
//
// ====================================================================

Unit blockart_save;
{$mode objfpc}
{$h-}
Interface

Uses
  DOS,
  xStrings,
  xCrt,
  XMenuBox,
  xMenuForm,
  xfileio,
  blockart_types,
  xDateTime,
  blockart_dialogs,
  xMenuInput;
  
Type
  RecAnsiBufferChar = Record
                        Ch   : Char;
                        Attr : Byte;
                      End;

  RecAnsiBufferLine = Array[1..80] of RecAnsiBufferChar;
  RecAnsiBuffer     = Array[1..1000] of RecAnsiBufferLine;

Var
    SaveCur : Boolean;  
  
Function Ansi_Color (B : Byte; Attr: Byte) : String;  
Procedure SaveScreenANSI(Filename: String; Image: TConsoleImageRec;  GetPrep:Boolean);
Procedure SaveScreenBLOCKART(Filename: String; Image: TConsoleImageRec; Rec:TLayerRec);
Procedure SaveScreenMYSTIC(Filename: String; Image: TConsoleImageRec);
Procedure SaveScreenTEXT(Filename: String; Image: TConsoleImageRec);
Procedure SaveScreenPascal(Filename: String; Image: TConsoleImageRec);
Function GetLineText (Image: TConsoleImageRec; Line: Byte) : String;
Function GetLineLength (Image: TConsoleImageRec; Line:Byte) : Byte;
Procedure SetLineText (Var Image: TConsoleImageRec; Start: Byte; Line: LongInt; Str: String; Attr: Byte);
Function IsImageEmpty(Image: TConsoleImageRec):Boolean;
Function FindLastLine(Image: TConsoleImageRec):Byte;

Function LoadAnsiImage (FName: String; Var Image:TConsoleImageRec):Boolean;
Function LoadBlockartImage(Filename: String; Var Image: TConsoleImageRec; Var Rec:TLayerRec):boolean;

Implementation

Uses blockart_ansiloader;
  
Const EOL = #13#10;
  
Function IsImageEmpty(Image: TConsoleImageRec):Boolean;
Var
  x,y:byte;
Begin
  Result:=False;
  For Y:=1 to 25 Do
    For X:=1 to 80 Do
      If (Image.Data[y][x].UnicodeChar<>#32) Or (Image.Data[y][x].Attributes<>7) Then Exit;
  Result:=True;
End;
 
Function GetLineLength (Image: TConsoleImageRec; Line:Byte) : Byte;
Begin
  Result := 80;

  While (Result > 0) and (Image.Data[Line][Result].UnicodeChar = #0) Do
    Dec (Result);
End; 
 
Function GetLineText (Image: TConsoleImageRec; Line: Byte) : String;
Var
  Count : Byte;
Begin
  Result := '';

  For Count := 1 to GetLineLength(Image, Line) Do
    If Image.Data[Line][Count].UnicodeChar = #0 Then
      Result := Result + ' '
    Else
      Result := Result + Image.Data[Line][Count].UnicodeChar;
End;
 
Function IsBlankLine (Image: TConsoleImageRec; Line:Byte) : Boolean;
Var
  EndPos : Byte;
  Data   : Array[1..255] of RecAnsiBufferChar absolute Line;
Begin
  EndPos := 80;

  While (EndPos > 0) and (Image.Data[Line][EndPos].UnicodeChar = #0) Do
    Dec (EndPos);

  Result := EndPos = 0;
End;

Function IsAnsiLine (Image: TConsoleImageRec; Line: LongInt) : Boolean;
Var
  Count : Byte;
Begin
  Result := False;

  For Count := 1 to 80 Do
    If (Ord(Image.Data[Line][Count].UnicodeChar) < 32) or (Ord(Image.Data[Line][Count].UnicodeChar) > 128) Then Begin
      Result := True;
      Exit;
    End;
End; 

Procedure SetLineText (Var Image: TConsoleImageRec; Start: Byte; Line: LongInt; Str: String; Attr: Byte);
Var
  Count : Byte;
Begin
  FillByte (Image.Data[Line], SizeOf(Image.Data[Line]), 0);

  For Count := 1 to Length(Str) Do Begin
    Image.Data[Line][Start+Count].UnicodeChar   := Str[Count];
    Image.Data[Line][Start+Count].Attributes    := Attr;
  End;
End;

Function FindLastLine(Image: TConsoleImageRec):Byte;
Var
  LastLine : Byte;
Begin
  LastLine := 25;

  While (LastLine > 1) And IsBlankLine(Image,LastLine) Do
    Dec(LastLine);

  Result := LastLine;
End;

Function Ansi_Color (B : Byte; Attr: Byte) : String;
  Var
    S : String;
  Begin
    S          := '';
    Ansi_Color := '';

    Case B of
      00: S := #27 + '[0;30m';
      01: S := #27 + '[0;34m';
      02: S := #27 + '[0;32m';
      03: S := #27 + '[0;36m';
      04: S := #27 + '[0;31m';
      05: S := #27 + '[0;35m';
      06: S := #27 + '[0;33m';
      07: S := #27 + '[0;37m';
      08: S := #27 + '[1;30m';
      09: S := #27 + '[1;34m';
      10: S := #27 + '[1;32m';
      11: S := #27 + '[1;36m';
      12: S := #27 + '[1;31m';
      13: S := #27 + '[1;35m';
      14: S := #27 + '[1;33m';
      15: S := #27 + '[1;37m';
    End;

    If B in [00..07] Then B := (Attr SHR 4) and 7 + 16;

    Case B of
      16: S := S + #27 + '[40m';
      17: S := S + #27 + '[44m';
      18: S := S + #27 + '[42m';
      19: S := S + #27 + '[46m';
      20: S := S + #27 + '[41m';
      21: S := S + #27 + '[45m';
      22: S := S + #27 + '[43m';
      23: S := S + #27 + '[47m';
    End;

    Ansi_Color := S;
  End;

Procedure SaveScreenANSI(Filename: String; Image: TConsoleImageRec;  GetPrep:Boolean);
  Var
    OutFile   : Text;
    FG,BG     : Byte;
    oFG,oBG  : Byte;
    OldAT     : Byte;
    Outname   : String;
    Count1    : Integer;
    Count2    : Integer; 
    Prep      : Byte;
    LastLine  : Byte;
    LineLen   : Byte;
  Begin
    If GetPrep Then 
      Prep := GetANSIPrep;
    Outname := Filename; //GetSaveFileName(' Save Screen ','blockart.ans');
    if Outname <> '' then Begin
      Assign     (OutFile, Outname);
      //SetTextBuf (OutFile, Buffer);
      ReWrite    (OutFile);
      OldAt:=0;
      oFG:=0;
      oBG:=0;
      If SaveCur Then LastLine := WhereY
        Else LastLine := FindLastLine(Image);
      If Prep = 2 Then  System.Write(Outfile, ANSIClrScr);
      For Count1 := 1 to LastLine Do Begin
        LineLen := GetLineLength(Image,Count1);
        For Count2 := Image.X1 to 80 Do Begin
          If OldAt <> Image.Data[Count1][Count2].Attributes then Begin
            FG := Image.Data[Count1][Count2].Attributes mod 16;
            BG := 16 + (Image.Data[Count1][Count2].Attributes div 16);
            //Write(Outfile,'|'+StrPadL(Int2Str(FG),2,'0'));
            //Write(Outfile,'|'+StrPadL(Int2Str(BG),2,'0'));
            if oFG<>FG then System.Write(Outfile,Ansi_Color(FG,GetTextAttr));
            if oBG<>BG then System.Write(Outfile,Ansi_Color(BG,GetTextAttr));
            //Write(Outfile,Ansi_Color(Image.Data[Count1][Count2].Attributes));
            oFG:=FG;
            oBG:=BG;
          End;
          System.Write(Outfile,Image.Data[Count1][Count2].UnicodeChar);
          OldAt := Image.Data[Count1][Count2].Attributes 
        End;
        If Count1 <> Lastline Then System.Write(Outfile,EOL);
      End;
      If Prep = 3 Then  System.Write(Outfile, ANSIHome);
      //If Settings.Sauce Then System.BlockWrite(Outfile,
      close(Outfile);
    End;
  
  End;
  
Procedure SaveScreenBLOCKART(Filename: String; Image: TConsoleImageRec; Rec:TLayerRec);
Var
  OutFile: file;
  Outname: String;
Begin
  Outname := Filename; 
  
  if Outname = '' then Exit;
  Assign     (OutFile, Outname);
  ReWrite    (OutFile,1);
  
  //write header;
  BlockWrite(outfile,rec,sizeof(rec));
  Blockwrite(outfile,image, sizeof(image));
    
  close(Outfile);
End;
  
Procedure SaveScreenMYSTIC(Filename: String; Image: TConsoleImageRec);
  Var
    OutFile: Text;
    FG,BG  : Byte;
  oFG,oBG  : Byte;
    OldAT  : Byte;
    Outname: String;
    Count1 : Integer;
    Count2 : Integer; 
    Prep   : Byte;
    LastLine : Byte;
    LineLen  : Byte;
  Begin
    Outname := Filename; //GetSaveFileName(' Save Screen ','blockart.ans');
    Prep := GetMysticPrep;
    if Outname <> '' then Begin
      Assign     (OutFile, Outname);
      //SetTextBuf (OutFile, Buffer);
      ReWrite    (OutFile);
      OldAt:=0;
      oFG:=0;
      oBG:=0;
      If (Prep = 1) Or (Prep = 3) Then  System.Write(Outfile, MysticCLrScr);
      If (Prep = 2) Or (Prep = 3) Then  System.Write(Outfile, MysticNoPause);
      If SaveCur Then LastLine := WhereY
        Else LastLine := FindLastLine(Image);
      For Count1 := 1 to LastLine Do Begin
        LineLen := GetLineLength(Image,Count1);
        For Count2 := Image.X1 to 80 Do Begin
          If OldAt <> Image.Data[Count1][Count2].Attributes then Begin
            FG := Image.Data[Count1][Count2].Attributes mod 16;
            BG := 16 + (Image.Data[Count1][Count2].Attributes div 16);
            if oFG<>FG then System.Write(Outfile,'|'+StrPadL(Int2Str(FG),2,'0'));
            if oBG<>BG then System.Write(Outfile,'|'+StrPadL(Int2Str(BG),2,'0'));
            oFG:=FG;
            oBG:=BG;
          End;
          System.Write(Outfile,Image.Data[Count1][Count2].UnicodeChar);
          OldAt := Image.Data[Count1][Count2].Attributes 
        End;
      If Count1 <> Lastline Then System.Write(Outfile,EOL);
      End;
      If Prep = 4 Then  System.Write(Outfile, MysticHome);
      close(Outfile);
    End;
  
  End;  
  
Procedure SaveScreenPascal(Filename: String; Image: TConsoleImageRec);  
  Var
    OutFile: Text;
    FG,BG  : Byte;
    Cnt  : Byte;
    Outname: String;
    Count1 : Integer;
    Count2 : Integer; 
    S      : String;
    C      : Char;
Begin
  Outname := Filename; //GetSaveFileName(' Save Screen ','blockart.ans');
  if Outname <> '' then Begin
    Assign     (OutFile, Outname);
    ReWrite    (OutFile);
{    const
  IMAGEDATA_WIDTH=80;
  IMAGEDATA_DEPTH=25;
  IMAGEDATA_LENGTH=689;
  IMAGEDATA : array [1..689] of Char = (
 }   
    System.Writeln(OutFile,'{ TheDraw Pascal Screen Image. }');
    System.Writeln(OutFile,'IMAGEDATA_WIDTH=80;');
    System.Writeln(OutFile,'IMAGEDATA_DEPTH=25;');
    System.Writeln(OutFile,'IMAGEDATA_LENGTH=4000;');
    System.Writeln(OutFile,'IMAGEDATA : array [1..4000] of Char = (');
    Cnt := 1;
    S   := '';
    For Count1 := 1 to 25 Do Begin
      For Count2 := 1 to 80 Do Begin
        C := Image.Data[Count1][Count2].UnicodeChar;
        If C = #0 Then C := ' ';
        If (Count1 * Count2)<>2000 Then Begin
          S := S + '''' + C + ''' ,#' + strPadR(Int2Str(Image.Data[Count1][Count2].Attributes),3,' ') + ',';
           Cnt := Cnt + 1;
          If Cnt = 7 Then Begin
            System.Writeln(OutFile,S);
            Cnt := 1;
            S := '';
          End;
        End
        Else Begin
          S := S + '''' + C + ''' ,#' + strPadR(Int2Str(Image.Data[Count1][Count2].Attributes),3,' ')+');';
          System.Writeln(OutFile,S);
        End;
       
      End;
    End;
    close(Outfile);
  End;
End;  
  
Procedure SaveScreenTEXT(Filename: String; Image: TConsoleImageRec);
  Var
    OutFile: Text;
    Outname: String;
    Count1 : Integer;
    Count2 : Integer; 
    LastLine : Byte;
  Begin
    Outname := Filename; //GetSaveFileName(' Save Screen ','blockart.ans');
    if Outname <> '' then Begin
      Assign     (OutFile, Outname);
      ReWrite    (OutFile);
      If SaveCur Then LastLine := WhereY
        Else LastLine := FindLastLine(Image);
      For Count1 := 1 to LastLine Do Begin
        For Count2 := 1 to 79 Do Begin
            System.Write(Outfile,Image.Data[Count1][Count2].UnicodeChar);
        End;
        If Count1 <> Lastline Then System.Write(Outfile,EOL);
      End;
      close(Outfile);
    End;
  End;    
  
Function LoadAnsiImage (FName: String; Var Image:TConsoleImageRec):Boolean;
Var
  Buf      : Array[1..4096] of Char;
  BufLen   : LongInt;
  TotL     : Byte;
  Ansi     : TMsgBaseAnsi;
  AFile    : File;
  FN       : String;
  x,y      : Byte;
Begin
  Result:=False;
  FN       := FName;

  Screen.TextAttr:=7;
  
  If Not FileExist(FN) Then Exit;
  
  Ansi := TMsgBaseAnsi.Create(nil, False);
  ansi.clear;

  Assign  (AFile, FN);
  ioReset (AFile, 1, fmReadWrite + fmDenyNone);

  While Not Eof(AFile) Do Begin
    ioBlockRead (AFile, Buf, SizeOf(Buf), BufLen);
    If Ansi.ProcessBuf (Buf, BufLen) Then Break;
  End;

  Close (AFile);
  
  If Ansi.Lines<26 then totl:=ansi.lines else totl:=25;
  ClearImage(image);
    for y:=1 to totl do 
      for x:=1 to 80 do begin
        Image.data[y][x].attributes:=ansi.data[y][x].attr;
        Image.data[y][x].UnicodeChar:=ansi.data[y][x].Ch;
      end;

  Ansi.Free;
  Result:=True;
End;

Function LoadBlockartImage(Filename: String; Var Image: TConsoleImageRec; Var Rec:TLayerRec):boolean;
Var
  f: file;
Begin
  Result:=False;
  
  if not fileexist(filename) then exit;
  
  Assign     (f, Filename);
  Reset    (f,1);
  
  BlockRead(f,rec,sizeof(rec));
  BlockRead(f,image, sizeof(image));
    
  close(f);
  Result:=True;
End;

Begin
End.  
