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

Program blockart;
{$mode objfpc}
{$extendedsyntax on}
Uses
  Math,
  m_Types,
  unix,
  DOS,
  xStrings,
  xCrt,
  xMenuBox,
  xMenuForm,
  xquicksort,
  xMenuInput,
  xfileIO,
  xDateTime,
  xTdf,
  xAnsi,
  blockart_dialogs,
  IniFiles,
  asciidraw,
  blockart_block,
  blockart_save,
  blockart_ansiloader,
  tdfstudio,
  blockart_types,
  blockart_gbext,
  blockart_nesext;

  
Const
  filex=2;
  filew=12;
  layerx=10;
  screenx=19;
  fontsx=29;
  toolsx=38;
  optionsx=47;
  helpx=58;
  
  layerw=14;
  screenw=14;
  fontsw=18;
  toolsw=13;
  optionsw=22;
  helpw=12;
          
  NormalFont    = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_''abcdefghijklmnopqrstuvwxyz';
  
  MaxAnsiLines = 5000;
  
  Save_ANSI     = 1;
  Save_Mystic   = 2;
  Save_Pascal   = 3;
  Save_Text     = 4;
  
  Draw_Color    = 2;
  Draw_Line     = 3;
  Draw_Normal   = 1;
  Draw_Block    = 4;
  Draw_Elite    = 5;
  Draw_TDF      = 6;
  Draw_FontFx   = 10;
  Draw_CaseFX   = 11;
  
  Move_None     = 0;
  Move_Left     = 1;
  Move_Right    = 2;
  Move_Down     = 3;
  Move_Up       = 4;
  
  Layers_max    = 30;

Var
  HelpFunc     : TMenuFormHelpProc;
  Layer        : Array of TConsoleImageRec;
  ILayer       : Array of TLayerRec;
  CurLayer     : Shortint = 1;
  TotLayer     : Byte = 0;
  Settings     : TSettings;
  Undo         : TUndo;
  Screen       : TOutput;
  Menu         : TMenuForm;
  Box          : TMenuBox;
  Image        : TConsoleImageRec;
  MainImage    : TConsoleImageRec;
  MenuPosition : Byte;
  Res          : Char;
  Keyboard     : Tinput;
  Edited       : Boolean = False;
  CurrentFile  : String = 'untitled.ans';
  RestoreScreen: Boolean = True;
  CurChar      : TGrChar;
  i,d          : Integer;
  SaveMode     : Byte;
  DrawMode     : Byte;
  DrawFx       : Byte = 0;
  Ch           : Char;
  ss,ss1       : String;
  ini          : tinifile;
  FileSauce    : RecSauceInfo;
  saucecom     : array of string[64];
  currentdir   : string;
  mv,lmv       : Byte;
  ShowStatusBar: Boolean = True;
  ShowRuler    : Boolean = False;
  HasSauce     : Boolean = False;
  db1,db2      : Byte;
  lasttab      : byte = 1;
  Font         : Array[1..2,65..122] of Byte = 
  ((65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122),
   (146,225,128,239,228,159,71,72,173,74,75,156,77,227,229,80,81,158,36,84,239,251,87,145,157,90,91,92,93,94,95,96,224,225,155,235,238,159,103,104,173,245,107,156,109,252,48,112,113,231,36,194,117,251,119,247,230,122));
  CharSetPr    : Array[1..10] Of String;
  CharSet      : Array[1..10,1..10] of Byte = ((218,191,192,217,196,179,195,180,193,194),
  (201,187,200,188,205,186,199,185,202,203),
  (213,184,212,190,205,179,198,189,207,209),
  (197,206,216,215,159,233,155,156,153,239),
  (176,177,178,219,220,223,221,222,254,249),
  (214,183,211,189,196,186,199,182,208,210),
  (174,175,242,243,244,245,246,247,240,251),
  (166,167,168,169,170,171,172,248,252,253),
  (224,225,226,235,238,237,234,228,229,230),
 (232,233,234,155,156,157,159,145,146,247));     
 
   procedure StoreXY; Forward;
   procedure ReStoreXY; Forward;
   Procedure Paste2Screen(Img:TConsoleImageRec); Forward;
   Procedure LoadAnsi (FName: String; Var Sauce:RecSauceInfo); Forward;
   Function LoadBlockartAnsi(FName: String; li:byte;Var Sauce:RecSauceInfo):Boolean; Forward;
   
{$I BLOCKART_COMMON.PAS}    

Procedure HelpF;
Begin
  With Menu Do Begin
    WriteXY(HelpX, HelpY,8,#178+#177+#176);
    WriteXY(HelpX+4, HelpY, HelpColor, StrPadR(ItemData[ItemPos]^.Help,HelpSize-4,' '));
  End;
End; 

Procedure DrawLogo;
Var
  i,m:byte;
Begin
  GotoXY(1,1);
  WriteLn('[77C[37m ');
  WriteLn('[77C ');
  WriteLn('[77C ');
  WriteLn('  [75C ');
  WriteLn('                                                                              ');
  WriteLn('  [72C    ');
  WriteLn('  ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ ');
  WriteLn('  [1;30mﬂﬂﬂﬂﬂﬂ€€‹ €€€ ∞∞∞∞ﬂﬂﬂﬂﬂﬂ€€‹ﬂﬂﬂﬂﬂﬂ€€€ €€€  €€€ﬂﬂﬂﬂﬂﬂ€€‹ﬂﬂﬂﬂﬂﬂ€€‹ ‹€€ﬂﬂﬂ     [0;37;40m ');
  WriteLn('  [1;30m €€€ ‹€€ﬂ €≤€  ‹‹‹ €€€  €≤€ €€€  ﬂﬂﬂ €≤€ ‹€€ﬂ €€€ ‹€≤€ €€€ ‹€€ﬂ €≤€ ∞∞ 2018[0;37;40m ');
  WriteLn('  [1;30m €≤€ﬂ €≤€ €≤€  €≤€ €≤€  €≤€ €≤€  ‹‹‹ €≤€ﬂ €≤€ €≤€ﬂ €≤€ €≤€ﬂ €≤€ €≤€ ∞∞ xqtr[0;37;40m ');
  WriteLn('  [1;30m €€€‹‹€€ﬂ ﬂ€€‹‹€€€ ﬂ€€‹‹€€ﬂ ﬂ€€‹‹€€€ €€€  €€€ €€€  €€€ €€€  €€€ €€€ ∞∞[1Cv1.2[0;37;40m ');
  WriteLn('  [1C‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹ ');
  WriteLn('');
  WriteLn('  [72C    ');
  WriteLn('  [72C    ');
  WriteLn('  [72C    ');
  WriteLn('  [72C    ');
  WriteLn('  [72C    ');
  WriteLn('  [72C    ');
  WriteLn('                                                                              ');
  WriteLn('                                                                              ');
  WriteLn('                                                                              ');
  WriteLn('[59C       ');
  delay(1000);
  for i:=1 to 40 do begin
    for m:=1 to 25 do Begin
      writexy(i,m,7,' ');
      writexy(81-i,m,7,' ');
    end;
    delay(30);
  end;
End;

Function LoadBlockartAnsi(FName: String; li:byte;Var Sauce:RecSauceInfo):Boolean;
Var
  R:TLayerRec;
  y,x:byte;
  l:byte;
  f:file;
  b:byte;
Begin
  Result:=false;
  if not fileexist(fname) then exit;
  
  FillByte(sauce,sizeof(sauce),0);
  HasSauce:=ReadSauceInfo(FName, Sauce);
  
  assign(f,fname);
  {$I-}reset(f,1);{$I+}
  if ioresult<>0 then exit;
  l:=li;
  while not eof(f) do begin
    blockread(f,ilayer[l],sizeof(Tlayerrec));
    blockread(f,layer[l],sizeof(tconsoleimagerec));
    l:=l+1;
    if l>totlayer then AddLayer('');
  end;
  
  
  close(f);
  result:=true;
End;

Procedure LoadAnsi (FName: String; Var Sauce:RecSauceInfo);
Var
  Buf      : Array[1..4096] of Char;
  BufLen   : LongInt;
  TotL     : Byte;
  cury     : Integer;
  Ansi     : TMsgBaseAnsi;
  AFile    : File;
  oFile    : File;
  Ch       : Char;
  FN       : String;
  Str      : String;
  //Sauce    : RecSauceInfo;
  x,y      : Byte;
  Res      : LongInt;

Begin
  FN       := FName;

  Screen.TextAttr:=7;
  
  If Not FileExist(FN) Then Exit;
  FillByte(sauce,sizeof(sauce),0);
  HasSauce:=ReadSauceInfo(FN, Sauce);
  
  Ansi := TMsgBaseAnsi.Create(nil, False);
  ansi.clear;

  Assign  (AFile, FN);
  ioReset (AFile, 1, fmReadWrite + fmDenyNone);

  While Not Eof(AFile) Do Begin
    ioBlockRead (AFile, Buf, SizeOf(Buf), BufLen);
    If Ansi.ProcessBuf (Buf, BufLen) Then Break;
  End;

  Close (AFile);
  
  If Ansi.Lines<26 then begin
    ClearImage(layer[curlayer]);
    for y:=1 to Ansi.Lines do 
      for x:=1 to 80 do begin
        Layer[CurLayer].data[y][x].attributes:=ansi.data[y][x].attr;
        Layer[CurLayer].data[y][x].UnicodeChar:=ansi.data[y][x].Ch;
      end;
  end else
  If (Ansi.Lines>25) and (Ansi.Lines<=250)Then Begin
    If showmsgbox(1,'File is bigger than a Layer. Use other Layers too?') then begin
      totl:=1;
      cury:=1;
      y:=1;
      ClearImage(layer[totl]);
      while CurY<=Ansi.Lines do begin
        for x:=1 to 80 do begin
          Layer[totl].data[y][x].attributes:=ansi.data[cury][x].attr;
          Layer[totl].data[y][x].UnicodeChar:=ansi.data[cury][x].Ch;
        end;
        y:=y+1;
        cury:=cury+1;
        if y>25 then begin
          y:=1;
          totl:=totl+1;
          AddLayer(JustFileName(JustFile(fname))+' #'+int2str(totl));
        end;
      end;
      
    end Else Begin
      ClearImage(layer[curlayer]);
      for y:=1 to 25 do 
        for x:=1 to 80 do begin
          Layer[CurLayer].data[y][x].attributes:=ansi.data[y][x].attr;
          Layer[CurLayer].data[y][x].UnicodeChar:=ansi.data[y][x].Ch;
        end;
    End;
  End;// else If (Ansi.Lines>250) Then ShowMsgBox(0,'Can''t handle files longer than 250 lines');
  
  
  
  Ansi.Free;
  If FileExist(Fname+'.tmp') Then FileErase(Fname+'.tmp');
End;

Procedure Paste2Screen(Img:TConsoleImageRec);
Begin
  StoreXY;  
  xcrt.RestoreScreen(Img);
  ReStoreXY;
End;

procedure RestoreStatusBar;
Var
  x:byte;
Begin
  For x:=1 to 80 Do Begin
    //SetTextAttr(Image.Data[25][x].Attributes);
    WriteXY(x,25,Layer[CurLayer].Data[25][x].Attributes,Layer[CurLayer].Data[25][x].UnicodeChar);
  End;
End;

Procedure AppExit;
Begin
  BoxOpen(30,10,50,13);
  WriteXY(34,11,15,'Are you sure?');
  If GetYN (36, 12, 15+7*16,7*16,8,False)=False Then Begin
    BoxClose;
    Exit;
  End;
  BoxClose;
  //If ShowMsgBox(1,'Are you Sure?')=False Then Exit;
  If Edited=True Then Begin
    //SaveScreen(MainImage);
    //If ShowMsgBox(1,'Save File?')=True Then SaveFile(MainImage);
  End;
  ClrScr;
  Menu.Free;
  SaveSettings;
  DeleteUndoFiles;
  Screen.Free;
  Keyboard.Free;
  halt;
End;

Procedure CoolBoxOpen (X1: Byte; Text: String);
Begin
  WriteXY(X1,1, 7*16, Text);
End;

Procedure StatusBar;
Begin
  //writexy(1,4,15,'High:'+int2str(high(layer))+' len:'+int2str(length(layer)));
  WriteXY(1,25,CurChar.Color Mod 16,Chr(219)+Chr(219)+Chr(219));
  WriteXY(4,25,8,#179);
  WriteXY(5,25,(CurChar.Color Div 16) * 16,'   ');
  WriteXY(8,25,8,#179);
  WriteXY(9,25,7,CharSetPr[CurChar.SelCharSet]);
  WriteXY(19,25,8,#179);
  WriteXYPipe(20,25,7, 'Ins:'+strYN(CurChar.Ins));
  WriteXY(27,25,8,#179);
  
  WriteXYPipe(28,25,7,StrPadR(DrawMode2Str(DrawMode),15,' ')+'|08'+#179+'|07'+
  StrPadR(Copy(JustFile(CurrentFile),1,12),12,' ')+'|08'+#179+'|07'+StrPadR(ilayer[curlayer].name,12,' ')+' |15'+Int2Str(Curlayer)+
  '|08/|15'+Int2Str(totlayer)+'|08'+#179+'|07'+Strpadl(int2str(wherex),2,'0')+#246+strpadl(int2str(wherey),2,'0'));
  {WriteXYPipe(28,25,7,StrPadR(DrawMode2Str(DrawMode),19,' '));
  WriteXY(48,25,8,#179);
  WriteXYPipe(49,25,7,StrPadR(Copy(JustFile(CurrentFile),1,12),12,' '));
  WriteXY(61,25,8,#179);
  WriteXYPipe(62,25,7,'Layer |15'+Int2Str(Curlayer)+'|08/|15'+Int2Str(Layers_max));
  WriteXY(74,25,8,#179);
  WriteXYPipe(75,25,7,Strpadl(int2str(wherex),2,'0')+#246+strpadl(int2str(wherey),2,'0')+' ');}
End;          


Begin
  Screen := TOutput.Create(True);
  Menu   := TMenuForm.Create;
  Keyboard := Tinput.create;
  xcrt.screen:=screen;
  xcrt.keyboard:=keyboard;
  xcrt.screen.SetWindowTitle('BlockArt');
  SaveMode := Save_ANSI;
  DrawMode := Draw_Normal;
  MenuPosition  := 0;
  CurChar.Ch    := ' ';
  CurChar.Color := 7;
  CurChar.Tabs  := 2;
  CurChar.Ins   := False;
  CurChar.TDF   := '';
  CurChar.Ins   := False;
  InitCharSet;
  LoadSettings;
  GetDir(0,Settings.Folder);
  CurChar.SaveCur := False;
  blockart_save.SaveCur := CurChar.SaveCur;
  
  Undo.Count:=1;
  Undo.Max := 20;
  Undo.Index := 1;
  
  //Load Settings
  getdir(0,currentdir);
  if not fileexist(addslash(apppath)+'blockart.ini') then 
    FontFolder:=currentdir else begin
      ini:=tinifile.create(addslash(apppath)+'blockart.ini');
      FontFolder:=ini.readstring('fonts','path','');
      ini.free;
      if FontFolder='' then FontFolder := currentdir;
    end;
    
  FillByte(FileSauce,Sizeof(filesauce),0);
  setlength(saucecom,0);
  SetTextAttr(7);
  ClrScr;
  DrawLogo;
  SetTextAttr(7);
  ClrScr;
  
  //Init Menu
  With Menu Do Begin
    HelpSize := 79;
    HelpX:=1;
    HelpColor   :=15;
    cLo         :=7;
    cHi         :=7*16;
    cData       :=15;
    cLoKey      :=15;
    cHiKey      :=15*16;
    cField1     :=11;
    cField2     :=12;
    
  End;
  menu.HelpProc := @HelpF;
  
  CharSetPr[1] := Chr(218)+Chr(191)+Chr(192)+Chr(217)+Chr(196)+Chr(179)+Chr(195)+Chr(180)+Chr(193)+Chr(194);
  CharSetPr[2] := Chr(201)+Chr(187)+Chr(200)+Chr(188)+Chr(205)+Chr(186)+Chr(199)+Chr(185)+Chr(202)+Chr(203);
  CharSetPr[3] := Chr(213)+Chr(184)+Chr(212)+Chr(190)+Chr(205)+Chr(179)+Chr(198)+Chr(189)+Chr(207)+Chr(209);
  CharSetPr[4] := Chr(197)+Chr(206)+Chr(216)+Chr(215)+Chr(159)+Chr(233)+Chr(155)+Chr(156)+Chr(153)+Chr(239);
  CharSetPr[5] := Chr(176)+Chr(177)+Chr(178)+Chr(219)+Chr(220)+Chr(223)+Chr(221)+Chr(222)+Chr(254)+Chr(249);
  CharSetPr[6] := Chr(214)+Chr(183)+Chr(211)+Chr(189)+Chr(196)+Chr(186)+Chr(199)+Chr(182)+Chr(208)+Chr(210);
  CharSetPr[7] := Chr(174)+Chr(175)+Chr(242)+Chr(243)+Chr(244)+Chr(245)+Chr(246)+Chr(247)+Chr(240)+Chr(251);
  CharSetPr[8] := Chr(166)+Chr(167)+Chr(168)+Chr(169)+Chr(170)+Chr(171)+Chr(172)+Chr(248)+Chr(252)+Chr(253);
  CharSetPr[9] := Chr(224)+Chr(225)+Chr(226)+Chr(235)+Chr(238)+Chr(237)+Chr(234)+Chr(228)+Chr(229)+Chr(230);
  CharSetPr[10] := Chr(232)+Chr(233)+Chr(234)+Chr(155)+Chr(156)+Chr(157)+Chr(159)+Chr(145)+Chr(146)+Chr(247);

  AddLayer('unused');
  totlayer:=0;
  AddLayer('Layer #1');
{
  For i:=1 to Layers_max Do Begin
    //FillByte(Layer[i],Sizeof(Layer[i]),0);
    //SaveScreen(Layer[i]);
    ClearImage(Layer[i]);
  End;}
  
  For i := 1 to 5 Do
    For d := 1 to 10 Do
      CurChar.Charset[i][d]:=Chr(200+i*d);
      
  If ShowStatusBar Then StatusBar;
  
  Repeat
  CurChar.OldX := WhereX;
  CurChar.OldY := WhereY;
  
  If Keypressed Then Begin
    Ch := Readkey; 
  Case Ch of
    #00: Begin
          Case Readkey of
      KeyAltP  : GetTransAt(WhereX,WhereY,curlayer);
      KeyAltE  : Begin
                    curlayer:=SelectLayer;
                    Paste2Screen(layer[curlayer]);
                End;
      KeyAltR  : ShowRuler:=Not ShowRuler;
      KeyAltJ  : Begin
                  GotoXY(1,25);
                  ClearEOL;
                  WriteXY(1,25,7,'Select Layer 1 to '+int2str(Layers_max));
                  ss:=GetStr(22,25,2,2,1,int2str(Curlayer));
                  if (str2int(ss)>=1) and (str2int(ss)<=layers_max) then begin
                    CurLayer:=str2int(ss);
                    SetTextAttr(7);
                    ClrScr;
                    Paste2Screen(Layer[CurLayer]);
                  end;
                 End;
      KeyALTZ  : Begin //Show Statusbar
                    ShowStatusBar := Not ShowStatusBar;
                    If Not ShowStatusBar then RestoreStatusBar;
                 End;
      KeyALTQ  : Begin // Circle FG Color
                    db1 := CurChar.Color mod 16;
                    db2 := CurChar.Color Div 16;
                    db1:=db1+1;
                    if db1>15 then db1:=0;
                    CurChar.Color:=db2*16 + db1;
                 End;
      KeyALTW  : Begin // Circle BG Color
                    db1 := CurChar.Color mod 16;
                    db2 := CurChar.Color Div 16;
                    db2:=db2+1;
                    if db2>6 then db2:=0;
                    CurChar.Color:=db2*16 + db1;
                 End;
      KeyCtrlZ: UndoScreen;
      KeyAltB: Begin
                  //DrawMode := Draw_Block;
                  //SaveScreen(MainImage);
                  AddUndoState(20,Layer[CurLayer]);
                  blockart_block.FontFile:=CurChar.TDF;
                  If ManageBlock(Layer[CurLayer],CurChar.Color,CurChar.SelCharset) Then Begin
                    Edited := True;
                    Paste2Screen(Layer[CurLayer]);
                  End;
               End;
      KeyAltG: Begin
                //SaveScreen(MainImage);
                AddUndoState(20,Layer[CurLayer]);
                Global(Layer[CurLayer]);
                Edit;
                //xcrt.RestoreScreen(Layer[CurLayer]);
                Paste2Screen(Layer[CurLayer]);
                //SaveScreen(MainImage);
               End;
      KeyAltH: Begin
                StoreXY;
                ShowHelp;
                xcrt.RestoreScreen(Layer[curlayer]);
                RestoreXY;
               End;
      KeyAltF: Begin
                tdfstudio.FontFolder := DirSlash(FontFolder);
                If FontGallery(CurChar.TDF,CurChar.TDFs)=True Then Begin
                  If not xtdf.init(CurChar.TDF) Then Begin
                    CurChar.TDF := '';
                    ShowMsgBox(0,'Font Loading Error');
                  End Else Begin
                    DrawMode := Draw_TDF;
                    xTDF.SelectFont(CurChar.TDFs);
                  End;
                End;
                xcrt.RestoreScreen(Layer[CurLayer]);
              End;
      KeyAltO: Begin
                //SaveScreen(MainImage);
                AddUndoState(20,Layer[CurLayer]);
                OpenFile;
                RestoreScreen := False;
               End;
      KeyAltC: Begin
                 mv := GetCharSetType(CurChar.SelCharSet);
                 if mv<255 then CurChar.SelCharSet := mv;
              End;
      KeyAltD: Begin
                 mv :=  GetDrawMode(DrawMode);
                 If mv <> 255 then DrawMode := mv;
               End;
      KeyAltS: Begin
                 //SaveScreen(MainImage);
                 SaveLayer(Layer[CurLayer]);
                 Edited:=False;
              End;
      KeyAltU: CurChar.Color := GetAttrAt(WhereX,WhereY);
      KeyAltI: Begin 
                 CurChar.Color := (CurChar.Color mod 16) * 16 + (CurChar.Color div 16);
               End;
      KeyAltN: Begin 
                  //SaveScreen(Image);
                  AddUndoState(20,Layer[CurLayer]);
                  InsertLine(Layer[CurLayer]); 
                  Paste2Screen(Layer[CurLayer]);
                  //SaveScreen(Image);
                  Edit;
               End;
      KeyAltM: Begin 
                  //SaveScreen(Image);
                  AddUndoState(20,Layer[CurLayer]);
                  DeleteLine(Layer[CurLayer]); 
                  Paste2Screen(Layer[CurLayer]);
                  //SaveScreen(Image);
                  Edit;
                  End;
      KeyAltK: Begin 
                  //SaveScreen(Image);
                  AddUndoState(20,Layer[CurLayer]);
                  Deletecol(Layer[CurLayer]); 
                  Paste2Screen(Layer[CurLayer]);
                  //SaveScreen(Image);
                  Edit;
                  End;
      KeyAltL: Begin 
                  //SaveScreen(Image);
                  AddUndoState(20,Layer[CurLayer]);
                  Insertcol(Layer[CurLayer]); 
                  Paste2Screen(Layer[CurLayer]);
                  //SaveScreen(Image);
                  Edit;
                  End;  
      KeyAltT: Begin 
                  //SaveScreen(MainImage);
                  AddUndoState(20,Layer[CurLayer]);
                  LineTools;
                  //SaveScreen(MainImage);
                  Edit;
                  End;  
      KeyAltA: Begin
                  //SaveScreen(MainImage);
                  CurChar.Color:=GetColor(CurChar.Color);
                  SetTextAttr(CurChar.Color);
                  //SaveScreen(MainImage);
               End;
      KeyAltX:  Begin
                  AppExit;
                  //Halt;
                End;
          #82:  CursorINS; //Insert
          #59: Begin
                //SaveScreen(MainImage);
                AddUndoState(2,MainImage);
                WriteXY(WhereX,WhereY,CurChar.Color,Chr(CharSet[CurChar.SelCharSet][1]));
                LWriteXYChar(WhereX,WhereY,CurChar.Color,Chr(CharSet[CurChar.SelCharSet][1]));
                CursorRight;
               End;
          #60:  Begin
                  //SaveScreen(MainImage);
                  AddUndoState(2,MainImage);
                  WriteXY(WhereX,WhereY,CurChar.Color,Chr(CharSet[CurChar.SelCharSet][2]));
                  LWriteXYChar(WhereX,WhereY,CurChar.Color,Chr(CharSet[CurChar.SelCharSet][2]));
                  CursorRight;
                  Edit;
                End;
          #61:  Begin
                  //SaveScreen(MainImage);
                  AddUndoState(2,MainImage);
                  WriteXY(WhereX,WhereY,CurChar.Color,Chr(CharSet[CurChar.SelCharSet][3]));
                  LWriteXYChar(WhereX,WhereY,CurChar.Color,Chr(CharSet[CurChar.SelCharSet][3]));
                  CursorRight;
                  Edit;
                End;
          #62: Begin
                  //SaveScreen(MainImage);
                  AddUndoState(2,MainImage);
                  WriteXY(WhereX,WhereY,CurChar.Color,Chr(CharSet[CurChar.SelCharSet][4]));
                  LWriteXYChar(WhereX,WhereY,CurChar.Color,Chr(CharSet[CurChar.SelCharSet][4]));
                  CursorRight;
                  Edit;
                End;
          #63: Begin
                  //SaveScreen(MainImage);
                  AddUndoState(2,MainImage);
                  WriteXY(WhereX,WhereY,CurChar.Color,Chr(CharSet[CurChar.SelCharSet][5]));
                  LWriteXYChar(WhereX,WhereY,CurChar.Color,Chr(CharSet[CurChar.SelCharSet][5]));
                  CursorRight;
                  Edit;
                End;
          #64: Begin
                  //SaveScreen(MainImage);
                  AddUndoState(2,MainImage);
                  WriteXY(WhereX,WhereY,CurChar.Color,Chr(CharSet[CurChar.SelCharSet][6]));
                  LWriteXYChar(WhereX,WhereY,CurChar.Color,Chr(CharSet[CurChar.SelCharSet][6]));
                  CursorRight;
                  Edit;
                End;
          #65: Begin
                  //SaveScreen(MainImage);
                  AddUndoState(2,MainImage);
                  WriteXY(WhereX,WhereY,CurChar.Color,Chr(CharSet[CurChar.SelCharSet][7]));
                  LWriteXYChar(WhereX,WhereY,CurChar.Color,Chr(CharSet[CurChar.SelCharSet][7]));
                  CursorRight;
                  Edit;
                End;
          #66: Begin
                  //SaveScreen(MainImage);
                  AddUndoState(2,MainImage);
                  WriteXY(WhereX,WhereY,CurChar.Color,Chr(CharSet[CurChar.SelCharSet][8]));
                  LWriteXYChar(WhereX,WhereY,CurChar.Color,Chr(CharSet[CurChar.SelCharSet][8]));
                  CursorRight;
                  Edit;
                End;
          #67: Begin
                  //SaveScreen(MainImage);
                  AddUndoState(2,MainImage);
                  WriteXY(WhereX,WhereY,CurChar.Color,Chr(CharSet[CurChar.SelCharSet][9]));
                  LWriteXYChar(WhereX,WhereY,CurChar.Color,Chr(CharSet[CurChar.SelCharSet][9]));
                  CursorRight;
                  Edit;
                End;
          #68: Begin
                  //SaveScreen(MainImage);
                  AddUndoState(2,MainImage);
                  WriteXY(WhereX,WhereY,CurChar.Color,Chr(CharSet[CurChar.SelCharSet][10]));
                  LWriteXYChar(WhereX,WhereY,CurChar.Color,Chr(CharSet[CurChar.SelCharSet][10]));
                  CursorRight;
                  Edit;
                End;
          keyCursorUP   : CursorUp; 
          keyCursorDOWN : CursorDown;      
          keyCursorLEFT : CursorLeft;      
          keyCursorRIGHT: CursorRight;      
          keyPGUP : If Settings.PGKeys then Begin
                      CurLayer:=CurLayer+1;
                      If CurLayer>TotLayer Then CurLayer:=1;
                      SetTextAttr(7);
                      Paste2Screen(Layer[CurLayer]);
                    End Else CursorPGUP;      
          keyPGDN : If Settings.PGKeys then Begin
                      CurLayer:=CurLayer-1;
                      If CurLayer<=0 Then CurLayer:=TotLayer;
                      SetTextAttr(7);
                      Paste2Screen(Layer[CurLayer]);
                    End Else CursorPGDN;       
          keyHOME : CursorHome;    
          keyEND  : CursorEnd;      
         End;
        If ShowRuler Then DrawRuler;
      End;
    #13: CursorEnter;
    #8 : Begin 
           If DrawMode <> Draw_TDF Then Begin
              CursorBackSpace;
              Edit;
           End Else Begin
              //SaveScreen(MainImage);
              AddUndoState(10,MainImage);
              D := WhereY;
              I := WhereX;
              BoxClear(I- CurChar.TDF_LWidth - xtdf.FontHeader.Spacing - 1 ,D, I, D + xtdf.fontchar.Height);
              GotoXY(I-CurChar.TDF_LWidth - xtdf.FontHeader.Spacing - 1, WhereY);
           End;
         End;
     KeyTab : Begin
                if pos('X',Settings.Tab)<>0 then Begin
                  mv:=wherex;
                  if mv=lasttab then mv:=mv+1;
                  while settings.tab[mv]<>'X' do begin
                    mv:=mv+1;
                    if mv>80 then mv:=1;
                  end;
                  lasttab:=mv;
                    gotox(mv);
                End;
              End;
    {keyTab : Begin
               Curlayer:=CurLayer+1;
               if CurLayer>Layers_max then CurLayer:=1;
               Paste2Screen(Layer[CurLayer]);
             End;}
#32..#126 : Begin CursorOther; Edit; End;
    #27: If DrawMode = Draw_Block Then Begin
            //DisableBlock;
         End Else Begin
          //SaveScreen(MainImage);
          RestoreScreen := True;
          //Writexy(1,1,7,StrPadR('   [ File ]     Tools    Fonts     Options    Layer     Help',80,' '));
          Writexy(1,1,7,StrPadR(' File    Layer    Screen    Fonts    Tools    Options    Help',80,' '));
           
          Repeat
          Menu.Clear;
          
          If MenuPosition = 0 Then Begin
            Menu.HiExitChars := #80;
            Menu.ExitOnFirst := False;
          End Else Begin
            Menu.HiExitChars := #75#77#27;
            Menu.ExitOnFirst := True;
          End;
      
          Case MenuPosition of
            0 : Begin
                  Menu.AddNone('M', ' File '   ,    filex, 1, 6,  'Main Program Functions');
                  Menu.AddNone('L', ' Layer '  ,   layerx, 1, 7,  'Layer Functions');
                  Menu.AddNone('S', ' Screen ' ,  screenx, 1, 8,  'Screen Functions');
                  Menu.AddNone('F', ' Fonts '  ,   fontsx, 1, 7,  'Font Functions');
                  Menu.AddNone('T', ' Tools '  ,   toolsx, 1, 7,  'Various Tools');
                  Menu.AddNone('O', ' Options ', optionsx, 1, 9,  'Program Options');
                  Menu.AddNone('H', ' Help '   ,    helpx, 1, 6,  'Help Screen');
      
                  Res := Menu.Execute;
      
                  If Menu.WasHiExit Then Begin
                      MenuPosition := Menu.ItemPos
                    End
                  Else
                    Case Res of
                      #27 : Begin
                              Menuposition:=0;
                              Break;
                            End;
                      'M' : MenuPosition := 1;
                      'T' : MenuPosition := 2;
                      'F' : MenuPosition := 3;
                      'O' : MenuPosition := 4;
                      'L' : MenuPosition := 5;
                      'H' : MenuPosition := 6;
                    End;
                End;
            1 : Begin
                  BoxOpen (filex-1, 2, filex+filew,  9);
                  CoolBoxOpen (filex, ' File ');
      
                  Menu.AddNone ('N', ' New'       , filex, 3, filew, 'Create New File');
                  Menu.AddNone ('O', ' Open'      , filex, 4, filew, 'Open ANS/BAN File');
                  Menu.AddNone ('S', ' Save File ', filex, 5, filew, 'Save to BAN Format');
                  Menu.AddNone ('E', ' Export    ', filex, 6, filew, 'Export to Other Formats');
                  Menu.AddNone ('U', ' Sauce     ', filex, 7, filew, 'Edit Sauce Data');
                  Menu.AddNone ('X', ' Exit      ', filex, 8, filew, 'Exit Blockart');
      
                  Res := Menu.Execute;
      
                  BoxClose;
                  CoolBoxClose;
      
                  If Menu.WasHiExit Then Begin
                    Case Res of
                      #75 : MenuPosition := 7;
                      #77 : MenuPosition := 2;
                    End;
                  End Else
                    Case Res of
                      #27 : Begin
                              Menuposition:=0;
                              Break;
                            End;
                      'U' : Begin
                              EditSauce;
                              Break;
                            End;
                      'E' : Begin
                              ExportFile;
                              Break;
                            End;
                      'S' : Begin
                              SaveFile;
                              Break;
                            End;
                      'N' : Begin
                              NewFile;
                              RestoreScreen := False;
                              Break;
                            End;
                      'O' : Begin
                              If OpenFile Then RestoreScreen := False Else
                                Begin
                                  RestoreScreen := True;
                                End;
                              Break;
                            End;
                      'X' : Begin
                              AppExit;
                              Break;
                            End;
                    Else
                      MenuPosition := 0;
                    End;
                End;
            2 : Begin
                  BoxOpen (layerx-1, 2, layerx+layerw, 12);
                  CoolBoxOpen (layerx, ' Layer  ');
      
                  Menu.AddNone ('A', ' Add Layer '   , layerx, 3, layerw, 'Add New Layer');
                  Menu.AddNone ('C', ' Clear '       , layerx, 4, layerw, 'Clear Layer');
                  Menu.AddNone ('M', ' Merge Down  ' , layerx, 5, layerw, 'Merge Down Layer');
                  Menu.AddNone ('Y', ' Copy To '     , layerx, 6, layerw, 'Copy This Layer to Another');
                  Menu.AddNone ('F', ' Flatten Img.' , layerx, 7, layerw, 'Merge All Layers Down');
                  Menu.AddNone ('T', ' Delete Layer' , layerx, 8, layerw, 'Delete This Layer');
                  Menu.AddNone ('X', ' Rename Layer' , layerx, 9, layerw, 'Rename layer');
                  Menu.AddNone ('S', ' Save Layer  ' , layerx,10, layerw, 'Save Only This Layer');
                  Menu.AddNone ('O', ' Open Layer  ' , layerx,11, layerw, 'Open File as Layer');
      
                  Res := Menu.Execute;
      
                  BoxClose;
                  CoolBoxClose;
      
                  If Menu.WasHiExit Then Begin
                    Case Res of
                      #75 : MenuPosition := 1;
                      #77 : MenuPosition := 3;
                    End;
                  end Else
                    Case Res of
                      'O' : Begin
                              OpenLayer;
                              Break;
                            End;
                      'S' : Begin
                              SaveLayer(Layer[CurLayer]);
                              Break;
                            End;
                      'X' : Begin 
                              ss:=StrBox(' Rename Layer ','Name', 12,12,ilayer[curlayer].name);
                              if ss<>'' then Begin
                                ilayer[curlayer].name:=ss;
                                Break;
                              End;
                            End;
                      'T' : Begin
                              If ShowMsgBox(1,'Delete Layer? Sure?') Then Begin
                                DeleteLayer(curlayer);
                                break;
                              end;
                            End;
                      'A' : Begin
                              ss:=StrBox(' Add Layer ','Name', 12,12,'Layer #'+int2str(TotLayer+1));
                              if ss<>'' then Begin
                                AddLayer(ss);
                                Break;
                              End;
                            End;
                      'Y' : CopyLayerTo;
                      'M' : Begin
                              MergeLayerDown(CurLayer);
                              Break;
                            End;
                      'F' : Begin
                              FlattenImage;
                              Break;
                            End;
                      'C' : Begin
                              If ShowMsgBox(1,'All Data Will be Lost') Then Begin
                                //ClearImage;
                                ClearImage(Layer[curlayer]);
                                Edited:=False;
                                Break;
                              End;
                            End;
                      #27 : Begin
                              Menuposition:=0;
                              Break;
                            End;
                    Else
                      MenuPosition := 0;
                    End;
                End;
            3 : Begin
                  BoxOpen (screenx-1, 2, screenx+screenw, 11);
                  CoolBoxOpen (screenx, ' Screen ');
                  
                  Menu.AddNone ('I', ' Insert Line ' , screenx, 3,  screenw, 'Insert New Lines');
                  Menu.AddNone ('D', ' Delete Line ' , screenx, 4, screenw, 'Delete Line');
                  Menu.AddNone ('N', ' Insert Col. ' , screenx, 5, screenw, 'Insert Column');
                  Menu.AddNone ('E', ' Delete Col. ' , screenx, 6, screenw, 'Delete Column');
                  Menu.AddNone ('L', ' Move Left '   , screenx, 7, screenw, 'Move Image Left');
                  Menu.AddNone ('R', ' Move Right '  , screenx, 8, screenw, 'Move Image Right');
                  Menu.AddNone ('P', ' Move Up '     , screenx, 9, screenw, 'Move Image Up');
                  Menu.AddNone ('W', ' Move Down '   , screenx, 10, screenw, 'Move Image Down');
                  
                  Res := Menu.Execute;
      
                  BoxClose;
                  CoolBoxClose;
      
                  If Menu.WasHiExit Then Begin
                    Case Res of
                      #75 : MenuPosition := 2;
                      #77 : MenuPosition := 4;
                    End;
                  end Else
                    Case Res of
                      #27 : Begin
                              Menuposition:=0;
                              Break;
                            End;
                      
                      'I' : Begin
                              InsertLine(Layer[curlayer]);
                              Edit;
                              Break;
                            End;
                      'D' : Begin
                              DeleteLine(Layer[curlayer]);
                              Edit;
                              Break;
                            End;
                      'N' : Begin
                              Insertcol(Layer[curlayer]);
                              Edit;
                              Break;
                            End;
                      'E' : Begin
                              Deletecol(Layer[curlayer]);
                              Edit;
                              Break;
                            End;
                      'L' : Begin
                             StoreOldXY;
                             CurChar.OldX:=1;
                             CurChar.OldY:=1;
                             GotoXY(1,1);
                             Deletecol(Layer[curlayer]);
                             Edit;
                             ReStoreOldXY;
                             Break;
                            End;
                      'R' : Begin
                             StoreOldXY;
                             CurChar.OldX:=1;
                             CurChar.OldY:=1;
                             GotoXY(1,1);
                             InsertCol(Layer[curlayer]);
                             Edit;
                             ReStoreOldXY;
                             Break;
                            End;
                  'p','P' : Begin
                             StoreOldXY;
                             CurChar.OldX:=1;
                             CurChar.OldY:=1;
                             GotoXY(1,1);
                             DeleteLine(Layer[curlayer]);
                             Edit;
                             ReStoreOldXY;
                             Break;
                            End;
                   'w','W' : Begin
                             StoreOldXY;
                             CurChar.OldX:=1;
                             CurChar.OldY:=1;
                             GotoXY(1,1);
                             InsertLine(Layer[curlayer]);
                             Edit;
                             ReStoreOldXY;
                             Break;
                            End;
                    Else
                      MenuPosition := 0;
                    End;
                End;
            4 : Begin
                  BoxOpen (fontsx-1, 2, fontsx+fontsw, 13);
                  CoolBoxOpen (fontsx, ' Fonts ');
      
                  Menu.AddNone ('N', ' Normal Font '        , fontsx, 3, fontsw, 'Select Norma Font');
                  Menu.AddNone ('E', ' Elite Mode '         , fontsx, 4, fontsw, 'Select Elite Write Mode');
                  Menu.AddNone ('T', ' TheDraw Font '       , fontsx, 5, fontsw, 'Write With TDF Font');
                  Menu.AddNone ('X', ' Fade FX '            , fontsx, 6, fontsw, 'Use FadeFX Write Mode');
                  Menu.AddNone ('S', ' Case FX '            , fontsx, 7, fontsw, 'Use CaseFX Write Mode');
                  WriteXY(fontsx,8,8,' ====---------====');
                  Menu.AddNone ('G', ' TheDraw Font Gal. '  , fontsx, 9, fontsw, 'TheDraw Font Gallery and Other Font Tools');
                  Menu.AddNone ('D', ' Create Empty TDF  '  , fontsx, 10, fontsw, 'Create an Empty TDF File');
                  Menu.AddNone ('F', ' Edit Fade FX '       , fontsx, 11, fontsw, 'Customize FadeFX Formats');
                  Menu.AddNone ('C', ' Edit Case FX '       , fontsx, 12, fontsw, 'Customize CaseFX Formats');
                  
      
                  Res := Menu.Execute;
      
                  BoxClose;
                  CoolBoxClose;
      
                  If Menu.WasHiExit Then Begin
                    Case Res of
                      #75 : MenuPosition := 3;
                      #77 : MenuPosition := 5;
                    End;
                  End Else
                    Case Res of
                      #27 : Begin
                              Menuposition:=0;
                              Break;
                            End;
                      'D' : Begin
                              ss:=GetSaveFileName(' Font File ','newfont.tdf',DirSlash(FontFolder),'*.tdf');
                              //If FileExist(ss) Then 
                              //  If ShowMsgBox(1,'File Exists. Overwrite?')=False Then Exit;
                              If ss='' Then Break;
                                BoxOpen(32,7,47,9);
                                Writexy(33,7,11,' Font Name ');
                                Writexy(1,25,7,StrPadR('Leave Blank to abort. Press ENTER when ready.',79,' '));
                                ss1:='';
                                ss1:=GetStr(34,8,12,12,1,7,15,#176,ss1);
                                mv:=GetFontType;
                                BoxClose;
                                if (mv=0) or (mv=1) then Begin
                                  ShowMsgBox(0,'Unsupported type');
                                  Break;
                                End;
                                If ss1<>'' Then 
                                  If NewEmptyFont(ss,ss1,mv-1) Then ShowMsgBox(0,'Font created!') Else
                                    ShowMsgBox(0,'Error while creating font!');
                              
                            End;
                      'T' : Begin
                              If CurChar.TDF <> '' Then DrawMode := Draw_TDF
                                Else ShowMsgBox(0,'No Font Selected!');
                              Break;
                            End;
                      'G' : Begin
                              tdfstudio.FontFolder := DirSlash(FontFolder);
                              If FontGallery(CurChar.TDF,CurChar.TDFs)=True Then Begin
                                If not xtdf.init(CurChar.TDF) Then Begin
                                  CurChar.TDF := '';
                                  ShowMsgBox(0,'Font Loading Error');
                                End Else Begin
                                  DrawMode := Draw_TDF;
                                  xTDF.SelectFont(CurChar.TDFs);
                                  Break;
                                End;
                              End;
                            End;
                      'N' : Begin
                              DrawMode := Draw_Normal;
                              DrawFx   := 0;
                              Break;
                            End;
                      'E' : Begin
                              DrawMode := Draw_Elite;
                              DrawFx   := 0;
                              Break;
                            End;
                      'F' : EditFontFx;
                      'C' : EditCaseFx;
                      'X' : Begin
                              D := SelectFontFX;
                              If D <> 0 Then Begin 
                                CurChar.FontFxSel := D;
                                CurChar.FontFx := ReadSetting('FontFx',Int2Str(D));
                                CurChar.FontFxCnt := strWordCount(CurChar.FontFx,'|');
                                If CurChar.FontFxCnt > 0 Then Begin
                                  DrawFx := Draw_FontFx;
                                  CurChar.FontFxIdx := 1;
                                  Break;
                                End;
                              End Else Begin
                                //ShowMsgBox(0,'No Selection.');
                              End;
                            End;
                      'S' : Begin
                                D := SelectCaseFX;
                                If D <> 0 Then Begin 
                                  CurChar.CaseFxSel := D;
                                  CurChar.CaseFxCap := ReadSetting('CaseFx'+Int2Str(D),'Capitals');
                                  CurChar.CaseFxLow := ReadSetting('CaseFx'+Int2Str(D),'Lowers');
                                  CurChar.CaseFxNum := ReadSetting('CaseFx'+Int2Str(D),'Numbers');
                                  CurChar.CaseFxSym := ReadSetting('CaseFx'+Int2Str(D),'Symbols');
                                  DrawFx := Draw_CaseFx;
                                  Break;
                                End Else Begin
                                  //ShowMsgBox(0,'No Selection.');
                                End;
                              End;
                    Else
                      MenuPosition := 0;
                    End;
                End;
          5 : Begin
                  BoxOpen (toolsx-1, 2, toolsx+toolsw, 11);
                  CoolBoxOpen (toolsx, ' Tools ');
      
                  Menu.AddNone ('P', ' Pick Color '  , toolsx, 3, toolsw, 'Choose Color Dialog');
                  Menu.AddNone ('A', ' ASCII Table ' , toolsx, 4, toolsw, 'ASCII Table');
                  Menu.AddNone ('S', ' Charset '     , toolsx, 5, toolsw, 'Select CharSet');
                  Menu.AddNone ('D', ' Draw Mode '   , toolsx, 6, toolsw, 'Select DrawMode (Normal, Line, Color)');
                  Menu.AddNone ('G', ' Global '      , toolsx, 7, toolsw, 'Global Functions');
                  Menu.AddNone ('E', ' GameBoy Exp.' , toolsx, 8, toolsw, 'Import GameBoy Graphics');
                  Menu.AddNone ('N', ' NES Export'   , toolsx, 9, toolsw, 'Import NES Graphics');
                  Menu.AddNone ('M', ' Mystic Codes ', toolsx, 10, toolsw, 'Insert Mystic BBS Pipe Command');
      
                  Res := Menu.Execute;
      
                  BoxClose;
                  CoolBoxClose;
      
                  If Menu.WasHiExit Then Begin
                    Case Res of
                      #75 : MenuPosition := 4;
                      #77 : MenuPosition := 6;
                    End;
                  End Else
                    Case Res of
                      #27 : Begin
                              Menuposition:=0;
                              Break;
                            End;
                      'M' : Begin
                              ss:=MysticCodes;
                              If ss<>'' Then Begin
                                WriteXY(CurChar.OldX,CurChar.OldY,CurChar.Color,ss);
                                LWriteXY(CurChar.OldX,CurChar.OldY,CurChar.Color,ss);
                              End;
                            End;
                      'S' : Begin
                              mv := GetCharSetType(CurChar.SelCharSet);
                              if mv<255 then CurChar.SelCharSet := mv;
                              Break;
                            End;
                      'P' : Begin
                              CurChar.Color:=GetColor(CurChar.Color);
                              Break;
                            End;
                      'A' : Begin 
                              CurChar.Ch := Chr(GetChar);
                              Break;
                              End;
                      'D' : Begin
                              SetTextAttr(7);
                              mv :=  GetDrawMode(DrawMode);;
                              If mv <> 255 then DrawMode := mv;
                              Break;
                            End;
                      'E' : Begin
                              GBExtract(Layer[curlayer]);
                              Break;
                            End;
                      'N' : Begin
                              NESExtract(Layer[curlayer]);
                              Break;
                            End;
                      'G' : Begin
                              Global(Layer[curlayer]);
                              Edit;
                              Break;
                            End;
                    Else
                      MenuPosition := 0;
                    End;
                End;
          6 : Begin
                  BoxOpen (optionsx-1, 2, optionsx+optionsw, 11);
                  CoolBoxOpen (optionsx, ' Options ');
                  Menu.AddNone ('T', ' Edit Tab            ' , optionsx, 3, 22, 'Edit TAB Spaces');
                  Menu.AddNone ('C', ' Save To Cursor '      , optionsx, 4, 22, 'Save File up to Cursor Position');
                  Menu.AddNone ('P', ' PGKeys Change Layers' , optionsx, 5, 22, 'Change PGUP/PGDOWN Keys Behavior');
                  Menu.AddNone ('E', ' Set Transparent Char' , optionsx, 6, 22, 'Select Char for Transparency');
                  Menu.AddNone ('N', ' Set Transparent Attr' , optionsx, 7, 22, 'Select Color for Transparency');
                  Menu.AddNone ('G', ' Get Trans Ch. & Attr' , optionsx, 8, 22, 'Select Char/Color Under Cursor for Transparency');
                  Menu.AddNone ('B', ' Block Cursor        ' , optionsx, 9, 22, 'Use Block Style Cursor (Windows only)');
                  Menu.AddNone ('U', ' Underl.Cursor       ' , optionsx, 10, 22, 'Use Underlying Style Cursor (Windows Only)');
                  
      
                  Res := Menu.Execute;
      
                  BoxClose;
                  CoolBoxClose;
      
                  If Menu.WasHiExit Then Begin
                    Case Res of
                      #75 : MenuPosition := 5;
                      #77 : MenuPosition := 7;
                    End;
                  End Else
                    Case Res of
                      'G' : GetTransAt(CurChar.OldX,CurChar.OldY,Curlayer);
                      #27 : Begin
                              Menuposition:=0;
                              Break;
                            End;
                      'B' : Begin
                              CursorBlock;
                              Break;
                            End;
                      'U' : Begin
                              HalfBlock;
                              Break;
                            End;
                      'E' : Begin
                              mv:=GetChar(Ord(Settings.TransChar));
                              if mv<>0 Then Settings.TransChar:=Chr(mv);
                            End;
                      'N' : Begin
                              Settings.TransAttr:=GetColor(Settings.TransAttr);
                            End;
                      'P' : Begin
                              Settings.PGKeys:=Not Settings.PGKeys;
                              If Settings.PGKeys Then
                                ShowMsgBox(0,'Page Up/Down will change layers')
                              Else
                                ShowMsgBox(0,'Page Up/Down returned to normal')
                            End;
                      'T' : EditTabs;
                      'C' : Begin
                              If ShowMsgBox(1,'Save to Cursor Position?') Then
                                CurChar.SaveCur := True 
                              Else
                                CurChar.SaveCur := False;
                              blockart_save.SaveCur := CurChar.SaveCur;
                            End;
                    Else
                      MenuPosition := 0;
                    End;
                End;
          
          7 : Begin
                  BoxOpen (helpx-1, 2, helpx+helpw, 5);
                  CoolBoxOpen (helpx,' Help ');
      
                  Menu.AddNone ('A', ' About ', helpx, 3, helpw, 'About BlockArt');
                  Menu.AddNone ('H', ' Help ' , helpx, 4, helpw, 'Key Shortcuts and other...');
      
                  Res := Menu.Execute;
      
                  BoxClose;
                  CoolBoxClose;
      
                  If Menu.WasHiExit Then Begin
                    Case Res of
                      #75 : MenuPosition := 6;
                      #77 : MenuPosition := 1;
                    End;
                  End Else
                    Case Res of
                      #27 : Begin
                              Menuposition:=0;
                              Break;
                            End;
                      'A' : Begin
                              AboutBox;
                              Break;
                            End;
                      'H' : Begin
                              SHowHelp;
                              Break;
                            End;
                    Else
                      MenuPosition := 0;
                    End;
                End;
          
          End;
          
          Until False;
          If RestoreScreen Then Begin
            //xcrt.RestoreScreen(MainImage);
            Paste2Screen(Layer[CurLayer]);
            GotoXY(CurChar.OldX,CurChar.OldY);
          End;
        End;  
        
      End;
    If ShowStatusBar Then StatusBar;
    End;
  
  Until False;

  ClrScr;
  Menu.Free;
  SaveSettings;
  DeleteUndoFiles;
  Screen.Free;
  Keyboard.Free;
End.
