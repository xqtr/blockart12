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
{$MODE objfpc}
{$H-}
Unit blockart_dialogs;

Interface

Uses
  Math,
  DOS,
  xStrings,
  xCrt,
  xMenuBox,
  xMenuForm,
  IniFiles,
  xquicksort,
  xfileio,
  xDateTime,
  xMenuInput;
  
Type
  TCharSet = Array[1..10] Of String[10];  
  
Function GetSaveType : Byte;
Function GetLoadType : Byte;
Function GetCharSetType(ch:byte=0) : Byte;
Function GetColor(Color:Byte) : Byte;
Function GetChar(ch:byte=32) : Byte;
Function GetTDFChar(ch:byte=33) : Byte;
Function GetDrawMode(df:byte=1): Byte;
Function ShowMsgBox (BoxType: Byte; Str: String) : Boolean;
Function DrawMode2Str(B:Byte):String;
Function GetSaveFileName(Header,def,xferpath,mask: String): String;
Function GetFontType : Byte;
Procedure EditFontFx;
Procedure EditCaseFx;
Function GetUploadFileName(Header,xFerPath,mask: String) : String;
Function GetMYSTICPrep : Byte;
Function GetANSIPrep : Byte;
Function MysticCodes:String;
Function StrBox(title,prompt:string; sizeb,sizes:byte;default:string):string;
Procedure EditLayerRec(Var Rec:TLayerRec);

Implementation

Uses xtdf;

Function DrawMode2Str(B:Byte):String;
Begin
  Case B Of
    1: DrawMode2Str := 'Normal Mode';
    2: DrawMode2Str := 'Color Mode';
    3: DrawMode2Str := 'Line Mode';
    5: DrawMode2Str := 'Elite Write Mode';
    6: DrawMode2Str := 'TheDraw Font Mode';
   11: DrawMode2Str := 'Normal + FadeFx Mode';
   15: DrawMode2Str := 'Elite + FadeFx Mode';
   12: DrawMode2Str := 'Normal + CaseFx Mode';
   16: DrawMode2Str := 'Normal + CaseFx Mode';
  End;
End;

Procedure Center(S:String; L:byte);
Begin
  //WriteXYPipe((40-strMCILen(s) div 2),L,7,strMCILen(s),S);
  WriteXYPipe((40-strMCILen(s) div 2),L,7,S);
End;

Function StrBox(title,prompt:string; sizeb,sizes:byte;default:string):string;
Var 
  MsgBox : TMenuBox;
  Len    : Byte;
  SavedX : Byte;
  SavedY : Byte;
  SavedA : Byte;
Begin
  SavedX     := WhereX;
  SavedY     := WhereY;
  SavedA     := GetTextAttr;
  MsgBox := TMenuBox.Create;
  MsgBox.Header     := Title;
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
  Len := (80 - (sizeb + 2)) DIV 2;
  MsgBox.Open (Len, 10 , Len + sizeb + 3, 13 );
  writexy(len+2,11,7,prompt);
  result:=getstr(len+2,12,sizeb,sizes,1,7,15,#176,default);
  MsgBox.Free;
  GotoXY (SavedX, SavedY);
  SetTextAttr(SavedA);
End;

Function ShowMsgBox (BoxType: Byte; Str: String) : Boolean;
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
  MsgBox.Header     := ' Info ';
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
                                                  if ShowMsgBox(1, 'File Exists. Overwrite?') then Result := Path + Savefile
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
                if ShowMsgBox(1, 'File Exists. Overwrite?') then Result := Path + FileList.List[FileList.Picked]^.Name;
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

Function GetSaveType : Byte;
Var
  List : TMenuList;
Begin
  List := TMenuList.Create;

  List.Box.Header    := ' Save Format ';
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

  List.Add('ANSI', 0);
  List.Add('Mystic', 0);
  List.Add('Text Only', 0);

  List.Open (30, 11, 49, 15);
  List.Box.Close;

  Case List.ExitCode of
    #27 : Result := 0;
  Else
    Result := List.Picked;
  End;

  List.Free;
End;

Function GetLoadType : Byte;
Var
  List : TMenuList;
Begin
  List := TMenuList.Create;

  List.Box.Header    := ' Load Format ';
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

  List.Add('ANSI', 0);
  List.Add('Text Only', 0);
  List.Add('BlockArt', 0);

  List.Open (30, 11, 49, 15);
  List.Box.Close;

  Case List.ExitCode of
    #27 : Result := 0;
  Else
    Result := List.Picked;
  End;

  List.Free;
End;

Function GetANSIPrep : Byte;
Var
  List : TMenuList;
Begin
  List := TMenuList.Create;

  List.Box.Header    := ' Preparation ';
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
  
  List.Add('None', 0);
  List.Add('Clear Screen', 0);
  List.Add('Home', 0);
  

  List.Open (30, 11, 49, 15);
  List.Box.Close;

  Case List.ExitCode of
    #27 : Result := 0;
  Else
    Result := List.Picked;
  End;

  List.Free;
End;

Function GetMYSTICPrep : Byte;
Var
  List : TMenuList;
Begin
  List := TMenuList.Create;

  List.Box.Header    := ' Preparation ';
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

  List.Add('Clear Screen', 0);
  List.Add('No Pause', 0);
  List.Add('Clear & No Pause', 0);
  List.Add('Home', 0);
  List.Add('None', 0);

  List.Open (30, 11, 49, 17);
  List.Box.Close;

  Case List.ExitCode of
    #27 : Result := 0;
  Else
    Result := List.Picked;
  End;

  List.Free;
End;

Function GetDrawMode(df:byte=1): Byte;
Var
  List : TMenuList;
Begin
  List := TMenuList.Create;

  List.Box.Header    := ' Draw Mode ';
  
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

  List.Add('Normal', 0);
  List.Add('Color', 0);
  List.Add('Line', 0);
  List.Picked:=df;
  List.Open (30, 11, 49, 15);
  List.Box.Close;

  Case List.ExitCode of
    #27 : GetDrawMode := 255;
  Else
    GetDrawMode := List.Picked;
  End;

  List.Free;
End;

Function GetCharSetType(ch:byte=0) : Byte;
Var
  List  : TMenuList;
  X,Y   : Byte;
Begin
  X := WhereX;
  Y := WhereY;
  List := TMenuList.Create;

  List.Box.Header    := ' Charset ';
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
  
  List.Add(Chr(218)+Chr(191)+Chr(192)+Chr(217)+Chr(196)+Chr(179)+Chr(195)+Chr(180)+Chr(193)+Chr(194),0);
  List.Add(Chr(201)+Chr(187)+Chr(200)+Chr(188)+Chr(205)+Chr(186)+Chr(199)+Chr(185)+Chr(202)+Chr(203),0);
  List.Add(Chr(213)+Chr(184)+Chr(212)+Chr(190)+Chr(205)+Chr(179)+Chr(198)+Chr(189)+Chr(207)+Chr(209),0);
  List.Add(Chr(197)+Chr(206)+Chr(216)+Chr(215)+Chr(159)+Chr(233)+Chr(155)+Chr(156)+Chr(153)+Chr(239),0);
  List.Add(Chr(176)+Chr(177)+Chr(178)+Chr(219)+Chr(220)+Chr(223)+Chr(221)+Chr(222)+Chr(254)+Chr(249),0);
  List.Add(Chr(214)+Chr(183)+Chr(211)+Chr(189)+Chr(196)+Chr(186)+Chr(199)+Chr(182)+Chr(208)+Chr(210),0);
  List.Add(Chr(174)+Chr(175)+Chr(242)+Chr(243)+Chr(244)+Chr(245)+Chr(246)+Chr(247)+Chr(240)+Chr(251),0);
  List.Add(Chr(166)+Chr(167)+Chr(168)+Chr(169)+Chr(170)+Chr(171)+Chr(172)+Chr(248)+Chr(252)+Chr(253),0);
  List.Add(Chr(224)+Chr(225)+Chr(226)+Chr(235)+Chr(238)+Chr(237)+Chr(234)+Chr(228)+Chr(229)+Chr(230),0);
  List.Add(Chr(232)+Chr(233)+Chr(234)+Chr(155)+Chr(156)+Chr(157)+Chr(159)+Chr(145)+Chr(146)+Chr(247),0);
  List.Picked:=ch;
  List.Open (30, 8, 43, 19);
  List.Box.Close;

  Case List.ExitCode of
    #27 : GetCharSetType := 255;
  Else
    GetCharSetType := List.Picked;
  End;
  List.Free;
  GotoXY(X,Y);
End;

Function GetColor(Color:Byte) : Byte;
Var
  i     : Byte;
  CS    : TCharSet;
  MsgBox: TMenuBox;
  SelFG : Byte;
  SelBG : Byte;
  FB    : Byte;
  X,Y   : Byte;
  sb    : string = 'Background';
  
  Procedure DrawColors;
  Var
    d: byte;
  Begin
    For d := 1 to 9 Do WriteXY(9,6+d,0,StrRep(' ',65));
    For d := 0 to 15 Do WriteXY(10+d*4,8,d,Chr(219)+Chr(219));
    //For d := 0 to 7 Do WriteXY(27+d*4,12,0+d*16,'  ');
    For d := 0 to 7 Do WriteXY(10,8+d,0+d*16,'  ');
    writexy(9,6,8,'Foreground');
    for d:=1 to length(sb) do writexy(7,5+d,8,sb[d]);
  End;
  
  Procedure Select(FG:Byte; CL:Byte);
  var
    z,x:byte;
  Begin
      WriteXY(9+SelFG*4,8,15,#179);
      WriteXY(12+SelFG*4,8,15,#179);
      WriteXY(9,8+SelBG,15,#179);
      WriteXY(12,8+SelBG,15,#179);
      gotoxy(30,6);
      textcolor(15);write('FG: ');textcolor(7);write(strpadl(int2str(selfg),2,'0'));
      gotoxy(40,6);
      textcolor(15);write('BG: ');textcolor(7);write(strpadl(int2str(selBg),2,'0'));
      gotoxy(50,6);
      textcolor(15);write('AT: ');textcolor(7);write(strpadl(int2str(selfg+selBg*16),3,'0'));
      
      for x:=1 to 32 do writexy(12+x,9,selfg+selBg*16, chr(31+x));
      for x:=1 to 32 do writexy(12+x,10,selfg+selBg*16,chr(63+x));
      for x:=1 to 32 do writexy(12+x,11,selfg+selBg*16,chr(95+x));
      for x:=1 to 32 do writexy(12+x,12,selfg+selBg*16,chr(127+x));
      for x:=1 to 32 do writexy(12+x,13,selfg+selBg*16,chr(159+x));
      for x:=1 to 32 do writexy(12+x,14,selfg+selBg*16,chr(191+x));
      for x:=1 to 32 do writexy(12+x,15,selfg+selBg*16,chr(223+x));
      
      for x:=1 to 20 do writexy(46,9,selbg+selfg*16,strrep(chr(178),26));
      for x:=1 to 20 do writexy(46,10,selfg+selBg*16,strrep(chr(176),26));      
      for x:=1 to 20 do writexy(46,11,selfg+selBg*16,strrep(chr(177),26));
      for x:=1 to 20 do writexy(46,12,selbg+selfg*16,strrep(chr(177),26));
      for x:=1 to 20 do writexy(46,13,selfg+selBg*16,strrep(chr(178),26));
      for x:=1 to 20 do writexy(46,14,selbg+selfg*16,strrep(chr(176),26));
      for x:=1 to 20 do writexy(46,15,selfg+selBg*16,strrep(chr(219),26));
      
  End;
  
Begin
  X := WhereX;
  Y := WhereY;
  MsgBox := TMenuBox.Create;
  MsgBox.Header     := ' Colors ';
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
  
  MsgBox.Open (5, 5,76,17);
  DrawColors;
  FB := 1;
  SelFG:= Color mod 16;
  SelBG:= Color Div 16;
  if selbg>7 then selbg:=7;
  textcolor(8);
  Center('Left/Right: Foreground Color  Up/Down:Background Color',16);
  Repeat
    DrawColors;
    Select(FB,SelFG);
    Case ReadKey Of
      #13: Begin
            GetColor := SelFG + SelBG*16;
            Break;
          End;
      #27: Begin
            GetColor := Color;
            Break;
          End;
      #00: Case ReadKey Of
        KeyCursorUp   : Begin
                        
                          If SelBG>0 Then Dec(SelBG);
                        End;
        KeyCursorDown : Begin
                          If SelBG<7 Then Inc(SelBG);
                        End;
        KeyCursorLeft : Begin
                          If SelFG>0 Then Dec(SelFG);
                        End;
        KeyCursorRight: Begin
                          If SelFG<15 Then Inc(SelFG);
                        End;
      End;
    End;
  Until False;
  MsgBox.Close;
  MsgBox.Free;
  GotoXY(X,Y);

End;

Function GetChar(ch:byte=32) : Byte;
Var
  MsgBox: TMenuBox;
  Col,
  Row   : Byte;
  X,Y   : Byte;
 
  Procedure DrawChars;
  Var
    d,b: byte;
    
  Begin
    For d := 0 to 15 Do 
      For b := 0 To 15 Do WriteXY(32+b,6+d,7,chr(b+16*d));
  End;
  
  Procedure Select(Col,Row:Byte);
  Begin
    WriteXY(32+Col,6+Row,15+7*16,Chr(Col+16*Row));
    WriteXY(32,5,15,'Dec: '+ Int2Str(Col+16*Row)+ ' Hex: '+Byte2Hex(Col+16*Row));
  End;
  
Begin
  X := WhereX;
  Y := WhereY;
  MsgBox := TMenuBox.Create;
  MsgBox.Header     := ' Chars ';
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
  
  MsgBox.Open (30, 4,49,22);
  
  Col := ch mod 16;
  Row := (ch div 16);
  Repeat
    DrawChars;
    Select(Col,Row);
    Case Keyboard.ReadKey Of
      #13: Begin
            GetChar := Col+16*Row;
            Break;
          End;
      #27: Begin
            GetChar := 0;
            Break;
          End;
      #00: Case ReadKey Of
        KeyCursorUp   : If Row > 0 Then Dec(Row);
        KeyCursorDown : If Row < 15 Then Inc(Row);
        KeyCursorLeft : If Col > 0 Then Dec(Col);
        KeyCursorRight : If Col < 15 Then Inc(Col);
      End;
    End;
  Until False;
  MsgBox.Close;
  MsgBox.Free;
  GotoXY(X,Y);

End;

Function GetTDFChar(ch:byte=33) : Byte;
Var
  MsgBox: TMenuBox;
  Col,
  Row   : Byte;
  X,Y   : Byte;
 
  Procedure DrawChars;
  Var
    d,b: byte;
  Begin
    For d := 0 to 1 Do 
      For b := 0 To 46 Do WriteXY(16+b,10+d,7,chr(33+b+46*d));
  End;
  
  Procedure Select(Col,Row:Byte);
  Begin
    WriteXY(16+Col,10+Row,15+7*16,Chr(33+Col+46*Row));
    WriteXY(16,9,15,'Dec: '+ Int2Str(33+Col+46*Row)+ ' Hex: '+Byte2Hex(33+Col+46*Row));
  End;
  
Begin
  X := WhereX;
  Y := WhereY;
  MsgBox := TMenuBox.Create;
  MsgBox.Header     := ' TDF Chars ';
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
  
  MsgBox.Open (14, 8,65,12);
  
  Col := ch mod 46;
  Row := (ch div 46);
  Repeat
    DrawChars;
    Select(Col,Row);
    Case Keyboard.ReadKey Of
      #13: Begin
            GetTDFChar := 33+Col+46*Row;
            Break;
          End;
      #27: Begin
            GetTDFChar := 0;
            Break;
          End;
      #00: Case ReadKey Of
        KeyHome       : Col := 0;
        KeyEnd        : Col := 46;
        KeyCursorUp   : If Row > 0 Then Dec(Row);
        KeyCursorDown : If Row < 1 Then Inc(Row);
        KeyCursorLeft : If Col > 0 Then Dec(Col);
        KeyCursorRight : If Col < 46 Then Inc(Col);
      End;
    End;
  Until False;
  MsgBox.Close;
  MsgBox.Free;
  GotoXY(X,Y);

End;

Procedure EditFontFx;
Var
  MyBox  : TMenuBox;
  MyForm : TMenuForm;
  Data   : Array[1..10] of String[255];
  Ini    : TIniFile;
  i      : Byte;
Begin
  FillByte(Data, SizeOf(Data), 0);

  Ini := TIniFile.Create('blockart.ini');
  For i := 1 To 10 Do Data[i] := Ini.ReadString('FontFx',Int2Str(i),'');
  
  MyBox  := TMenuBox.Create;
  MyForm := TMenuForm.Create;
  With MyBox Do Begin
    FrameType  := 1;
    BoxAttr    := 8;
    Box3D      := True;
    BoxAttr2   := 8;
    BoxAttr3   := 7;
    BoxAttr4   := 15;
    Shadow     := True;
    ShadowAttr := 8;
    HeadAttr   := 15;
    HeadType   := 1;
  End;
  With MyForm Do Begin
    HelpSize := 79;
    HelpColor   :=7;
    cLo         :=7;
    cHi         :=7*16;
    cData       :=7;
    cLoKey      :=15;
    cHiKey      :=15+7*16;
    cField1     :=15;
    cField2     :=8;
  End;

  MyBox.Header := ' Font FX Edit ';

  MyBox.Open   (12, 7, 69, 18);

  MyForm.AddStr ('1',' FX1 ', 13,  8, 24,  8, 11, 42, 60, @Data[1], Data[1]);
  MyForm.AddStr ('2',' FX2 ', 13,  9, 24,  9, 11, 42, 60, @Data[2], Data[2]);
  MyForm.AddStr ('3',' FX3 ', 13, 10, 24, 10, 11, 42, 60, @Data[3], Data[3]);
  MyForm.AddStr ('4',' FX4 ', 13, 11, 24, 11, 11, 42, 60, @Data[4], Data[4]);
  MyForm.AddStr ('5',' FX5 ', 13, 12, 24, 12, 11, 42, 60, @Data[5], Data[5]);
  MyForm.AddStr ('6',' FX6 ', 13, 13, 24, 13, 11, 42, 60, @Data[6], Data[6]);
  MyForm.AddStr ('7',' FX7 ', 13, 14, 24, 14, 11, 42, 60, @Data[7], Data[7]);
  MyForm.AddStr ('8',' FX8 ', 13, 15, 24, 15, 11, 42, 60, @Data[8], Data[8]);
  MyForm.AddStr ('9',' FX9 ', 13, 16, 24, 16, 11, 42, 60, @Data[9], Data[9]);
  MyForm.AddStr ('0',' FX0 ', 13, 17, 24, 17, 11, 42, 60, @Data[10], Data[10]);
  

  MyForm.Execute;

  MyBox.Close;
  
  If MyForm.Changed Then
    If ShowMsgBox(1, 'Save changes?') Then Begin
      For i := 1 to 10 Do Ini.WriteString('FontFx',Int2Str(i),Data[i]);
    End;
  Ini.Free;
  MyForm.Free;
  MyBox.Free;
End;

Procedure CustomizeCaseFX(N: Byte);
Var
  MyBox  : TMenuBox;
  MyForm : TMenuForm;
  Data   : Array[1..4] of String[255];
  Ini    : TIniFile;
  i      : Byte;
Begin
  FillByte (Data, SizeOf(Data), 0);

  Ini := TIniFile.Create('blockart.ini');
  Data[1] := Ini.ReadString('CaseFx'+Int2Str(N),'Capitals','');
  Data[2] := Ini.ReadString('CaseFx'+Int2Str(N),'Lowers','');
  Data[3] := Ini.ReadString('CaseFx'+Int2Str(N),'Numbers','');
  Data[4] := Ini.ReadString('CaseFx'+Int2Str(N),'Symbols','');
  
  MyBox  := TMenuBox.Create;
  MyForm := TMenuForm.Create;
  With MyBox Do Begin
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
  With MyForm Do Begin
    HelpSize := 79;
    HelpColor   :=7;
    cLo         :=7;
    cHi         :=7*16;
    cData       :=7;
    cLoKey      :=15;
    cHiKey      :=15+7*16;
    cField1     :=15;
    cField2     :=8;
  End;

  MyBox.Header := ' Case FX Edit ';

  MyBox.Open   (12, 7, 69, 12);

  MyForm.AddStr ('1',' Capitals ', 13,  8, 24,  8, 11, 42, 60, @Data[1], Data[1]);
  MyForm.AddStr ('2',' Lowers ', 13,  9, 24,  9, 11, 42, 60, @Data[2], Data[2]);
  MyForm.AddStr ('3',' Numbers ', 13, 10, 24, 10, 11, 42, 60, @Data[3], Data[3]);
  MyForm.AddStr ('4',' Symbols ', 13, 11, 24, 11, 11, 42, 60, @Data[4], Data[4]);
  
  MyForm.Execute;

  MyBox.Close;
  
  If MyForm.Changed Then
    If ShowMsgBox(1, 'Save changes?') Then Begin
      Ini.WriteString('CaseFx'+Int2Str(N),'Capitals',Data[1]);
      Ini.WriteString('CaseFx'+Int2Str(N),'Lowers',Data[2]);
      Ini.WriteString('CaseFx'+Int2Str(N),'Numbers',Data[3]);
      Ini.WriteString('CaseFx'+Int2Str(N),'Symbols',Data[4]);
    End;
  Ini.Free;
  MyForm.Free;
  MyBox.Free;
End;


Procedure EditCaseFx;
Var
  List : TMenuList;
  i    : Byte;
Begin
  List := TMenuList.Create;

  List.Box.Header    := ' Select ';
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
  
  For i := 1 to 10 Do
    List.Add('Case FX No '+Int2Str(i), 0);
  
  Repeat
    List.Open (30, 8, 49, 19);
    List.Box.Close;

    Case List.ExitCode of
      #27 : Break;
    Else
      CustomizeCaseFX(List.Picked);
    End;
  Until False;
  List.Free;
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

Function MysticCodes:String;
Var
  List : TMenuList;
  Res  : Integer;
Begin
  List := TMenuList.Create;

  List.Box.Header    := ' Mystic Codes ';
  
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

  List.PosBar        := True;
  
  List.HiAttr := 7*16;
  List.LoAttr := 7;

  List.Add('Colors', 0);
  List.Add('Boxes', 0);
  List.Add('User Related', 0);
  List.Add('BBS Related', 0);
  List.Add('Various', 0);

  List.Open (30, 11, 49, 17);
  List.Box.Close;

  Case List.ExitCode of
    #27 : Result := '';
  Else
    Res := List.Picked;
    List.Clear;
    Case Res of
      1 : Begin
            List.Box.Header    := ' Mystic Colors ';
            List.SearchX    :=12;
            List.SearchY    :=23;
            List.SearchA    :=8;
            List.Picked:=1;
            List.Add('00 : Sets the current foreground to Black', 0);
            List.Add('01 : Sets the current foreground to Dark Blue', 0);
            List.Add('02 : Sets the current foreground to Dark Green', 0);
            List.Add('03 : Sets the current foreground to Dark Cyan', 0);
            List.Add('04 : Sets the current foreground to Dark Red', 0);
            List.Add('05 : Sets the current foreground to Dark Magenta', 0);
            List.Add('06 : Sets the current foreground to Brown', 0);
            List.Add('07 : Sets the current foreground to Grey', 0);
            List.Add('08 : Sets the current foreground to Dark Grey', 0);
            List.Add('09 : Sets the current foreground to Light Blue', 0);
            List.Add('10 : Sets the current foreground to Light Green', 0);
            List.Add('11 : Sets the current foreground to Light Cyan', 0);
            List.Add('12 : Sets the current foreground to Light Red', 0);
            List.Add('13 : Sets the current foreground to Light Magenta', 0);
            List.Add('14 : Sets the current foreground to Yellow', 0);
            List.Add('15 : Sets the current foreground to White', 0);
            List.Add('16 : Sets the current background to Black', 0);
            List.Add('17 : Sets the current background to Blue', 0);
            List.Add('18 : Sets the current background to Green', 0);
            List.Add('19 : Sets the current background to Cyan', 0);
            List.Add('20 : Sets the current background to Red', 0);
            List.Add('21 : Sets the current background to Magenta', 0);
            List.Add('22 : Sets the current background to Brown', 0);
            List.Add('23 : Sets the current background to Grey', 0);
            List.Add('24 : Sets the current background to Dark Grey     [iCE]', 0);
            List.Add('25 : Sets the current background to Light Blue    [iCE]', 0);
            List.Add('26 : Sets the current background to Light Green   [iCE]', 0);
            List.Add('27 : Sets the current background to Light Cyan    [iCE]', 0);
            List.Add('28 : Sets the current background to Light Red     [iCE]', 0);
            List.Add('29 : Sets the current background to Light Magenta [iCE]', 0);
            List.Add('30 : Sets the current background to light Yellow  [iCE]', 0);
            List.Add('31 : Sets the current background to light White   [iCE]', 0);
            List.Add('T1 : Sets current color to theme''s color #1', 0);
            List.Add('T2 : Sets current color to theme''s color #2', 0);
            List.Add('T3 : Sets current color to theme''s color #3', 0);
            List.Add('T4 : Sets current color to theme''s color #4', 0);
            List.Add('T5 : Sets current color to theme''s color #5', 0);
            List.Add('T6 : Sets current color to theme''s color #6', 0);
            List.Add('T7 : Sets current color to theme''s color #7', 0);
            List.Add('T8 : Sets current color to theme''s color #8', 0);
            List.Add('T9 : Sets current color to theme''s color #9', 0);
            List.Add('T0 : Sets current color to theme''s color #0', 0);
            List.Open (10, 3, 70, 23);
            List.Box.Close;

            Case List.ExitCode of
              #27 : Result := '';
            Else
              Case List.Picked Of
                1..32 : Result := '|'+StrPadL(Int2str(List.Picked-1),2,'0');
                33..41: Result := '|'+StrPadL(Int2str(List.Picked-32),2,'T');
                42    : Result := '|T0';
              End;
            End;
          End;
      2 : Begin
            List.Box.Header    := ' Mystic Boxes ';
            List.SearchX    :=12;
            List.SearchY    :=23;
            List.SearchA    :=8;
            List.Picked:=1;
            List.Add('|#B#<style>#<Y position>#<header>#<text># ~ OK Box/Restore', 0);
            List.Add('|#I<header>#<notification># ~ PopUp/No Restore', 0);
            List.Add('|#V#<style#>#<X position>#<Y pos>#<header>#<commands>#', 0);
            List.Add('|#X#<style>#<header>#<x1>#<y1>#<x2>#<y2>#', 0);
            List.Add('|#Y#<style #>#<Y position>#<header>#<text>#', 0);
            List.Open (5, 3, 75, 9);
            List.Box.Close;
            Case List.ExitCode of
              #27 : Result := '';
            Else
              Case List.Picked Of
                1 : Result := '|#B#<style>#<Y position>#<header>#<text>#';
                2 : Result := '|#I<header>#<notification>#';
                3 : Result := '|#V#<style#>#<X position>#<Y pos>#<header>#<commands>#';
                4 : Result := '|#X#<style>#<header>#<x1>#<y1>#<x2>#<y2>#';
                5 : Result := '|#Y#<style #>#<Y position>#<header>#<text>#';
              End;
            End;
          End;
      3 : Begin
            List.Box.Header    := ' Mystic User Commands ';
            List.SearchX    :=12;
            List.SearchY    :=23;
            List.SearchA    :=8;
            List.Picked:=1;
            List.Add('AG - User''s age in years',0);
            List.Add('AS - User''s auto signature (On or Off)',0);
            List.Add('AV - User''s chat availability for user to user chat (Yes or No)',0);
            List.Add('BD - User''s baud rate (returns TELNET or LOCAL) (may be removed)',0);
            List.Add('BI - User''s birthdate in their selected date format',0);
            List.Add('CM - User''s full screen node chat setting (On or Off)',0);
            List.Add('CS - User''s total number of calls to the BBS',0);
            List.Add('CT - User''s total number of calls to the BBS today',0);
            List.Add('DA - Current date in the User''s selected date format',0);
            List.Add('DK - User''s total downloads in kilobytes',0);
            List.Add('DL - User''s total number of downloaded files',0);
            List.Add('DT - User''s total number of downloads today',0);
            List.Add('FB - User''s current file base name',0);
            List.Add('FG - User''s current file group name',0);
            List.Add('FK - User''s total uploads in kilobytes ',0);
            List.Add('FO - User''s first call date in their selected date format',0);
            List.Add('FU - User''s total number of files uploaded',0);
            List.Add('HK - User''s hotkey setting (On or Off)',0);
            List.Add('IL - User''s node status invisibility (On or Off)',0);
            List.Add('KT - User''s downloads in kilobytes today',0);
            List.Add('LO - User''s last call date in their selected date format',0);
            List.Add('MB - User''s current message base name',0);
            List.Add('ME - User''s total number of e-mails sent',0);
            List.Add('MG - User''s current message group name',0);
            List.Add('ML - User''s lightbar message index setting (On or Off)',0);
            List.Add('MP - User''s total number of message posts',0);
            List.Add('PC - User''s current post to calls ratio',0);
            List.Add('QA - User''s selected archive format (QWK, etc)',0);
            List.Add('QE - User''s Generate QWKE setting (Yes or No)',0);
            List.Add('QL - User''s Include QWK file listing setting (Yes or No)',0);
            List.Add('RD - User''s download ratio for their current security level (files)',0);
            List.Add('RK - User''s download ratio for their current security level (kilobytes)',0);
            List.Add('SB - User''s max allowed minutes in time bank for current security level',0);
            List.Add('SC - User''s max calls per day allowed for current security level',0);
            List.Add('SD - User''s current security level description',0);
            List.Add('SK - User''s max allowed download kilobytes per day for current sec level',0);
            List.Add('SL - User''s current security level number',0);
            List.Add('SX - User''s max allowed downloaded files per day for current security level',0);
            List.Add('TB - User''s timebank minutes',0);
            List.Add('TE - User''s terminal emulation (Ansi or Ascii)',0);
            List.Add('TL - User''s time left in minutes',0);
            List.Add('TO - User''s time spent online this session (in minutes)',0);
            List.Add('U# - User''s number (aka permanent user index)',0);
            List.Add('U1 - User''s optional data answer for question #1',0);
            List.Add('U2 - User''s optional data answer for question #1',0);
            List.Add('U3 - User''s optional data answer for question #1',0);
            List.Add('UA - User''s address',0);
            List.Add('UB - User''s file listing type (Normal or Lightbar)',0);
            List.Add('UC - User''s city, state',0);
            List.Add('UD - User''s data phone number  ',0);
            List.Add('UE - User''s message editor type (Line, Full, or Ask)End;',0);
            List.Add('UF - User''s Date input format (MM/DD/YY, DD/MM/YY, YY/DD/MM)  ',0);
            List.Add('UG - User''s gender (Male or Female)Begin',0);
            List.Add('UH - User''s handle (alias)',0);
            List.Add('UI - User''s User information fieldEnd.',0);
            List.Add('UJ - User''s message reader type (Normal or Lightbar)',0);
            List.Add('UK - User''s email address',0);
            List.Add('UL - User''s selected theme description',0);
            List.Add('UM - User''s lightbar message index setting (On of Off)',0);
            List.Add('UN - User''s real name',0);
            List.Add('UP - User''s Home phone number',0);
            List.Add('UQ - User''s full screen editor quote mode (Standard or Lightbar)',0);
            List.Add('US - User''s screen size lines (ie 25)',0);
            List.Add('UX - User''s computer/router/internet host name',0);
            List.Add('UY - User''s IP address',0);
            List.Add('UZ - User''s zip (postal) code',0);
            List.Open (5, 3, 75, 23);
            List.Box.Close;
            Case List.ExitCode of
              #27 : Result := '';
            Else
              Case List.Picked Of
                1 : Result :='|AG';
                2 : Result :='|AS';
                3 : Result :='|AV';
                4 : Result :='|BD';
                5 : Result :='|BI';
                6 : Result :='|CM';
                7 : Result :='|CS';
                8 : Result :='|CT';
                9 : Result :='|DA';
                10 : Result :='|DK';
                11 : Result :='|DL';
                12 : Result :='|DT';
                13 : Result :='|FB';
                14 : Result :='|FG';
                15 : Result :='|FK';
                16 : Result :='|FO';
                17 : Result :='|FU';
                18 : Result :='|HK';
                19 : Result :='|IL';
                20 : Result :='|KT';
                21 : Result :='|LO';
                22 : Result :='|MB';
                23 : Result :='|ME';
                24 : Result :='|MG';
                25 : Result :='|ML';
                26 : Result :='|MP';
                27 : Result :='|PC';
                28 : Result :='|QA';
                29 : Result :='|QE';
                30 : Result :='|QL';
                31 : Result :='|RD';
                32 : Result :='|RK';
                33 : Result :='|SB';
                34 : Result :='|SC';
                35 : Result :='|SD';
                36 : Result :='|SK';
                37 : Result :='|SL';
                38 : Result :='|SX';
                39 : Result :='|TB';
                40 : Result :='|TE';
                41 : Result :='|TL';
                42 : Result :='|TO';
                43 : Result :='|U#';
                44 : Result :='|U1';
                45 : Result :='|U2';
                46 : Result :='|U3';
                47 : Result :='|UA';
                48 : Result :='|UB';
                49 : Result :='|UC';
                50 : Result :='|UD';
                51 : Result :='|UE';
                52 : Result :='|UF';
                53 : Result :='|UG';
                54 : Result :='|UH';
                55 : Result :='|UI';
                56 : Result :='|UJ';
                57 : Result :='|UK';
                58 : Result :='|UL';
                59 : Result :='|UM';
                60 : Result :='|UN';
                61 : Result :='|UP';
                62 : Result :='|UQ';
                63 : Result :='|US';
                64 : Result :='|UX';
                65 : Result :='|UY';
                66 : Result :='|UZ';
              End;
            End;
          End;
      4 : Begin
            List.Box.Header    := ' Mystic BBS Commands ';
            List.SearchX    :=12;
            List.SearchY    :=23;
            List.SearchA    :=8;
            List.Picked:=1;
            List.Add('BN - BBS name from System configuration', 0);
            List.Add('FT - Total number of files in current file base (dynamic)', 0);
            List.Add('MD - Menu description of the current menu (from menu flags)', 0);
            List.Add('MN - Network address of current message base', 0);
            List.Add('MT - Total number of messages in current message base (dynamic)', 0);
            List.Add('ND - Current node number', 0);
            List.Add('NE - Minutes until next BBS-type event', 0);
            List.Add('OS - Operating system (Windows, Linux, Raspberry Pi, etc)', 0);
            List.Add('PW - Configured number of days before required password change', 0);
            List.Add('SN - Configured Sysop name', 0);
            List.Add('SP - Configured post call ratio for the current security level', 0);
            List.Add('ST - Configured allowed minutes per day for current security level', 0);
            List.Add('TC - Total number of calls to the BBS system', 0);
            List.Add('TI - Current time of day in 12 hour format', 0);
            List.Add('VR - Mystic BBS version number', 0);
            List.Add('XD - Days left before the user''s account expires (or 0 if none)', 0);
            List.Add('XS - Security level in which the user''s account will expire to', 0);
            List.Open (5, 3, 75, 23);
            List.Box.Close;
            Case List.ExitCode of
              #27 : Result := '';
            Else
              Case List.Picked Of
                1: Result := '|BN';
                2: Result := '|FT';
                3: Result := '|MD';
                4: Result := '|MN';
                5: Result := '|MT';
                6: Result := '|ND';
                7: Result := '|NE';
                8: Result := '|OS';
                9: Result := '|PW';
                10: Result := '|SN';
                11: Result := '|SP';
                12: Result := '|ST';
                13: Result := '|TC';
                14: Result := '|TI';
                15: Result := '|VR';
                16: Result := '|XD';
                17: Result := '|XS';
              End;
            End;
          End;
      5 : Begin
            List.Box.Header    := ' Mystic Various Commands ';
            List.SearchX    :=12;
            List.SearchY    :=23;
            List.SearchA    :=8;
            List.Picked:=1;
            List.Add('AO   - Used in display files to disable aborting of the display file', 0);
            List.Add('BE   - Sends a ^G character to the terminal (beep code on some terms)', 0);
            List.Add('DE   - Delay for half a second', 0);
            List.Add('PA   - Send the pause prompt and wait for a key to be pressed', 0);
            List.Add('PB   - Purge the current input buffer', 0);
            List.Add('PI   - Display a pipe symbol (|)', 0);
            List.Add('PN   - Wait for a key to be pressed without prompting', 0);
            List.Add('PO   - Used in display files to disable pausing for that display file', 0);
            List.Add('QO   - Replaced with a randomly generated Quote of the Day', 0);
            List.Add('RP## - Sets the internal screen pause line counter to ##', 0);
            List.Add('XX   - Returns no value', 0);
            List.Add('DF<file>| - Send display file <file> Example: |DFmyansi|', 0);
            List.Add('DI## - Sets the baud rate of the current display file', 0);
            List.Open (5, 3, 75, 23);
            List.Box.Close;
            Case List.ExitCode of
              #27 : Result := '';
            Else
              Case List.Picked Of
                1:Result := '|AO';
                2:Result := '|BE';
                3:Result := '|DE';
                4:Result := '|PA';
                5:Result := '|PB';
                6:Result := '|PI';
                7:Result := '|PN';
                8:Result := '|PO';
                9:Result := '|QO';
                10:Result := '|RP##';
                11:Result := '|XX';
                12:Result := '|DF<file>|';
                13:Result := '|DI##';
              End;
            End;
          End;
    End;
  End;
List.Free;
{

* 

}
End;

Procedure EditLayerRec(Var Rec:TLayerRec);
Var
  MyBox  : TMenuBox;
  MyForm : TMenuForm;
Begin
  MyBox  := TMenuBox.Create;
  MyForm := TMenuForm.Create;
  
  With MyBox Do Begin
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
  With MyForm Do Begin
    HelpSize := 79;
    HelpColor   :=7;
    cLo         :=7;
    cHi         :=7*16;
    cData       :=7;
    cLoKey      :=15;
    cHiKey      :=15+7*16;
    cField1     :=15;
    cField2     :=8;
  End;

  MyBox.Header := ' Layer Attributes ';

  MyBox.Open   (10, 4, 68, 16);

  MyForm.AddStr ('T',' Title '    , 12,  5, 24,   5, 11, 35, 35, @sTitle, '');
  MyForm.AddStr ('A',' Author '   , 12,  6, 24,  6, 11, 20, 20, @SAuthor, '');
  MyForm.AddStr ('G',' Group '    , 12,  7, 24,  7, 11, 20, 20, @SGroup, '');
  MyForm.Execute;

  myBox.Close;
  
  If MyForm.Changed Then
    If ShowMsgBox(1, 'Save changes?') Then Begin
      //SaveSettings;
      
    End;
  MyForm.Free;
  MyBox.Free;
End;

Begin
End.
