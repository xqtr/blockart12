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

procedure beep;
begin
  fpsystem('play -q -n synth 0.1 sin 880');
end;

Procedure NilChar(TC:m_types.TCharInfo);
Begin
  fillbyte(tc,2,0);
End;

Procedure LWriteXY(x,y,a:byte; s:string);
Begin
  xcrt.screen.ImageWriteXYStr(Layer[CurLayer],x,y,a,s);
End;

Procedure LWriteXYChar(x,y,a:byte; C:Char);
Begin
  xcrt.screen.ImageWriteXYChr(Layer[CurLayer],x,y,a,C);
End;

Procedure MergeLayerDown(i:byte);
Var
  x,y:byte;
  c:char;
  a:byte;
Begin
  if i=1 then exit;
  for y:=1 to 25 do 
    for x:=1 to 80 do begin
      c:=Layer[i].data[y][x].UnicodeChar;
      a:=Layer[i].data[y][x].Attributes;
      If (c<>Settings.TransChar) and (a<>Settings.TransAttr) Then Begin
        Layer[i-1].data[y][x].Attributes:=a;
        Layer[i-1].data[y][x].UnicodeChar:=c;
      End;
    end;
End;

Procedure CopyCurrentLayerTo(i:byte);
Var
  x,y:byte;
Begin
  if (i<=0) Or (i>TotLayer) then exit;
  for y:=1 to 25 do 
    for x:=1 to 80 do begin
      Layer[i].data[y][x].Attributes:=Layer[CurLayer].data[y][x].Attributes;
      Layer[i].data[y][x].UnicodeChar:=Layer[CurLayer].data[y][x].UnicodeChar;
    end;
End;

Function AddLayer(name:string):smallint;
Begin
  result:=-1;
  If TotLayer >= Layers_max then exit;
  setlength(layer,length(layer)+1);
  setlength(ILayer,length(ilayer)+1);
  fillbyte(ilayer[high(ilayer)],0,sizeof(tlayerrec));
  ilayer[high(ilayer)].name:=name;
  ilayer[high(ilayer)].idx:=high(layer);
  clearimage(layer[high(layer)]);
  totlayer:=totlayer+1;
  result:=high(layer);
End;

Procedure DeleteLayer(i:byte);
var
  z:byte;
Begin
  if totlayer=1 then Begin
    clearimage(layer[1]);
    ilayer[0].name:='Layer #1';
    ilayer[0].idx:=1;
    exit;
  End;
  
  if i=high(layer) then begin
    setlength(layer,length(layer)-1);
    setlength(ilayer,length(ilayer)-1);
  end else begin
    for z:=i to high(layer)-1 do begin
      ClearImage(layer[z]);
      layer[z]:=layer[z+1];
      ilayer[z]:=ilayer[z+1];
      //move(layer[z+1],layer[z],sizeof(layer));
      //move(ilayer[z+1],ilayer[z],sizeof(ilayer));
    end;
    setlength(layer,length(layer)-1);
    setlength(ilayer,length(ilayer)-1);
  end;
  curlayer:=curlayer-1;if curlayer=0 then curlayer:=1;
  totlayer:=totlayer-1;
  Paste2Screen(layer[curlayer]);
  
End;

Procedure FlattenImage;
Var
  k : byte;
Begin
  If totlayer=1 then exit;
  For k := TotLayer downto 2 do Begin
    MergeLayerDown(k);
    Setlength(layer,length(layer)-1);
    Setlength(ilayer,length(ilayer)-1);
  End;
  totlayer:=1;
  curlayer:=1;
  Paste2Screen(layer[curlayer]);
End;

Procedure StoreXY;
Begin
  CurChar.PX := WhereX;
  CurChar.PY := WhereY;
End;

Procedure ReStoreXY;
Begin
  GotoXY(CurChar.PX,CurChar.PY);
End;

Procedure StoreOldXY;
Begin
  CurChar.PX := CurChar.OldX;
  CurChar.PY := CurChar.OldY;
End;

Procedure ReStoreOldXY;
Begin
  CurChar.OldX := CurChar.PX;
  CurChar.OldY := CurChar.PY;
End;

Procedure AddUndoState(V: Byte; Image: TConsoleImageRec);
Begin
  Undo.Count := Undo.Count + V;
  If Undo.Count >= Undo.Max Then Begin
    SaveScreenANSI(DirSlash(Settings.Folder)+'undo'+Int2Str(Undo.Index)+'.ans', Image, False);
    Undo.Index := Undo.Index + 1;
    If Undo.Index >= Undo.Max Then Undo.Index := 1;
    Undo.Count := 1;
  End;
End;

Procedure UndoScreen;
Begin
  StoreXY;
  Undo.Index := Undo.Index - 1;
  If (Undo.Index = 1) Or (Undo.Index > 20) Then Undo.Index := 20;
  If FileExist(DirSlash(Settings.Folder)+'undo'+Int2Str(Undo.Index)+'.ans') Then Begin
    //LoadANSIFile(DirSlash(Settings.Folder)+'undo'+Int2Str(Undo.Index)+'.ans');  TO FIX!!!
    ReStoreXY;
  End;
End;

Procedure DeleteUndoFiles;
Var
  i: Byte;
Begin
  For i := 1 to 20 Do 
    If FileExist(DirSlash(Settings.Folder)+'undo'+Int2Str(i)+'.ans') then 
      FileErase(DirSlash(Settings.Folder)+'undo'+Int2Str(i)+'.ans');
End;

Procedure CursorBlock;
Begin
  {$IFDEF Linux}
  xcrt.screen.RawWriteStr (#27 + '[?112c'+#7);
  {$ENDIF}
End;

Procedure HalfBlock;
Begin
  {$IFDEF Linux}
  xcrt.screen.RawWriteStr (#27 + '[?2c'+#7);
  {$ENDIF}
End;


Procedure BoxClear(X1,Y1,X2,Y2: Byte);
Var
  x,y : Byte;
Begin
  For X := X1 To X2 Do
    For Y := Y1 To Y2 Do Begin
      WriteXY(X,Y,CurChar.Color,' ');
      LWriteXYChar(X,Y,CurChar.Color,' ');
    End;
End;

Function Pipe2ANSI(S: String): Byte;
Var
  Pipe : String;
  Fg   : Byte;
  Bg   : Byte;
  i    : Byte;
  Tot  : Byte;
Begin
 i := 1;
  Tot := StrWordCount(S, '|');
  Fg := 0;
  Bg := 0;
  For i := 1 To Tot Do begin
      Pipe := strWordGet(i,s,'|');
      If Str2Int(Pipe) >=16 Then Begin
        bg := (Str2Int(Pipe) - 16);
      End Else Begin
        Fg := Str2Int(Pipe);
      End;
  End;  
    Result := Fg + bg * 16;
End;

Procedure LoadSettings;
Var
  Ini : TIniFile;
  t:string;
Begin
  Ini := TIniFile.Create('blockart.ini');
  With Settings Do begin
    Title  := Ini.ReadString('Sauce','Title','');
    Artist := Ini.ReadString('Sauce','Artist','');
    Group  := Ini.ReadString('Sauce','Group','');
    Sauce  := Ini.ReadBool('Sauce','Use',False);
    PGKeys := Ini.ReadBool('Various','PGKeys',False);
    CurChar.Tabs := Ini.ReadInteger('Various','Tabs',2);
    Settings.CharSet := Ini.ReadInteger('Various','CharSet',1);
    PGkeys:=Ini.ReadBool('Various','PGKeys',False);
    TransChar := Chr(Ini.ReadInteger('Transparent','Char',32));
    TransAttr := Ini.ReadInteger('Transparent','Attribute',7);
    CurChar.SelCharSet:=Ini.ReadInteger('Various','SelCharSet',5);
    Tab := Upper(Ini.ReadString('Various','Tab','---x---x---x---x---x---x---x---x---x---x---x---x---x---x---x---x---x---x---x---x'));
  End;
  Ini.Free;
End;

Procedure SaveSettings;
Var
  Ini : TIniFile;
Begin
  Ini := TIniFile.Create('blockart.ini');
  Ini.WriteString('Sauce','Title',Settings.Title);
  Ini.WriteString('Sauce','Artist',Settings.Artist);
  Ini.WriteString('Sauce','Group',Settings.Group);
  Ini.WriteBool('Sauce','Use',Settings.Sauce);
  Ini.WriteInteger('Various','Tabs',CurChar.Tabs);
  Ini.WriteInteger('Various','CharSet',Settings.CharSet);
  Ini.WriteBool('Various','PGKeys',Settings.PGKeys);
  Ini.WriteInteger('Transparent','Char',Ord(Settings.TransChar));
  Ini.WriteInteger('Transparent','Attribute',Settings.TransAttr);
  Ini.WriteInteger('Various','SelCharSet',CurChar.SelCharSet);
  Ini.WriteString('Various','Tab',Settings.Tab);
  Ini.Free;
End;

Procedure Edit;
Begin  
  Edited:=True;
End;

Procedure WriteAsc(x,y,d:byte);
Var
  cc:char;
Begin
  //GetCharAt(X,Y)
  cc:=addtopage(X, Y, Layer[CurLayer].Data[y][x].UnicodeChar, Chr(Charset[CurChar.SelCharSet][d]));
  LWriteXYChar(X,Y,CurChar.Color,cc);
  WriteXY(X,Y,CurChar.Color,cc);
  //writexy(1,1,0,' '+Layer[CurLayer].Data[y][x].UnicodeChar+' '+Chr(Charset[CurChar.SelCharSet][d])+' '+cc);
  writexy(1,1,0,' '+cc+' '+cc+' '+cc);
End;

Procedure CursorLeft;
Var
  X,Y : Byte;
Begin
  X := WhereX;
  Y := WhereY;
  If WhereX>1 Then GotoXY(WhereX-1,WhereY);
  If DrawMode = Draw_Color Then Begin
    Edit;
    WriteXY(WhereX,WhereY,CurChar.Color,GetCharAt(WhereX,WhereY));
    LWriteXYChar(WhereX,WhereY,CurChar.Color,GetCharAt(WhereX,WhereY));
  End;
  If DrawMode = Draw_Line Then Begin
    Edit;
    Case lmv Of
      Move_Left : WriteAsc(x,y,5);
      Move_Right: WriteAsc(x,y,5);
      Move_Up   : WriteAsc(x,y,2);
      Move_Down : WriteAsc(x,y,4);
    End;
  End;
  lmv := Move_Left;
End;

Procedure CursorRight;
Var
  X,Y : Byte;
Begin
  X := WhereX;
  Y := WhereY;
  If WhereX<80 Then GotoXY(WhereX+1,WhereY);
  If DrawMode = Draw_Color Then Begin
    Edit;
    WriteXY(WhereX,WhereY,CurChar.Color,GetCharAt(WhereX,WhereY));
    LWriteXYChar(WhereX,WhereY,CurChar.Color,GetCharAt(WhereX,WhereY));
  End;
  If DrawMode = Draw_Line Then Begin
    Edit;
    Case lmv Of
      Move_Left : WriteAsc(x,y,5);
      Move_Right: WriteAsc(x,y,5);
      Move_Up   : WriteAsc(x,y,1);
      Move_Down : WriteAsc(x,y,3);
    End;
  End;
  lmv := Move_Right;
End;

Procedure CursorUp;
Var
  X,Y : Byte;
Begin
  X := WhereX;
  Y := WhereY;
  If WhereY>1 Then GotoXY(WhereX,WhereY-1);
  If DrawMode = Draw_Color Then Begin
    Edit;
    WriteXY(WhereX,WhereY,CurChar.Color,GetCharAt(WhereX,WhereY));
    LWriteXYChar(WhereX,WhereY,CurChar.Color,GetCharAt(WhereX,WhereY));
  End;
  If DrawMode = Draw_Line Then Begin
    Edit;
    Case lmv Of
      Move_Left : WriteAsc(x,y,3);
      //WriteXY(X,Y,CurChar.Color,Chr(Charset[CurChar.SelCharSet][3]));
      Move_Right: WriteAsc(x,y,4);
      Move_Up   : WriteAsc(x,y,6);
      Move_Down : WriteAsc(x,y,6);
    End;
  End;
  lmv := Move_Up;
End;

Procedure CursorDown;
Var
  X,Y : Byte;
Begin
  X := WhereX;
  Y := WhereY;
  If WhereY<25 Then GotoXY(WhereX,WhereY+1);
  If DrawMode = Draw_Color Then Begin
    Edit;
    WriteXY(WhereX,WhereY,CurChar.Color,GetCharAt(WhereX,WhereY));
    LWriteXYChar(WhereX,WhereY,CurChar.Color,GetCharAt(WhereX,WhereY));
  End;
  If DrawMode = Draw_Line Then Begin
    Edit;
    Case lmv Of
      Move_Left : WriteAsc(x,y,1);
      Move_Right: WriteAsc(x,y,2);
      Move_Up   : WriteAsc(x,y,6);
      Move_Down : WriteAsc(x,y,6);
    End;
  End;
  lmv := Move_Down;
End;

Procedure CursorPGDN;
Begin
  GotoXY(WhereX,25);
End;

Procedure CursorPGUP;
Begin
  GotoXY(WhereX,1);
End;

Procedure CursorHome;
Var
  X,Y: Byte;
Begin
  X := WhereX;
  Y := WhereY;
  GotoXY(1,WhereY);
  If DrawMode = Draw_Color Then Begin
    Edit;
    For i := 1 To X Do Begin
      WriteXY(i,y,CurChar.Color,GetCharAt(i,Y));
      LWriteXYChar(i,y,CurChar.Color,GetCharAt(i,Y));
    End;
  End;
End;

Procedure CursorEnd;
Var
  X,Y: Byte;
Begin
  X := WhereX;
  Y := WhereY;
  GotoXY(80,WhereY);
  If DrawMode = Draw_Color Then Begin
    Edit;
    For i := X To 80 Do Begin
      WriteXY(i,y,CurChar.Color,GetCharAt(i,Y));
      LWriteXYChar(i,y,CurChar.Color,GetCharAt(i,Y));
    End;
  End;
End;

Procedure CursorEnter;
Begin
  CursorDown;
  CursorHome;
End;

Procedure CursorBackSpace;
Begin
  CursorLeft;
  WriteXY(WhereX,WhereY,CurChar.Color,' ');
  LWriteXYChar(WhereX,WhereY,CurChar.Color,' ');
End;

Procedure CursorINS;
Begin
  CurChar.Ins := Not CurChar.Ins;
End;

Procedure CursorOther;
Var
  fg,bg: Byte;
  cl   : Byte;
  Pipe : String;
  sx,sy: Byte;
  d    : Byte;
Begin
  If DrawMode = Draw_TDF Then Begin
    Sx := WhereX;
    Sy := WhereY;
    
    If Pos(ch,xtdf.CharsAvail)>0 Then Begin
      //SaveScreen(MainImage);
      AddUndoState(10,Layer[curlayer]);
      case xtdf.fontheader.fonttype of
        1: begin  
            D := xTDF.WriteCharBL(Sx,Sy,Ch) + xtdf.fontheader.spacing;
            xTDF.ImgWriteCharBL(Layer[CurLayer],Sx,Sy,CurChar.Color,Ch);
           end;
        2: begin  
            D := xTDF.WriteCharCL(Sx,Sy,Ch) + xtdf.fontheader.spacing;
            xTDF.ImgWriteCharCL(Layer[CurLayer],Sx,Sy,Ch);
           end;
      end;
    
      GotoXY(Sx + D, Sy);   
      
      CurChar.TDF_LWidth  := WhereX - Sx; 
      CurChar.TDF_LHeight := WhereY - Sy; 
    End Else beep;
  End Else Begin
    If DrawFx = Draw_CaseFx Then Begin
      //SaveScreen(MainImage);
      AddUndoState(2,Layer[curlayer]);
      Case Ch Of
        #48..#57 : Cl := Pipe2ANSI(CurChar.CaseFxNum);
        #65..#90 : Cl := Pipe2ANSI(CurChar.CaseFxCap);
        #97..#122: Cl := Pipe2ANSI(CurChar.CaseFxLow);
        #32..#47,
        #58..#64,
        #91..#96,
        #123..#126 : Cl := Pipe2ANSI(CurChar.CaseFxSym);
        
      End;
    End;
    If DrawFx = Draw_FontFx Then Begin
      //SaveScreen(MainImage);
      AddUndoState(2,Layer[curlayer]);
      If Ch = ' ' Then CurChar.FontFXIdx := 1;

      Repeat
        Pipe := strWordGet(CurChar.FontFXIdx,CurChar.FontFX,'|');
        If Str2Int(Pipe) >=16 Then Begin
          bg := (Str2Int(Pipe) - 16);
          CurChar.FontFXIdx := CurChar.FontFXIdx + 1;
        End Else Begin
          Fg := Str2Int(Pipe);
          CurChar.FontFXIdx := CurChar.FontFXIdx + 1;
          If CurChar.FontFXIdx >= CurChar.FontFXCnt Then CurChar.FontFXIdx := CurChar.FontFXCnt;
          Break;
        End;
        If CurChar.FontFXIdx >= CurChar.FontFXCnt Then Begin
          CurChar.FontFXIdx := CurChar.FontFXCnt;
          Break;
        End;
      Until  Str2Int(Pipe)<16;
      Cl := Fg + bg * 16;   
    End;
    
    If CurChar.Ins Then Begin
    sx:=wherex;
    sy:=wherey;
      //SaveScreen(MainImage);
      AddUndoState(2,Layer[curlayer]);
      Move(Layer[curlayer].Data[sy][sx],Layer[curlayer].Data[sy][sx+1],(80-sx)*2);
      //xcrt.RestoreScreen(MainImage);
      Paste2Screen(Layer[CurLayer]);
      gotoxy(sx,sy);
    End;
    
    If (DrawFx = 0) Then Cl := CurChar.Color;
    
    //SaveScreen(MainImage);
    AddUndoState(2,Layer[curlayer]);
    
    sx:=Wherex;
    sy:=wherey;
    
    If ((Ord(Ch)>=32) And (Ord(ch)<=64)) Or ((Ord(Ch)>=123) And (Ord(ch)<=126)) Then Begin
      WriteXY(sx,sy,Cl,ch);
      LWriteXYChar(sx,sy,Cl,ch);
    End
    Else Begin
      If (DrawMode = Draw_Elite) Then begin
        WriteXY(sx,sy,Cl,Chr(Font[2,Ord(ch)]));
        LWriteXYChar(sx,sy,Cl,Chr(Font[2,Ord(ch)]));
      end;
      If (DrawMode = Draw_Normal) Then begin
        WriteXY(sx,sy,Cl,Chr(Font[1,Ord(ch)]));
        LWriteXYChar(sx,sy,Cl,Chr(Font[1,Ord(ch)]));
      end;
    End;
    CursorRight;
  End;
  
End;

Procedure CursorTAB;
Var 
  k:Byte;
  OldCh: Char;
  OldCl: Byte;
  OldX : Byte;
Begin
  OldX := WhereX;
  For k := 80-CurChar.Tabs Downto OldX Do Begin
    OldCl := GetAttrAt(k,WhereY);
    OldCh := GetCharAt(k,WhereY);
    WriteXY(k+CurChar.Tabs,WhereY,OldCl,OldCh);
    LWriteXYChar(k+CurChar.Tabs,WhereY,OldCl,OldCh);
  End;
  For k := 1 to CurChar.Tabs Do Begin
    WriteXY(OldX+k-1,WhereY,CurChar.Color,' ');
    LWriteXYChar(OldX+k-1,WhereY,CurChar.Color,' ');
  End;
  //GotoXY(OldX,WhereY);
End;

Procedure InitCharSet;
Begin
(*
  CurChar.Charset[1]:=Chr(218)+Chr(191)+Chr(192)+Chr(217)+Chr(196)+Chr(179)+Chr(195)+Chr(180)+Chr(193)+Chr(194);
  CurChar.Charset[2]:=Chr(201)+Chr(187)+Chr(200)+Chr(188)+Chr(205)+Chr(186)+Chr(199)+Chr(185)+Chr(202)+Chr(203);
  CurChar.Charset[3]:=Chr(213)+Chr(184)+Chr(212)+Chr(190)+Chr(205)+Chr(179)+Chr(198)+Chr(189)+Chr(207)+Chr(209);
  CurChar.Charset[4]:=Chr(197)+Chr(206)+Chr(216)+Chr(215)+Chr(159)+Chr(233)+Chr(155)+Chr(156)+Chr(153)+Chr(239);
  CurChar.Charset[5]:=Chr(176)+Chr(177)+Chr(178)+Chr(219)+Chr(220)+Chr(223)+Chr(221)+Chr(222)+Chr(254)+Chr(249);
  CurChar.Charset[6]:=Chr(214)+Chr(183)+Chr(211)+Chr(189)+Chr(196)+Chr(186)+Chr(199)+Chr(182)+Chr(208)+Chr(210);
  CurChar.Charset[7]:=Chr(174)+Chr(175)+Chr(242)+Chr(243)+Chr(244)+Chr(245)+Chr(246)+Chr(247)+Chr(240)+Chr(251);
  CurChar.Charset[8]:=Chr(166)+Chr(167)+Chr(168)+Chr(169)+Chr(170)+Chr(171)+Chr(172)+Chr(248)+Chr(252)+Chr(253);
  CurChar.Charset[9]:=Chr(224)+Chr(225)+Chr(226)+Chr(235)+Chr(238)+Chr(237)+Chr(234)+Chr(228)+Chr(229)+Chr(230);
 CurChar.Charset[10]:=Chr(232)+Chr(233)+Chr(234)+Chr(155)+Chr(156)+Chr(157)+Chr(159)+Chr(145)+Chr(146)+Chr(247);
 *)
  
 CurChar.SelCharSet:=1;
End;

Procedure Center(S:String; L:byte);
Begin
  //WriteXYPipe((40-strMCILen(s) div 2),L,7,strMCILen(s),S);
  WriteXY((40-strMCILen(s) div 2),L,7,S);
  LWriteXY((40-strMCILen(s) div 2),L,7,S);
End;  

Function GetCommandOption (StartY: Byte; CmdStr: String) : Char;
Var
  Box     : TMenuBox;
  Form    : TMenuForm;
  Count   : Byte;
  Cmds    : Byte;
  CmdData : Array[1..10] of Record
              Key  : Char;
              Desc : String[18];
            End;
Begin
  Cmds := 0;

  While Pos('|', CmdStr) > 0 Do Begin
    Inc (Cmds);

    CmdData[Cmds].Key  := CmdStr[1];
    CmdData[Cmds].Desc := Copy(CmdStr, 3, Pos('|', CmdStr) - 3);

    Delete (CmdStr, 1, Pos('|', Cmdstr));
  End;

  Box  := TMenuBox.Create;
  Form := TMenuForm.Create;
  
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

  Form.HelpSize := 0;

  Box.Open (30, StartY, 51, StartY + Cmds + 1);

  For Count := 1 to Cmds Do
    Form.AddNone (CmdData[Count].Key, ' ' + CmdData[Count].Key + ' ' + CmdData[Count].Desc, 31, StartY + Count, 20, '');

  Result := Form.Execute;

  Form.Free;
  Box.Close;
  Box.Free;
End;

Procedure CustomBox (X1, Y1, X2, Y2: Byte);
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

Procedure BoxOpen (X1, Y1, X2, Y2: Byte);
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
End;

Procedure BoxClose;
Begin
  Box.Close;
  Box.Free;
End;

Procedure CoolBoxClose;
Begin
  xcrt.RestoreScreen(Image);
End;

Procedure AboutBox;
Begin
  BoxOpen (19, 7, 62, 19);

  WriteXY (21,  8,  15, strPadC('BlockArt ANSI Editor', 40, ' '));
  WriteXY (21,  9, 8, strRep('-', 40));
  WriteXY (21, 10, 7, strPadC('Copyright (C) 2018', 40, ' '));
  WriteXY (22, 11, 7, 'All Rights Reserved for the ANSI Scene');
  WriteXY (21, 13, 7, strPadC('Version 0.8 Beta', 40, ' '));
  WriteXY (21, 16, 7, strPadC('andr01d.zapto.org:9999', 40, ' '));
  WriteXY (21, 15, 7, strPadC('xqtr@gmx.com', 40, ' '));
  WriteXY (21, 17, 8, strRep('-', 40));
  WriteXY (21, 18,  7, strPadC('Press A Key', 40, ' '));

  ReadKey;

  BoxClose;
End;

Procedure SaveLayer(Image:TConsoleImageRec);
Var
  FileName : String;
  last : byte;
  d  : byte =1;
  SaveType : Byte;
Begin
  SaveType := GetSaveType;
  If SaveType = 0 Then Exit;
  
  Case SaveType Of
    1: FileName := GetSaveFileName(' Save As ',JustFile(CurrentFile),Settings.Folder,'*.ans');
    2: FileName := GetSaveFileName(' Save As ',JustFile(CurrentFile),Settings.Folder,'*.mys');
    3: FileName := GetSaveFileName(' Save As ',JustFile(CurrentFile),Settings.Folder,'*.asc');
    4: FileName := GetSaveFileName(' Save As ',JustFile(CurrentFile),Settings.Folder,'*.ban');
  
  End;
  If FileName = '' Then Exit;
  
  Case SaveType Of
    1 : SaveScreenANSI(Filename,Layer[curlayer],True);
    2 : SaveScreenMYSTIC(Filename,Layer[curlayer]);
    3 : SaveScreenTEXT(Filename,Layer[curlayer]);
    4 : SaveScreenBLOCKART(filename,Layer[curlayer],iLayer[curlayer]);
  End;
  
  Edited := False;
  CurrentFile := FileName;
End;

Procedure SaveFile;
Var
  f:file;
  fn:string;
  l:byte;
Begin
  fn:=GetSaveFileName(' Save File ',JustFile(CurrentFile),Settings.Folder,'*.ban');
  if fn='' then exit;
  
  assign(f,fn);
  rewrite(f,1);
  for l:=1 to TotLayer do begin
    blockwrite(f,ilayer[l],sizeof(TLayerRec));
    blockwrite(f,layer[l],sizeof(tconsoleimagerec));
  end;
  If HasSauce then Blockwrite(f,Filesauce,sizeof(filesauce));
  close(f);
End;

Procedure SaveANSIFile(Filename: String);
Var
  OutFile   : Text;
  fp        : file;
  prep      : byte;
  FG,BG     : Byte;
  oFG,oBG  : Byte;
  OldAT     : Byte;
  Outname   : String;
  Count1    : Integer;
  Count2    : Integer; 
  LastLine  : Byte;
  LineLen   : Byte;
  ll        : byte;
  lr        : byte;
  
Begin
  Prep := GetANSIPrep;
  if filename ='' then exit;
  Assign     (OutFile, filename);
  ReWrite    (OutFile);
  OldAt:=0;
  oFG:=0;
  oBG:=0;
  If SaveCur Then LastLine := WhereY
    Else LastLine := FindLastLine(layer[totlayer]);
  If Prep = 2 Then  System.Write(Outfile, ANSIClrScr);
  lr:=0;
  while lr<=totlayer do begin
    lr:=lr+1;
    if lr<>totlayer then ll:=25 else ll:=lastline;
    For Count1 := 1 to ll Do Begin
      LineLen := GetLineLength(layer[lr],Count1);
      For Count2 := 1 to 80 Do Begin
        If OldAt <> layer[lr].Data[Count1][Count2].Attributes then Begin
          FG := layer[lr].Data[Count1][Count2].Attributes mod 16;
          BG := 16 + (layer[lr].Data[Count1][Count2].Attributes div 16);
          if oFG<>FG then System.Write(Outfile,Ansi_Color(FG,GetTextAttr));
          if oBG<>BG then System.Write(Outfile,Ansi_Color(BG,GetTextAttr));
          oFG:=FG;
          oBG:=BG;
        End;
        System.Write(Outfile,layer[lr].Data[Count1][Count2].UnicodeChar);
        OldAt := layer[lr].Data[Count1][Count2].Attributes 
      End;
      If Count1 <> ll Then System.Write(Outfile,EOL);
    End;
  End;
  If Prep = 3 Then  System.Write(Outfile, ANSIHome);
  //If Settings.Sauce Then System.BlockWrite(Outfile,
  close(Outfile);
  
  If HasSauce then Begin
    assign(fp,filename);
    reset(fp,1);
    seek(fp,filesize(fp));
    Blockwrite(fp,Filesauce,sizeof(filesauce));
    close(fp);
  End;
End;

Procedure ExportFile;
Var
  FileName : String;
  last : byte;
  d  : byte =1;
  SaveType : Byte;
Begin
  SaveType := GetSaveType;
  If SaveType = 0 Then Exit;
  
  Case SaveType Of
    1: FileName := GetSaveFileName(' Save As ',JustFile(CurrentFile),Settings.Folder,'*.ans');
    2: FileName := GetSaveFileName(' Save As ',JustFile(CurrentFile),Settings.Folder,'*.mys');
    3: FileName := GetSaveFileName(' Save As ',JustFile(CurrentFile),Settings.Folder,'*.asc');
  End;
  If FileName = '' Then Exit;
  
  Case SaveType Of
    1 : SaveANSIFile(Filename);
    2 : SaveScreenMYSTIC(Filename,Layer[curlayer]);
    3 : SaveScreenTEXT(Filename,Layer[curlayer]);
  End;
  
  Edited := False;
  CurrentFile := FileName;
End;

Procedure NewFile;
Var
  i:byte;
Begin
  If Edited Then Begin
    If ShowMsgBox(1,'Save File?') Then SaveFile;
    ClrScr;
    Edited := False;  
    
  End;
  ClrScr;
  for i:=1 to totlayer do deletelayer(i);
  Setlength(SauceCom,0);
  fillbyte(filesauce,0,sizeof(filesauce));
  hassauce:=false;
  Paste2Screen(layer[curlayer]);
  fillbyte(ilayer[curlayer],0,sizeof(tlayerrec));
  ilayer[curlayer].name:='Layer #1';
  ilayer[curlayer].idx:=1;
  CurrentFile:='untitled.ans';
  edited:=false;
End;

Function OpenFile:Boolean;
Var
  FileName : String;
  fp:file;
  commentid:array[1..5] of char;
  i:byte;
  l:array[1..64] of char;
Begin
  Result:=False;
  FileName := GetUploadFileName(' Open File ',Settings.Folder,'*.*');
  If Filename = '' Then Begin
    //ShowMsgBox(0,'No File. Abort.');
    Exit;
  End;
  CurrentFile := FileName;
  //LoadANSIFile(Filename); TO FIX!!!
  
  Case upper(JustFileExt(filename)) of
    'ANS' : LoadAnsi(filename,FileSauce);
    'BAN' : LoadBlockartAnsi(filename,curlayer,FileSauce);
  End;
  
  fillbyte(filesauce,sizeof(filesauce),0);
  
  If FileSauce.Comments>0 Then Begin
    assign(fp,filename);
    reset(fp,1);
    seek(fp,filesize(fp)-128-5-(filesauce.comments*64));
    blockread(fp,commentid,5);
    if commentid='COMNT' then begin
      for i:=1 to filesauce.comments do begin
        setlength(saucecom,Length(saucecom)+1);
        blockread(fp,l,64);
        saucecom[high(saucecom)]:=l;
      End;
    end;
    close(fp);
  End;
  Paste2Screen(layer[curlayer]);
  Edited := False;
  GotoXY(1,1);
  Result:=True;
End;

Procedure Global(Var Image:TConsoleImageRec);
Var
  List  : TMenuList;
  o,p   : Byte;
  X,Y   : Byte;
  Ch,Ch1: Byte;
  fg,bg : Byte;
  attr  : Byte;
  cl1,cl2:Byte;
  Chh   : Char;
Begin
  X := WhereX;
  Y := WhereY;
  List := TMenuList.Create;

  List.Box.Header    := ' Global ';
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
  
  List.Add('Fill With Character',0);
  List.Add('Fill With Foreground Color',0);
  List.Add('Fill With BackGround Color',0);
  List.Add('Fill With Current Color',0);
  List.Add('Box',0);
  List.Add('Replace Color',0);
  List.Add('Replace Character',0);
  
 
 
  List.Open (25, 9, 55, 19);
  List.Box.Close;

  Case List.ExitCode of
    #27 : ;
    #13 : Begin
      Case List.Picked Of
        1 : Begin 
            Ch := GetChar;
            If Ch <> 0 Then For o := 1 to 25 Do 
                For p := 1 to 80 Do Begin
                  Image.Data[o][p].UnicodeChar:=Chr(Ch);
                  Image.Data[o][p].Attributes := CurChar.Color;
                End;
            End;
        2 : Begin
              For o := 1 to 25 Do
                For p := 1 to 80 Do Begin
                  attr  := Image.Data[o][p].Attributes;
                  fg := attr mod 16;
                  bg := attr div 16;
                  Image.Data[o][p].Attributes := (CurChar.Color mod 16) + bg * 16;
                End;
            End;
        3 : Begin
              For o := 1 to 25 Do
                For p := 1 to 80 Do Begin
                  attr  := Image.Data[o][p].Attributes;
                  fg := attr mod 16;
                  bg := attr div 16;
                  Image.Data[o][p].Attributes := fg + (CurChar.Color div 16) * 16;
                End;
            End;
        4 : Begin
              For o := 1 to 25 Do
                For p := 1 to 80 Do Begin
                  Image.Data[o][p].Attributes  := CurChar.Color;
                End;
            End;
        5: Begin
              For x := 1 To 80 Do Begin
                Image.Data[1][x].UnicodeChar:=Chr(CharSet[CurChar.SelCharSet][5]);
                Image.Data[1][x].Attributes := CurChar.Color;
                Image.Data[25][x].UnicodeChar:=Chr(CharSet[CurChar.SelCharSet][5]);
                Image.Data[25][x].Attributes := CurChar.Color;
              End;
              For y:= 1 To 25 Do Begin
                Image.Data[y][1].UnicodeChar:=Chr(CharSet[CurChar.SelCharSet][6]);
                Image.Data[y][1].Attributes := CurChar.Color;
                Image.Data[y][80].UnicodeChar:=Chr(CharSet[CurChar.SelCharSet][6]);
                Image.Data[y][80].Attributes := CurChar.Color;
              End;
              Image.Data[1][1].UnicodeChar:=Chr(CharSet[CurChar.SelCharSet][1]);
              Image.Data[1][1].Attributes := CurChar.Color;
              Image.Data[1][80].UnicodeChar:=Chr(CharSet[CurChar.SelCharSet][2]);
              Image.Data[1][80].Attributes := CurChar.Color;
              Image.Data[25][1].UnicodeChar:=Chr(CharSet[CurChar.SelCharSet][3]);
              Image.Data[25][1].Attributes := CurChar.Color;
              Image.Data[25][80].UnicodeChar:=Chr(CharSet[CurChar.SelCharSet][4]);
              Image.Data[25][80].Attributes := CurChar.Color;
           End;
      6 : Begin
              ShowMsgBox(0,'Choose Original Color');
              ch := GetColor(CurChar.Color);
              ShowMsgBox(0,'Replace With...');
              Ch1 := GetColor(CurChar.Color);
              If Ch<>Ch1 Then Begin
                For o := 1 to 25 Do
                  For p := 1 to 80 Do Begin
                    attr  := Image.Data[o][p].Attributes;
                    If Attr = Ch Then
                       Image.Data[o][p].Attributes := Ch1;
                  End;
              End;
            End;
      7 : Begin
              ShowMsgBox(0,'Choose Original Character');
              ch := GetChar;
              ShowMsgBox(0,'Replace With...');
              Ch1 := GetChar;
              If Ch<>Ch1 Then Begin
                For o := 1 to 25 Do
                  For p := 1 to 80 Do Begin
                    attr  := Ord(Image.Data[o][p].UnicodeChar);
                    If Attr = Ch Then
                       Image.Data[o][p].UnicodeChar := Chr(Ch1);
                  End;
              End;
          End;
      End;
      Paste2Screen(Layer[CurLayer]);
    End;
  End;
  Edit;
  List.Free;
  GotoXY(X,Y);
End;

Procedure EditTabs;
Var
  c:char;
  d,t:byte;
  w:byte;
Begin
  SaveScreen(MainImage);
  writexy(1,24,7,Settings.Tab);
  gotoxy(1,25);ClearEOL;
  writexypipe(7,25,7,'Move Using <> Arrows. '+Button('Set')+' '+Button('Clear')+' '+Button('Reset')+' '+Button('Erase')+' '+Button('Increment')+' '+Button('Quit'));
  gotoxy(1,24);
  repeat
    writexypipe(1,25,8,Button('X'+StrPadL(int2str(wherex),2,'0')+chr(179)));
    c:=upcase(readkey);
    Case Upcase(c) of
      'S' : WriteXY(Wherex,24,15,'X');
      'C' : WriteXY(Wherex,24,7,'-');
      'E' : WriteXY(1,24,7,StrRep('-',80));
      'R' : Begin
              WriteXY(1,24,7,StrRep('-',80));
              d:=0;
              while d <=80 do begin
                d:=d+4;
                WriteXY(d,24,15,'X');
              end;
            End;
      'I' : Begin
              w:=wherex;
              gotoxy(1,25);cleareol;
              settextattr(15);write('Set Increment [1-40]: ');
              t:=4;
              try
                t:=str2int(GetStr(23,25,2,2,1,7,15,#176,Int2Str(t)));
              except
                t:=4;
              end;
              d:=w-1;
              while d <=80 do begin
                d:=d+t;
                WriteXY(d,24,15,'X');
              end;
            writexypipe(7,25,7,'Move Using <> Arrows. '+Button('Set')+' '+Button('Clear')+' '+Button('Reset')+' '+Button('Erase')+' '+Button('Increment')+' '+Button('Quit'));
            gotoxy(w,24);
            End;
      #00 : Begin
              c:=readkey;
              Case c of
                KeyCursorLeft  : Gotox(wherex-1);
                KeyCursorRight : Gotox(wherex+1);
              end;
            End;
    end;
  until c='Q';
  Settings.Tab:='';
  for d:=1 to 80 do Settings.Tab:=Settings.Tab+GetCharAt(d,24);
  SaveSettings;
  xcrt.RestoreScreen(MainImage);
End;

Procedure CopyLayerTo;
Var
  LayerTo:Byte;
Begin
  Try
    SaveScreen(MainImage);
    CustomBox(33,10,47,12);
    WriteXY(34,10,11,' Copy to ');
    WriteXY(35,11,8,'Layer :');
    LayerTo := Str2Int(GetStr(43,11,2,2,1,7,15,#176,Int2Str(CurLayer)));
    CopyCurrentLayerTo(LayerTo);
    xcrt.RestoreScreen(MainImage);
  Except
    ShowMsgBox(0,'Wrong Input!');
  End;
End;

Procedure EditComments;
Var
  MyBox  : TMenuBox;
  c:char;
Begin
  MyBox  := TMenuBox.Create;
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
  MyBox.Header := ' Sauce Comments ';
  MyBox.Open   (5, 4, 75, 16);
  
  If (FileSauce.Comments>0) And (High(Saucecom)>0) Then 
    for i:=1 to FileSauce.Comments do Writexy(7,5+i,7,SauceCom[i-1]);
  
  ReadKey;
    
  MyBox.Close;
  MyBox.Free;
End;



Procedure EditSauce;
Var
  MyBox  : TMenuBox;
  MyForm : TMenuForm;
  Data   : Array[1..9] of String;
  Sauce  : RecSauceInfo;
  SDate  : String[8];
  sgroup:string[20];
  sauthor:string[20];
  stitle:string[35];
  stoggle:boolean;
  swidth,sheight:byte;
  sInfo3, sInfo4   : Word;
  sFlags    : Byte;
  sFiller:string;
Begin
  
  textcolor(7);
  {If Not ReadSauceInfo(CurrentFile,Sauce) Then Begin
    ShowMsgBox(0,'No Sauce Data.');
    If ShowMsgBox(1,'Add Sauce Data?')=False then Exit;
  Fillbyte(sauce, SizeOf(sauce), 0);
  SDate:='';
  sTitle:='';
  sAuthor:='';
  sGroup:='';
  End;}
  
  sTitle:=stripc(filesauce.title);
  sauthor:=stripc(filesauce.author);
  sgroup:=stripc(filesauce.group);
  sdate:=stripc(filesauce.date);
  stoggle:=false;
  If (filesauce.datatype=1) or (filesauce.datatype=2) then begin
    swidth:=filesauce.tinfo1;
    sheight:=filesauce.tinfo2;
  end;
  sInfo3:=0;
  sInfo4:=0;
  sFlags:=0;
  sFiller:='';

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

  MyBox.Header := ' Sauce Data ';

  MyBox.Open   (10, 4, 68, 16);

  {WriteXY(12,10,0+7*16,'Title  :');
  WriteXY(12,11,0+7*16,'Author :');
  WriteXY(12,12,0+7*16,'Group  :');
  
  WriteXY(21,10,0+7*16,Sauce.Title);
  WriteXY(21,11,0+7*16,Sauce.Author);
  WriteXY(21,12,0+7*16,Sauce.Group);}
  
   {ID       : Array[1..5] of Char;
    Version  : Array[1..2] of Char;
    Title    : Array[1..35] of Char;
    Author   : Array[1..20] of Char;
    Group    : Array[1..20] of Char;
    Date     : Array[1..8] of Char;
    FileSize : Longint;
    DataType : Byte;
    FileType : Byte;
    TInfo1   : Word;
    TInfo2   : Word;
    TInfo3   : Word;
    TInfo4   : Word;
    Comments : Byte;
    Flags    : Byte;
    Filler   : Array[1..22] of Char;}

  MyForm.AddStr ('T',' Title '    , 12,  5, 24,   5, 11, 35, 35, @sTitle, '');
  MyForm.AddStr ('A',' Author '   , 12,  6, 24,  6, 11, 20, 20, @SAuthor, '');
  MyForm.AddStr ('G',' Group '    , 12,  7, 24,  7, 11, 20, 20, @SGroup, '');
  WriteXY(33,8,8,'[YYYYMMDD]');
  MyForm.AddStr ('D',' Date '     , 12,  8, 24,  8, 11, 8, 8, @SDate, '');
  WriteXY(12,9,7,' DataType');
  Case Filesauce.datatype of
    0 : WriteXY(24,9,8,'Unknown');
    1 : Begin
          WriteXY(24,9,8,'Character');
          WriteXY(36,9,7,'FileType');
          Case Filesauce.datatype of
            0 : WriteXY(48,9,8,'ASCII');
            1 : WriteXY(48,9,8,'ANSI');
            2 : WriteXY(48,9,8,'ANSIMATION');
            3 : WriteXY(48,9,8,'RIP');
            4 : WriteXY(48,9,8,'PCBOARD');
            5 : WriteXY(48,9,8,'Avatar');
          end;
        End;
    2 : WriteXY(24,9,8,'Graphics');
    3 : WriteXY(24,9,8,'Vector');
    4 : WriteXY(24,9,8,'Sound');
  end;
  myform.Addbyte('W',' Width',12,10,24,10,11,3,0,255,@sWidth,'');
  myform.Addbyte('H',' Height',12,11,24,11,11,3,0,255,@sHeight,'');
  
  myform.Addword('3',' Info3',12,12,24,12,11,3,0,255,@sinfo3,'');
  myform.Addword('4',' Info4',12,13,24,13,11,3,0,255,@sinfo4,'');
  MyForm.AddStr ('F',' Filler '     , 12,  14, 24,  14, 11, 22, 22, @SFiller, '');

  WriteXY(12,15,7,' Comments');
  If filesauce.comments>0 Then WriteXY(24,15,15,'Yes') 
    Else WriteXY(24,15,8,'No');
    
  
  MyForm.Execute;

  myBox.Close;
  
  If MyForm.Changed Then
    If ShowMsgBox(1, 'Save changes?') Then Begin
      SaveSettings;
      With FileSauce Do Begin
        Title:=stitle;
        author:=sauthor;
        group:=sauthor;
        date:=sdate;
        tinfo1:=swidth;
        tinfo2:=sheight;
        filler:=sfiller;
      
      End;      
    End;
  MyForm.Free;
  MyBox.Free;
End;
{
Procedure ClearImage;
Begin
  Fillbyte (Layer[CurLayer].Data, SizeOf(Layer[CurLayer].Data), 0);
End;}

Procedure InsertLine(Var Image: TConsoleImageRec);
Begin
    Move (Image.Data[CurChar.OldY][1], Image.Data[CurChar.OldY+1][1], SizeOf(TConsoleLineRec) * (25-CurChar.OldY));
    FillByte(Image.Data[CurChar.OldY][1], SizeOf(TConsoleLineRec), 0);
    nilchar(Image.Data[CurChar.OldY][1]);
End;

Procedure InsertCol(Var Image: TConsoleImageRec);
Var
  y : Byte;
Begin
  For y := 1 to 25 Do Begin
    Move (Image.Data[y][CurChar.OldX], Image.Data[y][CurChar.OldX+1], (80-CurChar.OldX+1)*2);
    FillByte(Image.Data[y][CurChar.OldX], 2, 0);
    //nilchar(Image.Data[y][CurChar.OldX]);
  End;
End;

Procedure DeleteCol(Var Image: TConsoleImageRec);
Var
  y : Byte;
Begin
  For y := 1 to 25 Do Begin
    Move (Image.Data[y][CurChar.OldX+1], Image.Data[y][CurChar.OldX], (80-CurChar.OldX+1)*2);
    nilchar(Image.Data[y][80]);
  End;
End;

Procedure DeleteLine(Var Image: TConsoleImageRec);
Begin
    Move (Image.Data[CurChar.OldY+1][1], Image.Data[CurChar.OldY][1], SizeOf(TConsoleLineRec) * (25-CurChar.OldY));
    nilchar(Image.Data[25][1]);
End;

Function ReadSetting(Section,Key:String):String;
Var
  Ini : TiniFile;
Begin
  Ini := TIniFile.Create('blockart.ini');
  ReadSetting := Ini.ReadString(Section,Key,'');
  Ini.Free;
End;

Function SelectFontFX:Byte;
Var
  List  : TMenuList;
  X,Y   : Byte;
  i     : Byte;
  Ini   : TIniFile;
  Fx    : String;
Begin
  X := WhereX;
  Y := WhereY;
  SaveScreen(MainImage);
  List := TMenuList.Create;

  List.Box.Header    := ' Font FX Select ';
  
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
  CustomBox (36,7,60,18);
  WriteXY(38,7,11,' Preview ');
  Ini := TIniFile.Create('blockart.ini');
  For i := 1 to 10 Do Begin
    Fx := Ini.ReadString('FontFX',Int2Str(i),'');
    List.Add(' '+Int2Str(i)+' '+Fx,0);
    Fx := Replace(Fx,'|','#!');
    Fx := Replace(Fx,'!','|');
    Fx := Fx + '#';
    Delete(Fx,1,1);
    WriteXYPipe(40,7+i,7,Fx);
  End;
  
  List.Open (8, 7, 30, 18);
  List.Box.Close;

  Case List.ExitCode of
    #27 : SelectFontFX := 0;
  Else
    SelectFontFX := List.Picked;
  End;
  List.Free;
  Ini.Free;
  xcrt.RestoreScreen(MainImage);
  GotoXY(X,Y);
End;

Function SelectCaseFX:Byte;
Var
  List  : TMenuList;
  X,Y   : Byte;
  i     : Byte;
  Ini   : TIniFile;
  Fx    : String;
  Cap,
  Low,
  Sym,
  Num   : Byte;
 
Begin
  X := WhereX;
  Y := WhereY;
  SaveScreen(MainImage);
  List := TMenuList.Create;

  List.Box.Header    := ' Case FX Select ';
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
  CustomBox(36,7,60,18);
  WriteXY(43,7,11,' Preview ');
  Ini := TIniFile.Create('blockart.ini');
  For i := 1 to 10 Do Begin
    Cap := Pipe2ANSI(Ini.ReadString('CaseFX'+Int2Str(i),'Capitals',''));
    Low := Pipe2ANSI(Ini.ReadString('CaseFX'+Int2Str(i),'Lowers',''));
    Num := Pipe2ANSI(Ini.ReadString('CaseFX'+Int2Str(i),'Numbers',''));
    Sym := Pipe2ANSI(Ini.ReadString('CaseFX'+Int2Str(i),'Symbols',''));
    List.Add(' CaseFX No '+Int2Str(i),0);
    
    WriteXY(44,7+i,Cap,'AA');
    WriteXY(46,7+i,Low,'aa');
    WriteXY(48,7+i,Num,'88');
    WriteXY(50,7+i,Sym,'##');
  End;
  
  List.Open (8, 7, 30, 18);
  List.Box.Close;

  Case List.ExitCode of
    #27 : SelectCaseFX := 0;
  Else
    SelectCaseFX:= List.Picked;
  End;
  List.Free;
  Ini.Free;
  xcrt.RestoreScreen(MainImage);
  GotoXY(X,Y);
End;

Procedure LineTools;
Var
  List : TMenuList;
  S    : String;
  i    : Byte;
  Fc,Ft: Byte;
Begin
  List := TMenuList.Create;

  List.Box.Header    := ' Line Tools ';
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

  List.Add('Center Text', 0);
  List.Add('Right Text', 0);
  List.Add('Left Text', 0);
  List.Add('Clear Line', 0);
  List.Add('Fill FG', 0);
  List.Add('Fill BG', 0);
  List.Add('Fill Char.', 0);

  List.Open (30, 11, 55, 19);
  List.Box.Close;

  Case List.ExitCode of
    #27 : ;
  Else Begin
    Case List.Picked Of
      1:  Begin
            S := strStripB(GetLineText(Layer[curlayer],WhereY),' ');
            SetLineText(Layer[curlayer],0,WhereY,StrRep(#0,80),CurChar.Color);
            SetLineText(Layer[curlayer],((80-Length(S)) Div 2)-1,WhereY,S,CurChar.Color);
          End;
      2:  Begin
            S := strStripB(GetLineText(Layer[curlayer],WhereY),' ');
            SetLineText(Layer[curlayer],0,WhereY,StrRep(#0,80),CurChar.Color);
            SetLineText(Layer[curlayer],80-Length(S)-1,WhereY,S,CurChar.Color);
          End;
      3:  Begin
            S := strStripB(GetLineText(Layer[curlayer],WhereY),' ');
            SetLineText(Layer[curlayer],0,WhereY,StrRep(#0,80),CurChar.Color);
            SetLineText(Layer[curlayer],0,WhereY,S,CurChar.Color);
          End;
      4:  Begin
            SetLineText(Layer[curlayer],0,WhereY,StrRep(#0,80),CurChar.Color);
          End;   
      5: Begin
            Fc := CurChar.Color Mod 16;
            For I := 1 To 80 Do Begin
              Ft := Layer[curlayer].Data[WhereY][i].Attributes div 16;
              Layer[curlayer].Data[WhereY][i].Attributes := 16*Ft + Fc;
            End;
         End;
      6: Begin
            Fc := (CurChar.Color Div 16);
            For I := 1 To 80 Do Begin
              Ft := Layer[curlayer].Data[WhereY][i].Attributes mod 16;
              Layer[curlayer].Data[WhereY][i].Attributes := 16*fc+ft;
            End;
         End;
      7:  Begin
            i := GetChar;
            SetLineText(Layer[curlayer],0,WhereY,StrRep(Chr(i),80),CurChar.Color);
          End;  
      End;
      Paste2Screen(Layer[curlayer]);
    End;
  End;
  List.Free;
End;

Procedure DrawRuler;
Var
  i:byte;
Begin
  StoreXY;
  Paste2Screen(Layer[curlayer]);
  For i:=1 to 25 do WriteXY(CurChar.Px,i,15,Chr(179));
  For i:=1 to 80 do WriteXY(i,CurChar.Py,15,Chr(196));
  writexy(CurChar.Px,CurChar.Py,15,chr(197));
  
  writexy(CurChar.Px-4,CurChar.Py,15,chr(197));
  writexy(CurChar.Px+4,CurChar.Py,15,chr(197));
  writexy(CurChar.Px-9,CurChar.Py,15,chr(215));
  writexy(CurChar.Px+9,CurChar.Py,15,chr(215));
  writexy(CurChar.Px,CurChar.Py-4,15,chr(197));
  writexy(CurChar.Px,CurChar.Py+4,15,chr(197));
  writexy(CurChar.Px,CurChar.Py-9,15,chr(216));
  writexy(CurChar.Px,CurChar.Py+9,15,chr(216));
  
  ReStoreXY;
End;

Procedure SHowHelp;
Begin
SetTextAttr(7);
ClrScr;
GotoXY(1,2);
writeln('[2C[1;30mﬂﬂﬂﬂﬂﬂ€€‹ €€€ ∞∞∞∞ﬂﬂﬂﬂﬂﬂ€€‹ﬂﬂﬂﬂﬂﬂ€€€ €€€  €€€ﬂﬂﬂﬂﬂﬂ€€‹ﬂﬂﬂﬂﬂﬂ€€‹ ‹€€ﬂﬂﬂ     [0;37;40m ');
writeln('[2C[1;30m €€€ ‹€€ﬂ €≤€  ‹‹‹ €€€  €≤€ €€€  ﬂﬂﬂ €≤€ ‹€€ﬂ €€€ ‹€≤€ €€€ ‹€€ﬂ €≤€ ∞∞ 2018[0;37;40m ');
writeln('[2C[1;30m €≤€ﬂ €≤€ €≤€  €≤€ €≤€  €≤€ €≤€  ‹‹‹ €≤€ﬂ €≤€ €≤€ﬂ €≤€ €≤€ﬂ €≤€ €≤€ ∞∞ xqtr[0;37;40m ');
writeln('  [1;30m €€€‹‹€€ﬂ ﬂ€€‹‹€€€ ﬂ€€‹‹€€ﬂ ﬂ€€‹‹€€€ €€€  €€€ €€€  €€€ €€€  €€€ €€€ ∞∞[1Cv1.2[0;37;40m ');
writeln('                                                                              ');
writeln('   [1mAlt˙A[1C[0;37;40mChange text color attr.[37C         ');
writeln('   [1mAlt˙B[1C[0;37;40mBlock action commands[13C[1mAlt˙O[1C[0;37;40mOpen File in layer[2C         ');
writeln('   [1mAlt˙C[1C[0;37;40mChange character set[14C[1mAlt˙P[21C[0;37;40m         ');
writeln('   [1mAlt˙D[0;37;40m Change draw mode[18C[1mAlt˙Q[1C[0;37;40mCycle FG Color[6C         ');
writeln('   [1mAlt˙E[35CAlt˙R[1C[0;37;40mShow/Hide Ruler[5C         ');
writeln('   [1mAlt˙F[0;37;40m Select & Use TDF Font[13C[1mAlt˙S[1C[0;37;40mSave[15C          ');
writeln('   [1mAlt˙G[1C[0;37;40mGlobal commands[19C[1mAlt˙T[1C[0;37;40mLine Tools[10C         ');
writeln('   [1mAlt˙H[1C[0;37;40mHelp[30C[1mAlt˙U[1C[0;37;40mUse color under curs         ');
writeln('   [1mAlt˙I[1C[0;37;40mInverse color[21C[1mAlt˙V[21C[0;37;40m         ');
writeln('   [1mAlt˙J[1C[0;37;40mSelect Layer[22C[1mAlt˙W[1C[0;37;40mCycle BG Color[6C         ');
writeln('   [1mAlt˙K[0;37;40m Remove Column[21C[1mAlt˙X[0;37;40m Exit BlockArt[7C         ');
writeln('   [1mAlt˙L[1C[0;37;40mInsert Column[21C[1mAlt˙Y[21C[0;37;40m         ');
writeln('   [1mAlt˙M[1C[0;37;40mRemove Line[23C[1mAlt˙Z[1C[0;37;40mShow/Hide StatusBar[1C         ');
writeln('   [1mAlt˙N[1C[0;37;40mInsert Line[23C[1mF1-F10[1C[0;37;40mUse Character from Set      ');
writeln('                                                                              ');
writeln('                                                                              ');
writeln('                                                                              ');
writeln('                           [1;30mPress A key to continue...[2C[0;37;40m');
ReadKey;
End;

Function SelectLayer:Byte;
Var
  List  : TMenuList;
Begin
  StoreXY;
  List := TMenuList.Create;

  List.Box.Header    := ' Layers ';
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
  
  writexy(32,9,8,Strpadr('Name',12,' ')+' ##');
  For i:=1 to high(layer) do list.add(Strpadr(ilayer[i].name,12,' ')+' '+strpadl(int2str(i),2,'0'),0);
  
  List.Picked:=curlayer;
  List.Open (30, 8, 48, 19);
  List.Box.Close;

  Case List.ExitCode of
    #27 : Result := curlayer;
  Else
    Result := List.Picked;
  End;
  List.Free;
  ReStoreXY;
end;

Procedure GetTransAt(x,y,i:byte);
Begin
  settings.transchar:=layer[i].data[y][x].unicodechar;
  settings.transattr:=layer[i].data[y][x].attributes;
End;

Function OpenLayer:Boolean;
Var
  FileName : String;
Begin
  Result:=False;
  FileName := GetUploadFileName(' Open File ',Settings.Folder,'*.*');
  If Filename = '' Then Begin
    //ShowMsgBox(0,'No File. Abort.');
    Exit;
  End;
  
  Case upper(JustFileExt(filename)) of
    'ANS' : Result:=LoadAnsiImage(filename,layer[curlayer]);
    'BAN' : Result:=LoadBlockartImage(filename,layer[curlayer],ilayer[curlayer]);
  End;
 
  Paste2Screen(layer[curlayer]);
  Edited := True;
End;
