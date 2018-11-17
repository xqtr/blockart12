Unit tdfstudio;
{$MODE objfpc}

Interface

Uses 
  xtdf,
  xcrt,
  xstrings,
  xfileio,
  dos,
  classes,
  xansi,
  xquicksort,
  xmenubox,
  inifiles,
  xmenuinput;

Var
  FontFolder  : String;
  

Function FontGallery(Var Fnt:String; Var FF:Byte):Boolean;


Implementation

Const
  Version = '1.1';
  
Type
  TCoord = Record
    x,
    y,
    a   : Byte;
  End;


Var
 Ch,t     : Char;
 d        : SmallInt;
 txt      : String;
 tmp      : String = '';
 tmp1     : String = '';
 Files    : TStringList;
 NC       : Byte = 8;
 HC       : Byte = 7*16;
 TC       : SmallInt = 15;
 FMS      : Integer = 0;
 SB       : TScreenBuf;
 SelFont  : String;
 x        : Byte = 1;
 y        : Byte = 3;
 Pal      : Array[1..16] Of Boolean;
 Coord    : TCoord;
 currentdir:string;
 tb       : byte;
 noclear  : boolean;
 
 ini      : tinifile;
 Done     : Boolean = False;

procedure clear;
var i:byte;
begin
  textcolor(7);
  clrscr;
  for i:=1 to 25 do writexy(1,i,7,strrep(#176,79));
end;

Function ShowMsgBox (BoxType: Byte; title, Str: String) : Boolean;
Var
  Len    : Byte;
  Len2   : Byte;
  Pos    : Byte;
  MsgBox : TMenuBox;
  Offset : Byte;
  SavedX : Byte;
  SavedY : Byte;
  SavedA : Byte;
Begin
  ShowMsgBox := True;
  SavedX     := WhereX;
  SavedY     := WhereY;
  SavedA     := GetTextAttr;

  MsgBox := TMenuBox.Create;

  Len := (80 - (Length(Str) + 2)) DIV 2;
  Pos := 1;
  MsgBox.Header     := title;
  With MsgBox Do Begin
    FrameType  := 1;
    BoxAttr    := 8;
    Box3D      := True;
    BoxAttr2   := 8;
    BoxAttr3   := 7;
    BoxAttr4   := 15;
    Shadow     := True;
    ShadowAttr := 8;
    HeadAttr   := 11;
    HeadType   := 1;
  End;
  offset:=0;

  If BoxType < 2 Then
    MsgBox.Open (Len, 10 + Offset, Len + Length(Str) + 3, 15 + Offset)
  Else
    MsgBox.Open (Len, 10 + Offset, Len + Length(Str) + 3, 14 + Offset);

  WriteXY (Len + 2, 12 + Offset, 7, Str);

  Case BoxType of
    0 : Begin
          Len2 := (Length(Str) - 4) DIV 2;

          WriteXY (Len + Len2 + 2, 14 + Offset, 7*16, ' OK ');

          Repeat
            Keyboard.ReadKey;
          Until Not Keyboard.KeyPressed;
        End;
    1 : Repeat
          Len2 := (Length(Str) - 9) DIV 2;

          WriteXY (Len + Len2 + 2, 14 + Offset, 8, ' YES ');
          WriteXY (Len + Len2 + 7, 14 + Offset, 8, ' NO ');

          If Pos = 1 Then
            WriteXY (Len + Len2 + 2, 14 + Offset, 15+7*16, ' YES ')
          Else
            WriteXY (Len + Len2 + 7, 14 + Offset, 7*16, ' NO ');

          Case UpCase(Keyboard.ReadKey) of
            #00 : Case Keyboard.ReadKey of
                    #75 : Pos := 1;
                    #77 : Pos := 0;
                  End;
            #13 : Begin
                    ShowMsgBox := Boolean(Pos);
                    Break;
                  End;
            #32 : If Pos = 0 Then Inc(Pos) Else Pos := 0;
            'N' : Begin
                    ShowMsgBox := False;
                    Break;
                  End;
            'Y' : Begin
                    ShowMsgBox := True;
                    Break;
                  End;
          End;
        Until False;
  End;

  If BoxType <> 2 Then MsgBox.Close;

  MsgBox.Free;
  
  GotoXY (SavedX, SavedY);

  SetTextAttr(SavedA);
End;

Procedure CustomBox (X1, Y1, X2, Y2: Byte);
var box:tmenubox;
Begin
  Box := TMenuBox.Create;
  With Box Do Begin
    FrameType  := 1;
    BoxAttr    := 8;
    Box3D      := True;
    BoxAttr2   := 8;
    BoxAttr3   := 7;
    BoxAttr4   := 15;
    Shadow     := True;
    ShadowAttr := 8;
    HeadAttr   := 11;
    HeadType   := 1;
  End;
  Box.Open(X1, Y1, X2, Y2);
  Box.Free;
End;

Function GetUploadFileName(Header,xFerPath,mask: String) : String;
Const
  ColorBox = 7;
  ColorBar = 7 * 16;
Var
  DirList  : TMenuList;
  FileList : TMenuList;
  
  Str      : String;
  Path     : String;
  //Mask     : String;
  OrigDIR  : String;

  Procedure UpdateInfo;
  Begin
    WriteXY (8,  7, 15 + 7 * 16, strPadR(Path, 65, ' '));
    WriteXY (8, 21, 15 + 7 * 16, strPadR(Mask, 65, ' '));
  End;

  Procedure CreateLists;
  Var
    Dir      : SearchRec;
    DirSort  : TQuickSort;
    FileSort : TQuickSort;
    Count    : LongInt;
  Begin
    DirList.Clear;
    FileList.Clear;

    While Path[Length(Path)] = PathSep Do Dec(Path[0]);

    ChDir(Path);

    Path := Path + PathSep;

    If IoResult <> 0 Then Exit;

    DirList.Picked  := 1;
    FileList.Picked := 1;

    UpdateInfo;

    DirSort  := TQuickSort.Create;
    FileSort := TQuickSort.Create;

    FindFirst (Path + '*', AnyFile - VolumeID, Dir);

    While DosError = 0 Do Begin
      If (Dir.Attr And Directory = 0) or ((Dir.Attr And Directory <> 0) And (Dir.Name = '.')) Then Begin
        FindNext(Dir);
        Continue;
      End;

      DirSort.Add (Dir.Name, 0);
      FindNext    (Dir);
    End;

    FindClose(Dir);

    FindFirst (Path + Mask, AnyFile - VolumeID, Dir);

    While DosError = 0 Do Begin
      If Dir.Attr And Directory <> 0 Then Begin
        FindNext(Dir);

        Continue;
      End;

      FileSort.Add(Dir.Name, 0);
      FindNext(Dir);
    End;

    FindClose(Dir);

    DirSort.Sort  (1, DirSort.Total,  qAscending);
    FileSort.Sort (1, FileSort.Total, qAscending);

    For Count := 1 to DirSort.Total Do
      DirList.Add(DirSort.Data[Count]^.Name, 0);

    For Count := 1 to FileSort.Total Do
      FileList.Add(FileSort.Data[Count]^.Name, 0);

    DirSort.Free;
    FileSort.Free;

    WriteXY (14, 9, 8, strPadR('(' + strComma(FileList.ListMax) + ')', 7, ' '));
    WriteXY (53, 9, 8, strPadR('(' + strComma(DirList.ListMax) + ')', 7, ' '));
  End;

Var
  Box  : TMenuBox;
  Done : Boolean;
  Mode : Byte;
Begin
  Result   := '';
  Path     := XferPath;
  //Mask     := '*.*';
  Box      := TMenuBox.Create;
  DirList  := TMenuList.Create;
  FileList := TMenuList.Create;

  GetDIR (0, OrigDIR);

  FileList.NoWindow   := True;
  FileList.LoChars    := #9#13#27;
  FileList.HiChars    := #77;
  FileList.HiAttr     := ColorBar;
  FileList.LoAttr     := ColorBox;

  DirList.NoWindow    := True;
  DirList.NoInput     := True;
  DirList.HiAttr      := ColorBox;
  DirList.LoAttr      := ColorBox;

  //Box.Header := ' Upload file ';
  Box.Header := Header;
  With Box Do Begin
    FrameType  := 1;
    BoxAttr    := 8;
    Box3D      := True;
    BoxAttr2   := 8;
    BoxAttr3   := 7;
    BoxAttr4   := 15;
    Shadow     := True;
    ShadowAttr := 8;
    HeadAttr   := 11;
    HeadType   := 1;
  End;
  Box.Open (6, 5, 74, 22);

  WriteXY ( 8,  6, 15, 'Directory');
  WriteXY ( 8,  9, 15, 'Files');
  WriteXY (41,  9, 15, 'Directories');
  WriteXY ( 8, 20, 15, 'File Mask');
  WriteXY ( 8, 21,  15+7*16, strRep(' ', 65));

  CreateLists;

  DirList.Open (40, 9, 72, 19);
  DirList.Update;

  Done := False;

  Repeat
    FileList.Open (7, 9, 39, 19);

    Case FileList.ExitCode of
      #09,
      #77 : Begin
              FileList.HiAttr := ColorBox;
              DirList.NoInput := False;
              DirList.LoChars := #09#13#27;
              DirList.HiChars := #75;
              DirList.HiAttr  := ColorBar;

              FileList.Update;

              Repeat
                DirList.Open(40, 9, 72, 19);

                Case DirList.ExitCode of
                  #09 : Begin
                          DirList.HiAttr := ColorBox;
                          DirList.Update;

                          Mode  := 1;
                          xMenuInput.LoChars := #09#13#27;
                          xMenuInput.FillAttr := 15+0*16;
                          xMenuInput.Attr := 15+7*16;
                          Repeat
                            Case Mode of
                              1 : Begin
                                    xMenuInput.Attr := 7*16;
                                    Str := GetStr(8, 21, 65, 255, 1, Mask);

                                    Case xMenuInput.ExitCode of
                                      #09 : Mode := 2;
                                      #13 : Begin
                                              Mask := Str;
                                              CreateLists;
                                              FileList.Update;
                                              DirList.Update;
                                            End;
                                      #27 : Begin
                                              Done := True;
                                              Break;
                                            End;
                                    End;
                                  End;
                              2 : Begin
                                    UpdateInfo;
                                    xMenuInput.Attr := 7*16;
                                    Str := GetStr(8, 7, 65, 255, 1, Path);

                                    Case xMenuInput.ExitCode of
                                      #09 : Break;
                                      #13 : Begin
                                              ChDir(Str);

                                              If IoResult = 0 Then Begin
                                                Path := Str;
                                                CreateLists;
                                                FileList.Update;
                                                DirList.Update;
                                              End;
                                            End;
                                      #27 : Begin
                                              Done := True;
                                              Break;
                                            End;
                                    End;
                                  End;
                            End;
                          Until False;

                          UpdateInfo;

                          Break;
                        End;
                  #13 : If DirList.ListMax > 0 Then Begin
                          ChDir  (DirList.List[DirList.Picked]^.Name);
                          GetDir (0, Path);

                          Path := Path + PathSep;

                          CreateLists;
                          FileList.Update;
                        End;
                  #27 : Done := True;
                  #75 : Break;
                End;
              Until Done;

              DirList.NoInput := True;
              DirList.HiAttr  := ColorBox;
              FileList.HiAttr := ColorBar;
              DirList.Update;
            End;
      #13 : If FileList.ListMax > 0 Then Begin
              Result := Path + FileList.List[FileList.Picked]^.Name;
              Break;
            End;
      #27 : Break;
    End;
  Until Done;

  ChDIR(OrigDIR);

  FileList.Free;
  DirList.Free;
  Box.Close;
  Box.Free;
End;
 
Function GetSaveFileName(Header,def,xferpath,mask: String): String;
Const
  ColorBox = 7;
  ColorBar = 7*16;
Var
  DirList  : TMenuList;
  FileList : TMenuList;
  Str      : String;
  Path     : String;
  //Mask     : String;
  OrigDIR  : String;
  SaveFile : String;

  Procedure UpdateInfo;
  Begin
    WriteXY (8,  7, 7 * 16, strPadR(Path, 65, ' '));
    WriteXY (8, 21, 7 * 16, strPadR(SaveFile, 65, ' '));
  End;

  Procedure CreateLists;
  Var
    Dir      : SearchRec;
    DirSort  : TQuickSort;
    FileSort : TQuickSort;
    Count    : LongInt;
  Begin
    DirList.Clear;
    FileList.Clear;

    While Path[Length(Path)] = PathSep Do Dec(Path[0]);

    ChDir(Path);

    Path := Path + PathSep;

    If IoResult <> 0 Then Exit;

    DirList.Picked  := 1;
    FileList.Picked := 1;

    UpdateInfo;

    DirSort  := TQuickSort.Create;
    FileSort := TQuickSort.Create;

    FindFirst (Path + '*', AnyFile - VolumeID, Dir);

    While DosError = 0 Do Begin
      If (Dir.Attr And Directory = 0) or ((Dir.Attr And Directory <> 0) And (Dir.Name = '.')) Then Begin
        FindNext(Dir);
        Continue;
      End;

      DirSort.Add (Dir.Name, 0);
      FindNext    (Dir);
    End;

    FindClose(Dir);

    FindFirst (Path + Mask, AnyFile - VolumeID, Dir);

    While DosError = 0 Do Begin
      If Dir.Attr And Directory <> 0 Then Begin
        FindNext(Dir);

        Continue;
      End;

      FileSort.Add(Dir.Name, 0);
      FindNext(Dir);
    End;

    FindClose(Dir);

    DirSort.Sort  (1, DirSort.Total,  qAscending);
    FileSort.Sort (1, FileSort.Total, qAscending);

    For Count := 1 to DirSort.Total Do
      DirList.Add(DirSort.Data[Count]^.Name, 0);

    For Count := 1 to FileSort.Total Do
      FileList.Add(FileSort.Data[Count]^.Name, 0);

    DirSort.Free;
    FileSort.Free;

    WriteXY (14, 9, 8, strPadR('(' + strComma(FileList.ListMax) + ')', 7, ' '));
    WriteXY (53, 9, 8, strPadR('(' + strComma(DirList.ListMax) + ')', 7, ' '));
  End;

Var
  Box  : TMenuBox;
  Done : Boolean;
  Mode : Byte;
Begin
  Result   := '';
  Path     := XferPath;
  //Mask     := '*.*';
  SaveFile := def;
  Box      := TMenuBox.Create;
  DirList  := TMenuList.Create;
  FileList := TMenuList.Create;
  
  With Box Do Begin
    FrameType  := 1;
    BoxAttr    := 8;
    Box3D      := True;
    BoxAttr2   := 8;
    BoxAttr3   := 7;
    BoxAttr4   := 15;
    Shadow     := True;
    ShadowAttr := 8;
    HeadAttr   := 11;
    HeadType   := 1;
  End;

  GetDIR (0, OrigDIR);

  FileList.NoWindow   := True;
  FileList.LoChars    := #9#13#27;
  FileList.HiChars    := #77;
  FileList.HiAttr     := ColorBar;
  FileList.LoAttr     := ColorBox;

  DirList.NoWindow    := True;
  DirList.NoInput     := True;
  DirList.HiAttr      := ColorBox;
  DirList.LoAttr      := ColorBox;

  //Box.Header := ' Save File ';
  Box.Header := Header;
  //Box.HeadAttr := 15 + 7 * 16;
  Box.Open (6, 5, 74, 22);

  WriteXY ( 8,  6, 15, 'Directory');
  WriteXY ( 8,  9, 15, 'Files');
  WriteXY (41,  9, 15, 'Directories');
  WriteXY ( 8, 20, 15, 'File Name');
  WriteXY ( 8, 21, 15+7*16, strRep(' ', 65));

  CreateLists;

  DirList.Open (40, 9, 72, 19);
  DirList.Update;

  Done := False;

  Repeat
    FileList.Open (7, 9, 39, 19);

    Case FileList.ExitCode of
      #09,
      #77 : Begin
              FileList.HiAttr := ColorBox;
              DirList.NoInput := False;
              DirList.LoChars := #09#13#27;
              DirList.HiChars := #75;
              DirList.HiAttr  := ColorBar;

              FileList.Update;

              Repeat
                DirList.Open(40, 9, 72, 19);

                Case DirList.ExitCode of
                  #09 : Begin
                          DirList.HiAttr := ColorBox;
                          DirList.Update;

                          Mode  := 1;
                          xMenuInput.FillAttr := 15;
                          xMenuInput.Attr := 15+7*16;
                          xMenuInput.LoChars := #09#13#27;

                          Repeat
                            Case Mode of
                              1 : Begin
                                    Str := GetStr(8, 21, 65, 255, 1, SaveFile);

                                    Case xMenuInput.ExitCode of
                                      #09 : Mode := 2;
                                      #13 : Begin
                                              SaveFile := Str;
                                              if SaveFile <> '' then 
                                                if fileexist(Path + Savefile) then Begin
                                                  if ShowMsgBox(1, ' Error ','File Exists. Overwrite?') then Result := Path + Savefile
                                                  End else Result := Path + Savefile;
                                              if result = Path + Savefile then begin
                                                ChDIR(OrigDIR);
                                                FileList.Free;
                                                DirList.Free;
                                                Box.Close;
                                                Box.Free;
                                                exit;
                                              end;
                                              (*CreateLists;
                                              FileList.Update;
                                              DirList.Update;*)
                                            End;
                                      #27 : Begin
                                              Done := True;
                                              Break;
                                            End;
                                    End;
                                  End;
                              2 : Begin
                                    UpdateInfo;

                                    Str := GetStr(8, 7, 65, 255, 1, Path);

                                    Case xMenuInput.ExitCode of
                                      #09 : Break;
                                      #13 : Begin
                                              ChDir(Str);

                                              If IoResult = 0 Then Begin
                                                Path := Str;
                                                CreateLists;
                                                FileList.Update;
                                                DirList.Update;
                                              End;
                                            End;
                                      #27 : Begin
                                              Done := True;
                                              Break;
                                            End;
                                    End;
                                  End;
                            End;
                          Until False;

                          UpdateInfo;

                          Break;
                        End;
                  #13 : If DirList.ListMax > 0 Then Begin
                          ChDir  (DirList.List[DirList.Picked]^.Name);
                          GetDir (0, Path);

                          Path := Path + PathSep;

                          CreateLists;
                          FileList.Update;
                        End;
                  #27 : Done := True;
                  #75 : Break;
                End;
              Until Done;

              DirList.NoInput := True;
              DirList.HiAttr  := ColorBox;
              FileList.HiAttr := ColorBar;
              DirList.Update;
            End;
      #13 : If FileList.ListMax > 0 Then Begin
              //Result := Path + FileList.List[FileList.Picked]^.Name;
              if fileexist(Path + FileList.List[FileList.Picked]^.Name) then Begin
                if ShowMsgBox(1, ' Error ','File Exists. Overwrite?') then Result := Path + FileList.List[FileList.Picked]^.Name;
              End else Result := Path + FileList.List[FileList.Picked]^.Name;
              if Result = Path + FileList.List[FileList.Picked]^.Name then Break;
            End;
      #27 : Begin
              Result:='';
              Break;
            End;
    End;
  Until Done;

  ChDIR(OrigDIR);

  FileList.Free;
  DirList.Free;
  Box.Close;
  Box.Free;
End;

Function GetFontType : Byte;
Var
  List : TMenuList;
Begin
  List := TMenuList.Create;

  List.Box.Header    := ' Font Type ';
  
  With List.Box Do Begin
    FrameType  := 1;
    BoxAttr    := 8;
    Box3D      := True;
    BoxAttr2   := 8;
    BoxAttr3   := 7;
    BoxAttr4   := 15;
    Shadow     := True;
    ShadowAttr := 8;
    HeadAttr   := 11;
    HeadType   := 1;
  End;

  List.PosBar        := False;
  
  List.HiAttr := 7*16;
  List.LoAttr := 7;

  List.Add('Outline', 0);
  List.Add('Block', 0);
  List.Add('Color', 0);

  List.Open (30, 11, 49, 15);
  List.Box.Close;

  Case List.ExitCode of
    #27 : Result := 0;
  Else
    Result := List.Picked;
  End;

  List.Free;
End;

//under
 
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
 
Procedure SaveScreenANSI(Filename: String; Image: TScreenBuf);
  Var
    OutFile   : Text;
    FG,BG     : Byte;
    OldAT     : Byte;
    Outname   : String;
    Count1    : Integer;
    Count2    : Integer; 
    Prep      : Byte;
    LastLine  : Byte;
    LineLen   : Byte;
  Begin
    Outname := Filename; //GetSaveFileName(' Save Screen ','blockart.ans');
    if Outname <> '' then Begin
      Assign     (OutFile, Outname);
      //SetTextBuf (OutFile, Buffer);
      ReWrite    (OutFile);
      OldAt:=0;
      LastLine := 21;
      For Count1 := 2 to LastLine Do Begin
        //LineLen := GetLineLength(Image,Count1);
        For Count2 := 1 to 79 Do Begin
          If OldAt <> (Image.data[Count1][Count2].Attributes) then Begin
            FG := Image.data[Count1][Count2].Attributes mod 16;
            BG := 16 + (Image.data[Count1][Count2].Attributes div 16);
            system.Write(Outfile,Ansi_Color(FG,getTextAttr));
            system.Write(Outfile,Ansi_Color(BG,getTextAttr));
          End;
          system.Write(Outfile,Image.data[Count1][Count2].UnicodeChar);
          OldAt := Image.data[Count1][Count2].Attributes 
        End;
        If Count1 <> Lastline Then system.Write(Outfile,EOL);
      End;
      close(Outfile);
    End;
  
  End;

Procedure InAppHelpScreen;
Var
  x : Byte = 3;
Begin
  setTextAttr(7);
  ClrScr;
  
  setTextAttr(7*16);
  GotoXY(1,1);ClearEOL;
  WriteXY(2,1,7*16,'TDFStudio v'+Version);
  GotoXY(1,25);ClearEOL;
  
  WriteXYPipe(x,4,7,'|15ESC |08: |07Quit');
  WriteXYPipe(x,5,7,'|15E   |08: |07Extract Font');
  WriteXYPipe(x,6,7,'|15M   |08: |07Merge Font');
  WriteXYPipe(x,7,7,'|15L   |08: |07Load Font File');
  WriteXYPipe(x,8,7,'|15S   |08: |07Save ANSI Image');
  WriteXYPipe(x,9,7,'|15N   |08: |07Change Name');
  WriteXYPipe(x,10,7,'|15I   |08: |07Change Spacing');
  WriteXYPipe(x,11,7,'|15T   |08: |07Change Displayed Text');
  WriteXYPipe(x,12,7,'|15F   |08: |07Change Type of Font');
  WriteXYPipe(x,13,7,'|15X   |08: |07Change X Position of Text');
  WriteXYPipe(x,14,7,'|15Y   |08: |07Change Y Position of Text');
  //WriteXYPipe(x,15,7,'|15C   |08: |07Color Substitude');
  WriteXYPipe(x,15,7,'|15P   |08: |07Color Palette');
  WriteXYPipe(x,16,7,'|15R   |08: |07Recolor Font');
  WriteXYPipe(x,17,7,'|15C   |08: |07Substitude Color in X,Y Position');
  ReadKey;
End;

Procedure ResetPalette;
Var i:Byte;
Begin
  For i := 1 to 16 Do Pal[i]:=False;
End;

Procedure SubColor(F,S:Byte);
Var
  xi,yi : Byte;
  img:tconsoleimagerec;
Begin
  savescreen(img);
  For yi:=2 to 21 Do 
    For xi:=1 to 80 do
      If img.data[yi][xi].Attributes=F Then img.data[yi][xi].Attributes:=s;
  restorescreen(img);
End;

Procedure ReColor(S:Byte);
Var
  xi,yi : Byte;
  img:tconsoleimagerec;
Begin
savescreen(img);
  For yi:=2 to 21 Do 
    For xi:=1 to 80 do
       img.data[yi][xi].Attributes:=s;
restorescreen(img);
End;

Function FindPalette:String;
Var 
  xi,yi : Byte;
Begin
  Result:='';
  For yi:=2 to 21 Do 
    For xi:=1 to 80 do
      Pal[FgColor(GetAttrAt(xi,yi))]:=True;
      
  For xi:=1 to 16 Do
    If Pal[xi] Then Result:=Result+' |'+StrPadL(Int2Str(xi),2,'0')+'лл|15|16'+Int2Str(xi);
End;


Function FontGallery(Var Fnt:String; Var FF:Byte):Boolean;
Begin
  Fnt:='';
  FF:=0;
  Result:=False;
  done:=false;
  tmp:='';
  
    
  
    //tmp:=SelectFile;
    getdir(0,currentdir);
    tmp:=GetUploadFileName(' Load Font ',FontFolder,'*.tdf');
    if tmp<>'' Then Begin
      xtdf.init(tmp);
      SelFont:=tmp;
      d:=xTDF.Selected;
    End Else Begin
      setTextAttr(7);
      ClrScr;
      Exit;
    End;
  
  xtdf.init(SelFont);
  d:=xTDF.Selected;
  txt:='adf1';
  //currentdir:=GetCurrentDir;
  getdir(0,currentdir);
  noclear:=false;
  Repeat
    xTDF.SelectFont(d);
    setTextAttr(7);
    if noclear=false then clrscr;
    GotoXY(1,1);setTextAttr(HC);
    Write(StrPadR(JustFile(xTDF.FontFile),25,' ')+
      StrPadR('Font: '+Int2Str(xTDF.Selected) +'/'+Int2Str(xTDF.Count),15,' ')+
      StrPadl('Spacing: '+Int2Str(FontHeader.Spacing),10,' ')+
      StrPadl('Name: '+Fonts[d-1].Name+' ['+xTDF.GetFontType+']',30,' '));
    If FontHeader.FontType=1 Then setTextAttr(TC) Else setTextAttr(15);
    if noclear=false then xtdf.writestr(x,y,txt);
    textcolor(15);
    tmp:=xTDF.AvailableChars;
    WriteXY(1,23,3,StrPadC('Chars.:'+Copy(tmp,1,44),80,' '));
    WriteXY(1,24,3,StrPadC(Copy(tmp,45,54),80,' '));
    WriteXYPipe(1,25,7,'|00|23'+Button('H')+'|07|16'+'Help');
    setTextAttr(NC);
    ClearEol;
    Ch:=Readkey;
    noclear:=false;
    Case lower(Ch) of
       #13: Begin
              Fnt:=SelFont;
              FF:=xTDF.Selected;
              Result:=True;
              Done:=True;
            End;
      'h' : Begin
              InAppHelpScreen;
            End;
      'r' : begin
              WriteXY(1,25,HC,StrRep(' ',80));
              WriteXY(1,25,HC,StrPadL('Attr = FG + BG * 16',80,' '));
              WriteXY(2,25,HC,'Recolor: ');
              //Coord.X:=Str2Int(Input('',CHARS_NUMERIC,#0,2,2,HC));
              Coord.A:=Str2Int(GetStr (11, 25, 3, 3, 0,15,8,#178,''));
              recolor(Coord.A);
              noclear:=true;
              
            end;
      'c' : Begin
              WriteXY(1,25,HC,StrRep(' ',80));
              WriteXY(1,25,HC,StrPadL('Attr = FG + BG * 16',80,' '));
              WriteXY(2,25,HC,'X: ');
              //Coord.X:=Str2Int(Input('',CHARS_NUMERIC,#0,2,2,HC));
              Coord.X:=Str2Int(GetStr (5, 25, 3, 3, 0,15,8,#178,''));
              WriteXY(8,25,HC,'Y: ');
              //Coord.Y:=Str2Int(Input('',CHARS_NUMERIC,#0,2,2,HC));
              Coord.Y:=Str2Int(GetStr(11,25,3,3,0,15,8,#178,''));
              WriteXY(16,25,HC,'Attr: ');
              //Coord.A:=Str2Int(Input('',CHARS_NUMERIC,#0,3,3,HC));
              Coord.A:=Str2Int(GetStr(22,25,3,3,0,15,8,#178,''));
              SubColor(GetAttrAt(Coord.X,Coord.Y),Coord.A);
              noclear:=true;
              
            End;
      'p' : Begin
              ResetPalette;
              SaveScreen(SB);
              custombox(2,21,78,23);
              WriteXYPipe(4,22,7,'Used Colors: '+FindPalette);
              ReadKey;
              RestoreScreen(SB);
            End;
      #0  : Begin
              Ch:=Readkey;
              Case Ch Of
                keyCursorUp : begin
                                d:=d+1;
                               
                              end;
                keyCursorDown: begin
                                d:=d-1;
                               
                              end;
              End;
            End;
      'l' : Begin
              //tmp:=SelectFile;
              tmp:='';
              tmp:=GetUploadFileName(' Load Font ',FontFolder,'*.tdf');
              If tmp<>'' Then Begin
                xtdf.init(tmp);
                SelFont:=tmp;
                d:=xTDF.Selected;
                xTDF.SelectFont(d);
              End;
            End;
      '+' : If FontHeader.FontType=1 Then tc:=tc+1;
      '-' : If FontHeader.FontType=1 Then tc:=tc-1;
      't' : Begin
              WriteXY(1,25,HC,StrRep(' ',80));
              WriteXY(1,25,HC,'Text: ');
              //txt:=Input(txt,CHARS_FILENAME,#0,69,255,HC);
              txt:=GetStr(7,25,69,254,1,15,8,#178,txt);
              If txt='' Then txt:='adf1';
            End;
      'n' : Begin
              WriteXY(1,25,HC,StrRep(' ',80));
              WriteXY(1,25,HC,'Font Name:                               Up to 12 chars.');
              tmp:=FontHeader.FontName;
              //tmp:=Input(tmp,CHARS_FILENAME,#0,12,12,HC);
              tmp:=GetStr(12,25,12,12,1,15,8,#178,tmp);
              If tmp<>'' Then begin
                ChangeFontName(tmp);
                d:=Selected;
                Init(SelFont);
                SelectFont(d);
              End;
            End;
      'f' : Begin
              tb:=GetFontType;
              If tb<>0 Then Begin
                ChangeType(tb-1);
                d:=Selected;
                Init(SelFont);
                SelectFont(d);
              End;
            End;
      'i' : Begin
              WriteXY(1,25,HC,StrRep(' ',80));
              WriteXY(1,25,HC,'New Spacing: ');
              tmp:=Int2Str(FontHeader.Spacing);
              //tmp:=Input(tmp,CHARS_NUMERIC,#0,3,3,HC);
              tmp:=GetStr(14,25,3,3,0,15,8,#178,'');
              If tmp='' Then Break;
              ChangeSpacing(Str2Int(tmp));
              d:=Selected;
              Init(SelFont);
              SelectFont(d);
            End;
      'y' : Begin
              WriteXY(1,25,HC,StrRep(' ',80));
              WriteXY(1,25,HC,'Y: ');
              tmp:=Int2Str(Y);
              //tmp:=Input(tmp,CHARS_NUMERIC,#0,3,3,HC);
              tmp:=GetStr(4,25,3,3,0,15,8,#178,'');
              If tmp='' Then Break;
              y:=Str2Int(tmp);
            End;
      'x' : Begin
              WriteXY(1,25,HC,StrRep(' ',80));
              WriteXY(1,25,HC,'X: ');
              tmp:=Int2Str(X);
              //tmp:=Input(tmp,CHARS_NUMERIC,#0,3,3,HC);
              tmp:=GetStr(4,25,3,3,0,15,8,#178,'');
              If tmp='' Then Break;
              X:=Str2Int(tmp);
            End;
      'e' : Begin
              tmp:='';
              tmp:=GetSaveFileName(' Save Font As... ',xTDF.Fonts[d-1].Name+'.tdf',currentdir,'*.tdf');
              If tmp<>'' Then ExtractFont(tmp);
            End;
      'm' : Begin
              WriteXY(1,25,NC,StrRep(' ',80));
              //tmp:=SelectFile;
              tmp:='';
              tmp:=GetUploadFileName(' Select Font ',FontFolder,'*.tdf');
              If tmp<>'' THen 
                If ShowMsgBox(1,' Caution ','Are you sure') Then Begin
                  xTDF.MergeFont(tmp);
                  xtdf.init(SelFont);
                  d:=xTDF.Selected;
                  xTDF.SelectFont(d);
                End;
            End;
      's' : Begin
              tmp:='';
              tmp:=GetSaveFileName( ' Save Screen ',xTDF.Fonts[d-1].Name+'.ans',currentdir,'*.ans');
              If tmp<>'' Then Begin
                SaveScreen(SB);
                SaveScreenANSI(tmp,SB);
              End;
            End;
      #27 : Done:=True;
    End;
    If d>xTDF.Count Then d:=1;
    if d<1 Then d:=xTDF.Count;
    If tc>15 Then tc:=1;
    if tc<1 Then tc:=15;
    
  Until Done; //Ch=#27;
  setTextAttr(7);
  ClrScr;
  
End;

End.
