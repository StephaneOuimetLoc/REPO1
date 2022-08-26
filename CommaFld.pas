//CR14785   JCD       2019/05/09 Correction of numbers from 20 to 29 in spanish
//CR14990   Stephan   2019/04/12 Fix Spanish typo

unit CommaFld;

interfaceX111111111111

  Function GetFieldFromString(buf: AnsiString;Fld:Integer;var len:Integer):Integer; Overload;
  Function GetFieldFromString(buf: String; Fld:Integer; var len:Integer):Integer; Overload;
  Function NumberInWords (TheNumber : Integer): String;
  Function NumberInWordsFr(TheNumber: Integer): String;
  Function NumberInWordsEs(TheNumber: Integer): String;

implementation

{ Scan 'buf' to find the field number 'fld' (from 1 to nn)
	returns the position of the first byte of that
	field, or 0 if field number not found		}

Uses System.SysUtils{, System.AnsiStrings};

Function GetFieldFromString(buf:AnsiString; Fld:Integer; var len:Integer):Integer;
var
ln:Integer;
ln2:Integer;

begin
ln := Length(buf);
{$IFDEF WIN64}



{$ELSE}
asm
		push	ebx
		push	edi
		mov	ecx,ln			{ Number of bytes to check }
		mov  	edi,Fld			{ Field number wanted }
		mov	ebx,buf			{ String of all fields }
		mov	edx,1				{ Position within the string }

		inc	edi				{ Check if fld# is 0	}
		dec	edi				{ Make it sound like it's fld 1 }
		jz		@Found

		dec	edi
		jz		@Found			{ Were looking for the very first field }
		inc	ecx
		dec	ecx
		jz		@NotFound		{ Blank string }

@again:
		mov	al,byte [ebx]
		cmp	al,' '			{ Skip blanks }
		jnz	@nextb
		inc	ebx
		inc	edx
		loop	@again
		jmp	@NotFound

@nextb:
		mov	ah,al				{ Remember if it's single or double quote }
		cmp	al,'"'   		{ Double quoted string }
		jz		@more1
		cmp	al,''''			{ Single quoted string }
		jz		@more1
		jmp	@NoQuote

{Single or double quote here }
@more1:
		inc	ebx
		inc	edx
		dec	ecx
		jz		@NotFound		{ End of buffer too soon }
@waitEnd:
		mov	al,byte [ebx]
		cmp	al,ah
		jnz   @more1			{ Keep looking for the quote }

		inc	ebx      		{ OK, we got it...		}
		inc	edx
		dec	ecx
		jz		@NotFound      { But there is no more byte to check }

		mov	al,byte [ebx]
		cmp	al,','			{ Is next byte a commas? }
		jz		@Scommas			{ Yes, then it's ok	}
		jmp	@WaitEnd			{ No, then keep checking }

{ Just to the next commas here }
@NoQuote:
		mov	al,byte [ebx]
		cmp	al,','
		jz		@Scommas
		inc	ebx
		inc	edx
		dec	ecx
		jz		@NotFound
		jmp	@noQuote

{ Now we are at the commas }
@SCommas:
		inc	ebx
		inc	edx
		dec	ecx
		jz		@ChkIfLast		{ Buffer empty now }
		dec	edi				{ Field count. Are we there yet? }
		jz		@Found			{ YES... Finally! }
		jmp	@Again			{ No... Well... keep looking }
@ChkIfLast:
		dec	edi				{ Were we at the end enyway? }
		jz		@found			{ Yes.  Empty last field then }
		jmp	@NotFound

@Found:                     { Here we are at the begining of the wanted field }
		mov	eax,edx
		mov	@result,eax		{ Remember the start }
		mov	edx,0				{ Prepare the count of the length }
		inc	ecx				{ Check if not already at the end }
		dec	ecx
		jz		@len001			{ Yes, so len = 0 }

		mov	al,byte [ebx]	{ Is it a quote?	}
		mov	ah,al				{ Preserve the quote	}
		cmp	al,''''
		jz		@len102			{ Yes,, go wait for the other one }
		cmp	al,'"'			{ A double quote?	}
		jz		@len102			{ Yes, then do the same }

{Just wait for the next commas }
@len002:
		mov	al,byte [ebx]
		cmp	al,','			{ Is next byte a quote? }
		jz		@len001			{ Yes, then it's ok	}
		inc	ebx
		inc	edx
		dec	ecx				{ End of buffer yet? }
		jz		@len001			{ Yes... so that must be the length }
		jmp	@len002

{Wait for single quote followed by a commas }
@len100:
		mov	al,byte [ebx]	{ ah is a single or double quote }
		cmp	al,ah				{ Is next byte a quote? }
		jz		@len101			{ Yes, then go check if commas }
@len102:
		inc	ebx
		inc	edx				{ Our counter }
		dec	ecx
		jz		@len001			{ Reached the end anyway }
		jmp	@len100
@len101:
		inc	ebx
		inc	edx
		dec	ecx
		jz		@len001			{ The end of buffer }
		mov	al,byte [ebx]
		cmp	al,','			{ Is there a commas ? }
		jz		@len001			{ Yes, got it			}
		jmp	@len100

{ OK, edx is the length of the wanted field }
@len001:
		mov	ln2,edx
		jmp	@cont2
@NotFound:
		mov	eax, 0
@cont:
		mov	@result, eax
@cont2:
		pop	edi
		pop	ebx
end;
{$ENDIF}
len:=ln2;
end;

{*** Return the first position of the desired field and the length of the field ***}

Function GetFieldFromString(buf: String; Fld:Integer; var len:Integer):Integer;
var
  c: Char;
  ln:Integer;
  ln2:Integer;
  iLen:Integer; {Maximum length of the buf}
  iSt:Integer;  {First character position of the desired field number}
  iSp:Integer;  {Position in the string}
  bTxt:Byte;    {Let know if it's a text field (begin by an apostrophe)}
  iFld:integer; {Field number currently search the end position}

begin
{$IFDEF WIN64}
  iSt:=1;
  iFld:=fld;
  iSp:=1;
  iLen:=length(buf);
  bTxt:=0;
  Repeat
    while (iSp<=iLen) and ((buf[iSp]<>',') or (bTxt<>0)) do
     begin
       if (bTxt<>2) and (buf[iSp]='''') then
        begin
          if (iSt=iSp) and (bTxt=0) then 
           bTxt:=1 else
          if (iSp<iLen) and ((buf[iSp]=buf[iSp+1]) or (buf[iSp+1]<>',')) then
           Inc(iSp) else
           bTxt:=0;
        end
       else
       if (bTxt<>1) and (buf[iSp]='"') then
        begin
          if (iSt=iSp) and (bTxt=0) then
           bTxt:=2 else
           bTxt:=0;
        end;
       Inc(iSp);
     end;
    Dec(iFld);
    Inc(iSp);
    if iFld>0 then iSt:=iSp;
  Until iFld=0;

  len:=iSp-iSt-1;
  if iSt>iLen then
   begin
     iSt:=0;
     len:=0;
   end;
  Result:=iSt;

{$ELSE}
  ln := Length(buf);
asm
		push	ebx
		push	edi
		mov	 ecx,ln			{ Number of bytes to check }
		mov  edi,Fld		{ Field number wanted }
		mov	 ebx,buf		{ String of all fields }
		mov	 edx,1				{ Position within the string }

		inc	 edi				{ Check if fld# is 0	}
		dec	 edi				{ Make it sound like it's fld 1 }
		jz		 @Found

		dec	 edi
		jz		 @Found			{ Were looking for the very first field }
		inc	 ecx
		dec	 ecx
		jz		 @NotFound		{ Blank string }

@again:
		mov	 ax,word [ebx]
		cmp	 ax,' '			{ Skip blanks }
		jnz	 @nextb
		inc	 ebx
  inc  ebx
		inc	 edx
		loop	@again
		jmp	 @NotFound

@nextb:
		mov	 c,ax			  	{ Remember if it's single or double quote }
		cmp	 ax,'"'   		{ Double quoted string }
		jz		 @more1
		cmp	 ax,''''			{ Single quoted string }
		jz		 @more1
		jmp	 @NoQuote

{Single or double quote here }
@more1:
		inc	 ebx
  inc  ebx
		inc	 edx
		dec	 ecx
		jz		 @NotFound		{ End of buffer too soon }
@waitEnd:
		mov	 ax,word [ebx]
		cmp	 ax,c
		jnz  @more1			{ Keep looking for the quote }

		inc 	ebx      		{ OK, we got it...		}
  inc  ebx
		inc	 edx
		dec 	ecx
		jz		 @NotFound      { But there is no more byte to check }

		mov 	al,byte [ebx]
		cmp	 al,','			{ Is next byte a commas? }
		jz	 	@Scommas			{ Yes, then it's ok	}
		jmp	 @WaitEnd			{ No, then keep checking }

{ Just to the next commas here }
@NoQuote:
		mov	 ax,word [ebx]
		cmp	 ax,','
		jz		 @Scommas
		inc	 ebx
  inc  ebx
		inc	 edx
		dec	 ecx
		jz		 @NotFound
		jmp	 @noQuote

{ Now we are at the commas }
@SCommas:
		inc	 ebx
  inc  ebx
		inc	 edx
		dec	 ecx
		jz		 @ChkIfLast		{ Buffer empty now }
		dec	 edi				{ Field count. Are we there yet? }
		jz		 @Found			{ YES... Finally! }
		jmp	 @Again			{ No... Well... keep looking }
@ChkIfLast:
		dec	 edi				{ Were we at the end enyway? }
		jz		 @found			{ Yes.  Empty last field then }
		jmp	 @NotFound

@Found:                     { Here we are at the begining of the wanted field }
		mov	 eax,edx
		mov	 @result,eax		{ Remember the start }
		mov	 edx,0				{ Prepare the count of the length }
		inc	 ecx				{ Check if not already at the end }
		dec	 ecx
		jz		 @len001			{ Yes, so len = 0 }

		mov	 ax,word [ebx]	{ Is it a quote?	}
		mov	 c,ax				{ Preserve the quote	}
		cmp	 ax,''''
		jz		 @len102			{ Yes,, go wait for the other one }
		cmp	 ax,'"'			{ A double quote?	}
		jz		 @len102			{ Yes, then do the same }

{Just wait for the next commas }
@len002:
		mov	 ax,word [ebx]
		cmp	 ax,','			{ Is next byte a quote? }
		jz		 @len001			{ Yes, then it's ok	}
		inc	 ebx
  inc  ebx
		inc	 edx
		dec	 ecx				{ End of buffer yet? }
		jz		 @len001			{ Yes... so that must be the length }
		jmp	 @len002

{Wait for single quote followed by a commas }
@len100:
		mov	 ax,word [ebx]	{ ah is a single or double quote }
		cmp	 ax,c				{ Is next byte a quote? }
		jz		 @len101			{ Yes, then go check if commas }
@len102:
		inc	 ebx
  inc  ebx
		inc	 edx				{ Our counter }
		dec	 ecx
		jz		 @len001			{ Reached the end anyway }
		jmp	 @len100
@len101:
		inc	 ebx
  inc  ebx
		inc	 edx
		dec	 ecx
		jz		 @len001			{ The end of buffer }
		mov	 ax,word [ebx]
		cmp	 ax,','			{ Is there a commas ? }
		jz		 @len001			{ Yes, got it			}
		jmp	 @len100

{ OK, edx is the length of the wanted field }
@len001:
		mov	 ln2,edx
		jmp	 @cont2
@NotFound:
		mov	 eax, 0
@cont:
		mov	 @result, eax
@cont2:
		pop	 edi
		pop	 ebx
end;
len:=ln2;
{$ENDIF}
end;


{---------------------------------------------}
{	Entry:	Buf:	 		is the commas delimited string
				OutStr:		is the returned field
				FldNumber: 	is the field number to get from buf

	Returns:	True if field not found
}

Function GetField(Buf:String;var OutString:String; FldNumber:Integer):Boolean;
var
i, i3:Integer;

Begin
  i := GetFieldFromString(buf, FldNumber, i3);
  GetField := True;
  if i = 0 then exit;		{ Field not found }
  GetField := False;
  OutString := copy(buf, i, i3);
End;

{---------------------------------------------}
{	Same as GetField function except that the
	field is returned without the quoted
}

Function GetCleanField(Buf:String;var OutString:String; FldNumber:Integer):Boolean;
begin
  GetCleanField := True;
  if GetField(buf, OutString, FldNumber) then exit;
  GetCleanField := False;
  if Length(OutString) > 1 then
   if ((OutString[1] = '''') and (outString[Length(OutString)] = ''''))
      or ((OutString[1] = '"') and (outString[Length(OutString)] = '"')) then
     OutString := Copy(OutString, 2, Length(OutString)-2);
end;


{*****NUMBER AS LETTERS *****************************************}

{*** ENGLISH *********************************************************}

Const
  Digits : Array [1..9] Of String = (
    'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine'
    );

  Teens : Array [1..9] Of String = (
    'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen'
    );

  TenTimes : Array [1..9] Of String = (
    'ten', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety'
    );

Function DoTriplet (TheNumber : Integer) : String;
Var
  Digit, Num : Integer;
Begin
  Result := '';
  Num := TheNumber Mod 100;
  If (Num > 10) And (Num < 20) Then Begin
    Result := Teens [Num - 10];
    Num := TheNumber Div 100;
  End
  Else Begin
    Num := TheNumber;
    Digit := Num Mod 10;
    Num := Num Div 10;
    If Digit > 0 Then Result := Digits [Digit];
    Digit := Num Mod 10;
    Num := Num Div 10;
    If Digit > 0 Then Result := TenTimes [Digit] + ' ' + Result;
    Result := Trim (Result);
  End;
  Digit := Num Mod 10;
  If (Result <> '') And (Digit > 0) Then Result := 'and ' + Result;
  If Digit > 0 Then Result := Digits [Digit] + ' hundred ' + Result;
  Result := Trim (Result);
End;

Function NumberInWords (TheNumber : Integer) : String;
Var
  Num, Triplet, Pass : Integer;
Begin
  If TheNumber < 0 Then Result := 'Minus ' + NumberInWords (-TheNumber)
  Else Begin
    Result := '';
    Num := TheNumber;
    If Num > 999999999 Then
      Raise Exception.Create('Can''t express more than 999,999,999 in words');
    For Pass := 1 To 3 Do Begin
      Triplet := Num Mod 1000;
      Num := Num Div 1000;
      If Triplet > 0 Then Begin
        If (Pass > 1) And (Result <> '') Then Result := ', ' + Result;
        Case Pass Of
          2 : Result := ' thousand' + Result;
          3 : Result := ' million' + Result;
        End;
        Result := Trim (DoTriplet (Triplet) + Result);
      End;
    End;
  End;
End;


{*** FRANCAIS *********************************************************}

Const
  Cvingt : Array [0..19] Of String = (
    '', 'un', 'deux', 'trois', 'quatre', 'cinq', 'six', 'sept', 'huit', 'neuf', 'dix',
    'onze', 'douze', 'treize', 'quatorze', 'quinze', 'seize', 'dix-sept', 'dix-huit', 'dix-neuf');

  Ccent : Array [2..9] Of String = ('vingt', 'trente', 'quarante', 'cinquante',
    'soixante', 'soixante', 'quatre-vingt', 'quatre-vingt');

Procedure a_cent (chiff1, chiff2 : Word; Var sCent : String);
Var
  x10, prem, dern : Word;
Begin
  x10 := 10 * chiff1 + chiff2;
  prem := chiff1;
  dern := chiff2;
  If x10 <= 19 Then insert (Cvingt [x10], sCent, 1)
  Else If prem In [7, 9] Then Begin
    If dern <> 0 Then Begin
      insert (Cvingt [dern + 10], sCent, 1);
      If dern In [1] Then Begin
        If prem <> 9 Then insert (' et ', sCent, 1) Else insert ('-', sCent, 1);
      End
      Else insert ('-', sCent, 1);
      insert (Ccent [prem], sCent, 1);
    End
    Else insert (Ccent [prem] + '-' + Cvingt [dern + 10], sCent, 1);
  End
  Else { if not prem in [7,9] }  Begin
    If dern <> 0 Then insert (Cvingt [dern], sCent, 1);
    If dern = 0 Then If prem = 8 Then insert ('s', sCent, 1);
    Begin
      If dern = 1 Then Begin
        If prem <> 8 Then insert (' et ', sCent, 1) Else insert ('-', sCent, 1)
      End;
      If dern In [2..9] Then insert ('-', sCent, 1);
    End;
    insert (Ccent [prem], sCent, 1);
  End;
End;

Function NumberInWordsFr(TheNumber : Integer) : String;
Var
  s, strn : String;
  res : Integer;
  p, c1, c2, c3, nc, i : Word;
  chiff : Array [0..9] Of Byte;
Begin
  For i := 0 To 9 Do chiff [i] := 0;
  Result := '';

  str (TheNumber:0, strn);
  val (strn, TheNumber, res);
  nc := Length (strn);
  For i := 1 To nc Do Begin
    s := strn [i];
    val (s, chiff [i], res);
  End;
  If TheNumber = 0 Then Result := 'zéro'
  Else If nc = 1 Then Result := Cvingt [chiff [nc]]
  Else If nc > 1 Then Begin
    a_cent (chiff [nc - 1], chiff [nc], Result);
    c1 := 0;
    {c2 := 0;  Hint Value assigned to c2 never used Andy Preston 19-Oct-1999 }
    If nc >= 3 Then Begin
      c2 := chiff [nc - 2];
      If (Result = '') And (c2 > 1) Then insert ('s', Result, 1)
      Else
        insert (' ', Result, 1);
      If c2 > 0 Then insert (' cent', Result, 1);
      If c2 > 1 Then a_cent (c1, c2, Result);
    End;
    If nc >= 4 Then Begin
      c1 := 0;
      c2 := 0;
      c3 := 0;
      If nc <= 4 Then c3 := chiff [nc - 3];
      If nc > 4 Then Begin
        c2 := chiff [nc - 4];
        c3 := chiff [nc - 3];
      End;
      If nc >= 5 Then c1 := chiff [nc - 5];
      insert (' ', Result, 1);
      If c1 * 100 + c2 * 10 + c3 > 0 Then insert (' mille', Result, 1);
      If c2 * 10 + c3 > 1 Then a_cent (c2, c3, Result);
      If c1 > 0 Then Begin
        insert (' cent ', Result, 1);
        If c1 > 1 Then insert (Cvingt [c1], Result, 1);
      End;
    End;
    If nc >= 7 Then Begin
      c1 := 0;
      c2 := 0;
      c3 := 0;
      If nc <= 7 Then c3 := chiff [nc - 6];
      If nc > 7 Then Begin
        c2 := chiff [nc - 7];
        c3 := chiff [nc - 6];
      End;
      If nc >= 8 Then c1 := chiff [nc - 8];
      insert (' ', Result, 1);
      If c1 * 100 + c2 * 10 + c3 > 1 Then insert ('s', Result, 1);
      If c1 * 100 + c2 * 10 + c3 > 0 Then insert (' million', Result, 1);
      a_cent (c2, c3, Result);
      If c1 > 0 Then Begin
        insert (' cent ', Result, 1);
        If c1 > 1 Then insert (Cvingt [c1], Result, 1);
      End;
    End;
    If nc >= 10 Then Begin
      c1 := 0;
      c2 := 0;
      c3 := 0;
      If nc <= 10 Then c3 := chiff [nc - 9];
      If nc > 10 Then Begin
        c2 := chiff [nc - 10];
        c3 := chiff [nc - 9];
      End;
      If nc >= 11 Then c1 := chiff [nc - 11];
      insert (' ', Result, 1);
      If c1 * 100 + c2 * 10 + c3 > 1 Then insert ('s', Result, 1);
      If c1 * 100 + c2 * 10 + c3 > 0 Then insert (' milliard', Result, 1);
      a_cent (c2, c3, Result);
      If c1 > 0 Then Begin
        insert (' cent ', Result, 1);
        If c1 > 1 Then insert (Cvingt [c1], Result, 1);
      End;
    End;
  End;

  Repeat
    p := Pos ('  ', Result);
    If p <> 0 Then delete (Result, p, 1);
  Until p = 0;
  If Result [Length (Result)] = ' ' Then Result := Copy (Result, 1, Length (Result) - 1);
  If Result [1] = ' ' Then Result := Copy (Result, 2, Length (Result));
End;

{*** SPANISH *********************************************************}

Const
  Cu : Array [1..15] Of String = (
    'UN', 'DOS', 'TRES', 'CUATRO', 'CINCO', 'SEIS', 'SIETE', 'OCHO', 'NUEVE', 'DIEZ', 'ONCE',
    'DOCE', 'TRECE', 'CATORCE', 'QUINCE');

  Cd : Array [1..9] Of String = (
    'DIEZ', 'VEINTE', 'TREINTA', 'CUARENTA', 'CINCUENTA', 'SESENTA', 'SETENTA', 'OCHENTA', 'NOVENTA');

  Cc : Array [1..9] Of String = (
//CR14990 {
    'CIEN', 'DOSCIENTOS', 'TRECIENTOS', 'CUATROCIENTOS', 'QUINIENTOS', 'SEISCIENTOS', 'SETECIENTOS', 'OCHOCIENTOS', 'NOVECIENTOS');
//CR14990 }

Function AnyStrToInt(sLine:String): Integer;
Var
  i1,i2:Integer;
begin
  Val(sLine,i1,i2);
  AnyStrToInt:=i1;
end;

Function NumberInWordsEs(TheNumber:Integer) : String;
Var
  s1,sPacket,sChk,sNumber : String;
  iThousand,iDigit : Integer;
//CR14785 {  
  sign:String;
//CR14785 }  
Begin
//CR14785 {
  sign:='';
  if TheNumber<0 then sign:='-';
//CR14785 }  
  Result:='';
  sPacket:='';
  sChk:='';
//CR14785 {  
  sNumber:='            '+IntToStr(abs(TheNumber));
//CR14785 }  
  sNumber:=Copy(sNumber,Length(sNumber)-11,12);

  iThousand:=1;
  iDigit:=Length(sNumber)-2;

  while (iDigit>=0) do
   Begin
     {Loop by 3 digits packet}
     if (Trim(Copy(sNumber,iDigit,3))<>'') then
      begin
        s1:=Copy(sNumber,iDigit,3);
        if (AnyStrToInt(Copy(s1,1,1))<>0) then
         Begin
           sPacket:=Cc[AnyStrToInt(Copy(s1,1,1))];
           if ((Copy(s1,1,1)='1') and (AnyStrToInt(Copy(s1,2,2))<>0)) then
            sPacket:=sPacket+'TO';
         End;
        if ((AnyStrToInt(Copy(s1,2,2))<16) and (AnyStrToInt(Copy(s1,2,2))<>0)) then
         sPacket:=sPacket+' '+Cu[AnyStrToInt(Copy(s1,2,2))]
        else if (AnyStrToInt(Copy(s1,2,1))<>0) then
         Begin
           sPacket:=sPacket+' '+Cd[AnyStrToInt(Copy(s1,2,1))];
//CR14785 {		   
           if ((AnyStrToInt(Copy(s1,3,1))<>0) and (Pos('VEINTE',sPacket)<=0)) then
            sPacket:=sPacket+' Y '+Cu[AnyStrToInt(Copy(s1,3,1))]
           else
            if (AnyStrToInt(Copy(s1,3,1))<>0) then sPacket:=sPacket+Cu[AnyStrToInt(Copy(s1,3,1))];
//CR14785 }			
         End;

       {Fix UNO}
       if (iThousand=1) and (AnyStrToInt(Copy(s1,3,1))=1) and (AnyStrToInt(Copy(s1,2,2))<>11) then
        sPacket:=sPacket+'O';

       if (iThousand=2) and (AnyStrToInt(s1)<>0) then
        Begin
          sPacket:=sPacket+' MIL ';
          if (AnyStrToInt(s1)=1) then
           sPacket:=' MIL ';
        End;

        if (iThousand=3) then
         Begin
           if (AnyStrToInt(s1)=1) then
            sPacket:=sPacket+' MILLON '
           else sPacket:=sPacket+' MILLONES '
         End;

        if (iThousand=4) then
         Begin
           if (AnyStrToInt(s1)=1) then
            sPacket:=' MIL '
           else sPacket:=sPacket+' MIL '
         End;
      End;

     iThousand:=iThousand+1;
     iDigit:=iDigit-3;
     sChk:=sPacket+sChk;
     sPacket:='';
   End;
//CR14785 {   
  Result:=sign+sChk;
//CR14785 }  
End;

end.

