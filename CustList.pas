
unit CustList;

interface

uses
  Classes, SysUtils, Windows;

type
  TNotifyEvent = procedure(Sender: TObject) of object;
  { RTFM VCL Manual }

type
  TItem = record
    Data: pointer;
    Size: integer;
  end;

type
  TCustList = class(TList)  
  private
    FOnChange: TNotifyEvent;
    FCapacity: integer; 
  protected
    function    Get_Item(const Index: integer): TItem; 
    procedure   Set_Item(const Index: integer; const Item: TItem); 

//    function    Extract(Item: pointer): pointer; virtual; abstract;
//    function    Expand: TList; virtual; abstract;
//    procedure   Sort(Compare: TListSortCompare); virtual; abstract;
    property    List; 
  public
    constructor Create; 
    function    Add(const Data; const Size: integer): integer;
    procedure   Insert(const Index: integer; const Data; const Size: integer);
    procedure   Delete(const Index: integer);
    procedure   Clear; override; 
    procedure   GetItem(const Index: integer; var Data; var Size: integer);
    procedure   GetData(const Index: integer; var Data);
    function    GetSize(const Index: integer): integer; 
    procedure   SetItem(const Index: integer; const Data; const Size: integer);
    function    First: TItem; 
    function    Last: TItem; 
    function    IndexOf(const Item: TItem): integer; 
    function    Remove(const Item: TItem): integer; 
    procedure   Pack; 

    property    Items[const Index: integer]: TItem read Get_Item write Set_Item; default; 
    property    Capacity: integer read FCapacity;

    property    OnChange: TNotifyEvent read FOnChange write FOnChange default nil; 
  end;

type
  EFileReadError = class(Exception); // ошибка чтения файла
  EFileWriteError = class(Exception); // ошибка записи файла

type
  TStrList = class(TList) // лист строк
  private
    FEolStr, // см. ниже
    FIgnoreEolChars: string; // см. ниже
    FCapacity: dword; // общая длина строк
    FOnChange: TNotifyEvent; // RTFM TList
    function    TrimChars(const Text, Chars: string): string; // удаляет из границ Text все символы Chars, RTFM Trim()
  protected
    function    Get_Item(const Index: integer): string; // см. ниже
    procedure   Set_Item(const Index: integer; const Item: string); // см. ниже
    function    Get_Text: string; // см. ниже
    procedure   Set_Text(const Text: string); // см. ниже
    function    Get_Length: dword; // см. ниже
    procedure   Set_EolStr(const EolStr: string); // см. ниже
    procedure   Set_IgnoreEolChars(const IgnoreEolChars: string); // см. ниже

//    function    Extract(Item: pointer): pointer; virtual; abstract;
//    function    Expand: TList; virtual; abstract;
    property    List; // RTFM: Object Pascal reference, VCL Manual
  public
    constructor Create; // RTFM Object Pascal reference
    function    Add(const Text: string): integer; // добавить строку
    procedure   Insert(const Index: integer; const Text: string); // вставить строку
    procedure   Delete(const Index: integer); // удалить строку
    procedure   Clear; override; // RTFM: Object Pascal reference, TList
    procedure   Assign(Source: TStrList); // скопировать содержимое из Source
    procedure   Sort(const Descenting, CaseSens: boolean); // сортировать строки
    function    IndexOf(const Text: string; const CaseSens: boolean = true): integer; // найти индекст строки, RTFM TList
    procedure   LoadFromFile(const FileName: string); // загрузить строки из файла
    procedure   SaveToFile(const FileName: string); // сохранить строки в файл

    property    Strings[const Index: integer]: string read Get_Item write Set_Item; default; // массив хранимых строк
    property    Text: string read Get_Text write Set_Text; // контактонация всех хранимых строк, разделенных EolString
    property    Capacity: dword read FCapacity; // общее число сохраненных данных (в байтах)
    property    TextLength: dword read Get_Length; // длина свойства Text, работает гораздо быстрее чем Length(Text);

    property    EolString: string read FEolStr write Set_EolStr; // строка-признак конца строки
    property    IgnoreEolChars: string read FIgnoreEolChars write Set_IgnoreEolChars; // игнорировать символы этой строки если они граничат с EolString
    
    property    OnChange: TNotifyEvent read FOnChange write FOnChange default nil; // RTFM TList
  end;

type
  TIndexRec = record
    Index: integer;
    Data: pointer;
  end;

type
  TEachItemProc = procedure(Sender: TObject; const Data: pointer; const Index: integer) of object;

type
  EIndexListError = class(Exception);

type
  TIndexList = class(TCustList) // TCustList
  private
    FListLock: PRTLCriticalSection;
    function    FindNativeIndex(const Index: integer): integer;
  protected
    function    Get_FirstIndex: integer;
    function    Get_LastIndex: integer;
    function    Get_NextIndex(const CurIndex: integer): integer;
    function    Get_PrevIndex(const CurIndex: integer): integer;

    function    GetLocked: boolean;
    procedure   SetLocked(const Value: boolean);
    procedure   EnterCriticalSection;
    procedure   LeaveCriticalSection;
  public
    constructor Create;
    destructor  Destroy; override;
    function    Add(const Data: pointer): integer;
    procedure   Insert(const Index: integer; const Data: pointer);
    procedure   Delete(const Index: integer);
    function    FirstIndex: integer;
    function    LastIndex: integer;
    function    NextIndex(const CurIndex: integer): integer;
    function    PrevIndex(const CurIndex: integer): integer;
    procedure   Clear; override;
    function    GetItem(const Index: integer): pointer;
    procedure   SetItem(const Index: integer; const Data: pointer);
    procedure   ForEachItemDo(const EachItemProc: TEachItemProc);
    function    IndexExists(const Index: integer): boolean;
    property    Items[const Index: integer]: Pointer read GetItem write SetItem; default;

    property    Locked: boolean read GetLocked write SetLocked default false;
  end;


implementation

///////////////////////////// TCustList /////////////////////////

type
  PItem = ^TItem;

constructor TCustList.Create;
begin
  inherited Create;
  FOnChange:= nil;
  FCapacity:= 0;
end;

function TCustList.Add(const Data; const Size: integer): integer;
var
  Item: PItem;
begin
  new(Item);
  getmem(Item^.Data, Size);
  system.move(Data, Item^.Data^, Size);
  Item^.Size:= Size;
  Result:= inherited Add(Item);
  inc(FCapacity, Size);
  if assigned(FOnChange) then FOnChange(Self);
end;

procedure TCustList.Insert(const Index: integer; const Data; const Size: integer);
var
  Item: PItem;
begin
  new(Item);
  getmem(Item^.Data, Size);
  system.move(Data, Item^.Data^, Size);
  Item^.Size:= Size;
  inherited Insert(Index, Item);
  inc(FCapacity, Size);
  if assigned(FOnChange) then FOnChange(Self);
end;

procedure TCustList.Delete(const Index: integer);
begin
  if (TItem(inherited Items[Index]^).Data <> nil) and (TItem(inherited Items[Index]^).Size > 0) then
    begin
      freemem(TItem(inherited Items[Index]^).Data, TItem(inherited Items[Index]^).Size);
      dec(FCapacity, TItem(inherited Items[Index]^).Size);
    end;
  dispose(PItem(inherited Items[Index]));
  inherited Delete(Index);
  if assigned(FOnChange) then FOnChange(Self);
end;

procedure TCustList.Clear;
var
  i: integer;
begin
  for i:= 0 to inherited Count-1 do
    begin
      if (TItem(inherited Items[i]^).Data <> nil) and (TItem(inherited Items[i]^).Size > 0) then
        freemem(TItem(inherited Items[i]^).Data, TItem(inherited Items[i]^).Size);
      dispose(PItem(inherited Items[i]));
    end;
  inherited Clear;
  FCapacity:= 0;
  if assigned(FOnChange) then FOnChange(Self);
end;

function TCustList.First: TItem;
begin
  Result:= TItem(inherited First^);
end;

function TCustList.Last: TItem;
begin
  Result:= TItem(inherited Last^);
end;

function TCustList.IndexOf(const Item: TItem): integer;
var
  i: integer;
begin
  Result:= -1;
  i:= inherited Count-1;
  while i >= 0 do
    if (TItem(inherited Items[i]^).Data = Item.Data) and (TItem(inherited Items[i]^).Size = Item.Size) then
      begin
        Result:= i;
        i:= -1;
      end
    else
      dec(i);
end;

function TCustList.Remove(const Item: TItem): integer;
begin
  Result:= IndexOf(Item);
  if Result <> -1 then Delete(Result);
end;

procedure TCustList.Pack;
var
  i: integer;
begin
  i:= 0;
  while i < Count do
    if (Items[i].Data = nil) or (Items[i].Size = 0) then
      Delete(i)
    else
      inc(i);  
end;

procedure TCustList.GetItem(const Index: integer; var Data; var Size: integer);
begin
  GetData(Index, Data);
  Size:= GetSize(Index);
end;

procedure TCustList.GetData(const Index: integer; var Data);
begin
  system.Move(TItem(inherited Items[Index]^).Data, Data, TItem(inherited Items[Index]^).Size);
end;

function TCustList.GetSize(const Index: integer): integer;
begin
  Result:= TItem(inherited Items[Index]^).Size;
end;

function TCustList.Get_Item(const Index: integer): TItem;
begin
  Result:= TItem(inherited Items[Index]^);
end;

procedure TCustList.Set_Item(const Index: integer; const Item: TItem);
begin
  freemem(TItem(inherited Items[Index]^).Data, TItem(inherited Items[Index]^).Size);
  TItem(inherited Items[Index]^).Size:= Item.Size;
  getmem(TItem(inherited Items[Index]^).Data, TItem(inherited Items[Index]^).Size);
  system.Move(Item.Data^, TItem(inherited Items[Index]^).Data^, TItem(inherited Items[Index]^).Size);
  if assigned(FOnChange) then FOnChange(Self);
end;

procedure TCustList.SetItem(const Index: integer; const Data; const Size: integer);
begin
  freemem(TItem(inherited Items[Index]^).Data, TItem(inherited Items[Index]^).Size);
  TItem(inherited Items[Index]^).Size:= Size;
  getmem(TItem(inherited Items[Index]^).Data, TItem(inherited Items[Index]^).Size);
  system.Move(Data, TItem(inherited Items[Index]^).Data^, TItem(inherited Items[Index]^).Size);
  if assigned(FOnChange) then FOnChange(Self);
end;

///////////////////////////// TStrList //////////////////////////

constructor TStrList.Create;
begin
  inherited Create;
  FEolStr:= #13;
  FIgnoreEolChars:= #10;
  FCapacity:= 0;
end;

function TStrList.Add(const Text: string): integer;
var
  PText: PChar;
begin
  inc(FCapacity, system.length(Text));
  getmem(PText, system.length(Text)+1);
  strpcopy(PText, Text);
  Result:= inherited Add(PText);
  if assigned(FOnChange) then FOnChange(Self);
end;

procedure TStrList.Insert(const Index: integer; const Text: string);
var
  PText: PChar;
begin
  inc(FCapacity, system.length(Text));
  getmem(PText, system.length(Text)+1);
  strpcopy(PText, Text);
  inherited Insert(Index, PText);
  if assigned(FOnChange) then FOnChange(Self);
end;

procedure TStrList.Delete(const Index: integer);
begin
  dec(FCapacity, strlen(inherited Items[Index]));
  freemem(inherited Items[Index], strlen(inherited Items[Index])+1);
  inherited Delete(Index);
  if assigned(FOnChange) then FOnChange(Self);
end;

procedure TStrList.Clear;
var
  i: integer;
begin
  for i:= 0 to inherited Count-1 do
    freemem(inherited Items[i], strlen(inherited Items[i])+1);
  FCapacity:= 0;
  inherited Clear;
  if assigned(FOnChange) then FOnChange(Self);
end;

function TStrList.Get_Item(const Index: integer): string;
begin
  Result:= strpas(inherited Items[Index]);
end;

procedure TStrList.Set_Item(const Index: integer; const Item: string);
var
  PText: PChar;
begin
  dec(FCapacity, strlen(inherited Items[Index]));
  freemem(inherited Items[Index], strlen(inherited Items[Index])+1);
  getmem(PText, system.length(Item)+1);
  strpcopy(PText, Item);
  inherited Items[Index]:= PText;
  inc(FCapacity, system.length(Item));
  if assigned(FOnChange) then FOnChange(Self);
end;

function TStrList.Get_Text: string;
var
  i: integer;
begin
  Result:= '';
  for i:= 0 to inherited Count-1 do
    Result:= Result+strpas(inherited Items[i])+FEolStr;
end;

procedure TStrList.Set_Text(const Text: string);
var
  i, j, Len, EolLen: integer;
begin
  Clear;
  Len:= system.length(Text);
  if Len > 0 then
    begin
      EolLen:= system.length(FEolStr);
      i:= 1;
      repeat
        j:= 0;
        while (i+j <= Len) and (copy(Text, i+j, EolLen) <> FEolStr) do inc(j);
        Add(TrimChars(copy(Text, i, j), FIgnoreEolChars));
        inc(i, j+EolLen);
      until i > Len;
    end;
  if assigned(FOnChange) then FOnChange(Self);
end;

function TStrList.Get_Length: dword;
var
  i: integer;
  EolLen: dword;
begin
  Result:= 0;
  EolLen:= system.length(FEolStr);
  for i:= 0 to inherited Count-1 do
    inc(Result, strlen(inherited Items[i])+EolLen);
end;

procedure TStrList.Set_EolStr(const EolStr: string);
begin
  if EolStr <> '' then FEolStr:= EolStr;
end;

procedure TStrList.Set_IgnoreEolChars(const IgnoreEolChars: string);
var
  i: integer;
begin
  if IgnoreEolChars = '' then
    FIgnoreEolChars:= IgnoreEolChars
  else
    for i:= 1 to Length(IgnoreEolChars) do
      if Pos(IgnoreEolChars[i], FIgnoreEolChars) = 0 then FIgnoreEolChars:= FIgnoreEolChars+IgnoreEolChars[i];
end;

function TStrList.TrimChars(const Text, Chars: string): string;
var
  i, j, b, e: integer;
  IsTrim: boolean;
begin
  IsTrim:= true;
  i:= 1;
  while (i <= Length(Text)) and (IsTrim) do
    begin
      IsTrim:= false;
      j:= 1;
      while j <= Length(Chars) do
        if Text[i] = Chars[j] then
          begin
            IsTrim:= true;
            inc(i);
            j:= Length(Chars)+1;
          end
        else
          inc(j);
    end;
  b:= i;

  IsTrim:= true;
  i:= Length(Text);
  while (i >= 1) and (IsTrim) do
    begin
      IsTrim:= false;
      j:= 1;
      while j <= Length(Chars) do
        if Text[i] = Chars[j] then
          begin
            IsTrim:= true;
            dec(i);
            j:= Length(Chars)+1;
          end
        else
          inc(j);
    end;
  e:= i;

  Result:= Copy(Text, b, e-b+1);
end;

procedure TStrList.Assign(Source: TStrList);
var
  i: integer;
begin
  Clear;
  for i:= 0 to Source.Count-1 do Add(Source.Strings[i]);
end;

procedure TStrList.Sort(const Descenting, CaseSens: boolean);
var
  i, j: integer;
  s1, s2: string;
begin
  for j:= 0 to inherited Count-1 do
    for i:= 0 to inherited Count-2 do
      begin
        if CaseSens then
          begin
            s1:= strpas(inherited Items[i]);
            s2:= strpas(inherited Items[i+1]);
          end
        else
          begin
            s1:= ansiuppercase(strpas(inherited Items[i]));
            s2:= ansiuppercase(strpas(inherited Items[i+1]));
          end;
        if s1 > s2 then
          begin
            if Descenting then inherited Exchange(i, i+1);
          end;
        if s1 < s2 then
          begin
            if not Descenting then inherited Exchange(i, i+1);
          end;
      end;
end;

function TStrList.IndexOf(const Text: string; const CaseSens: boolean = true): integer;
var
  i: integer;
  str: string;
begin
  Result:= -1;
  if CaseSens then
    str:= Text
  else
    str:= ansiuppercase(Text);
  i:= 0;
  while i < inherited Count do
    begin
      if ((CaseSens) and (str = strpas(inherited Items[i]))) or ((not CaseSens) and (str = ansiuppercase(strpas(inherited Items[i])))) then
        begin
          Result:= i;
          i:= inherited Count;
        end
      else
        inc(i);
    end;
end;

procedure TStrList.LoadFromFile(const FileName: string);
var
  f: file;
  Size: integer;
  Data: PChar;
begin
  try
    AssignFile(f, FileName);
    Reset(f, 1);
    Size:= FileSize(f);
    GetMem(Data, Size+1);
    BlockRead(f, Data^, Size);
    CloseFile(f);
    Data[Size]:= #0;
    Self.Text:= StrPas(Data);
    FreeMem(Data, Size+1);
  except
    raise EFileReadError.Create('File read error');
  end;
end;

procedure TStrList.SaveToFile(const FileName: string);
var
  f: file;
begin
  try
    AssignFile(f, FileName);
    Rewrite(f, 1);
    BlockWrite(f, PChar(Self.Text)^, Self.TextLength);
    CloseFile(f);
  except
    raise EFileWriteError.Create('File write error');
  end;
end;

///////////////////////////// TIndexList //////////////////////////////////

constructor TIndexList.Create;
begin
  inherited Create;
  FListLock:= nil;
end;

destructor TIndexList.Destroy;
begin
  SetLocked(false);
  inherited Destroy;
end;

function TIndexList.GetLocked: boolean;
begin
  Result:= (FListLock <> nil);
end;

procedure TIndexList.SetLocked(const Value: boolean);
begin
  if Value <> GetLocked then
    if Value then
      begin
        New(FListLock);
        InitializeCriticalSection(FListLock^);
      end
    else
      begin
        DeleteCriticalSection(FListLock^);
        Dispose(FListLock);
        FListLock:= nil;
      end;
end;

procedure TIndexList.EnterCriticalSection;
begin
  if GetLocked then Windows.EnterCriticalSection(FListLock^);
end;

procedure TIndexList.LeaveCriticalSection;
begin
  if GetLocked then Windows.LeaveCriticalSection(FListLock^);
end;

function TIndexList.FindNativeIndex(const Index: integer): integer;
var
  i: integer;
begin
  Result:= -1;
  i:= Count-1;
  while i >= 0 do
    if TIndexRec(inherited Items[i].Data^).Index = Index then
      begin
        Result:= i;
        i:= -1;
      end
    else
      dec(i);
end;

function TIndexList.Get_FirstIndex: integer;
begin
  if Count > 0 then
    Result:= TIndexRec(First.Data^).Index
  else
    Result:= -1;
end;

function TIndexList.Get_LastIndex: integer;
begin
  if Count > 0 then
    Result:= TIndexRec(Last.Data^).Index
  else
    Result:= -1;
end;

function TIndexList.Get_NextIndex(const CurIndex: integer): integer;
var
  i, j: integer;
begin
  i:= FindNativeIndex(CurIndex);
  if (i = -1) and (Get_FirstIndex < CurIndex) and (CurIndex < Get_LastIndex) then
    begin
      j:= 1;
      while j < Count do
        if (TIndexRec(inherited Items[j-1].Data^).Index < CurIndex) and (CurIndex < TIndexRec(inherited Items[j].Data^).Index) then
          begin
            i:= j-1;
            j:= Count;
          end
        else
          inc(j);
    end;

  if (i = -1) or (CurIndex = Get_LastIndex) then
    Result:= -1
  else
    Result:= TIndexRec(inherited Items[i+1].Data^).Index;
end;

function TIndexList.Get_PrevIndex(const CurIndex: integer): integer;
var
  i, j: integer;
begin
  i:= FindNativeIndex(CurIndex);
  if (i = -1) and (Get_FirstIndex < CurIndex) and (CurIndex < Get_LastIndex) then
    begin
      j:= Count-1;
      while j > 0 do
        if (TIndexRec(inherited Items[j-1].Data^).Index < CurIndex) and (CurIndex < TIndexRec(inherited Items[j].Data^).Index) then
          begin
            i:= j;
            j:= 0;
          end
        else
          Dec(j);
    end;

  if (i = -1) or (CurIndex = Get_FirstIndex) then
    Result:= -1
  else
    Result:= TIndexRec(inherited Items[i-1].Data^).Index;
end;

function TIndexList.Add(const Data: pointer): integer;
var
  IndexRec: TIndexRec;
begin
  EnterCriticalSection;
  try
    Result:= Get_LastIndex+1;
    IndexRec.Index:= Result;
    IndexRec.Data:= Data;
    inherited Add(IndexRec, sizeof(IndexRec));
  finally
    LeaveCriticalSection;
  end;
end;

procedure TIndexList.Delete(const Index: integer);
var
  i: integer;
begin
  EnterCriticalSection;
  try
    i:= FindNativeIndex(Index);
    if i <> -1 then
      inherited Delete(i)
    else
      raise EIndexListError.Create('IndexList index out of bounds ('+inttostr(Index)+')');
  finally
    LeaveCriticalSection;
  end;
end;

procedure TIndexList.Insert(const Index: integer; const Data: pointer);
var
  IndexRec: TIndexRec;
  ExistIndex, i, NativeIndex: integer;
begin
  EnterCriticalSection;
  try
    if Index >= 0 then
      begin
        IndexRec.Index:= Index;
        IndexRec.Data:= Data;
        ExistIndex:= FindNativeIndex(Index);
        if ExistIndex = -1 then
          if Index > Get_LastIndex then
            inherited Add(IndexRec, sizeof(IndexRec))
          else
            if Index < Get_FirstIndex then
              inherited Insert(0, IndexRec, sizeof(IndexRec))
            else
              begin
                i:= Count-1;
                while i >= 1 do
                  if (TIndexRec(inherited Items[i-1].Data^).Index < Index) and (Index < TIndexRec(inherited Items[i].Data^).Index) then
                    begin
                      inherited Insert(i, IndexRec, sizeof(IndexRec));
                      i:= 0;
                    end
                  else
                    dec(i);
              end
        else
          begin
            i:= ExistIndex;
            while i < Count do
              begin
                NativeIndex:= i;
                if FindNativeIndex(TIndexRec(inherited Items[NativeIndex].Data^).Index+1) = -1 then
                  i:= Count
                else
                  inc(i);
                inc(TIndexRec(inherited Items[NativeIndex].Data^).Index);
              end;
            inherited Insert(ExistIndex, IndexRec, sizeof(IndexRec));
          end;
      end
    else
      raise EIndexListError.Create('IndexList index out of bounds (< 0)');
  finally
    LeaveCriticalSection;
  end;
end;

procedure TIndexList.Clear;
begin
  EnterCriticalSection;
  try
    inherited Clear;
  finally
    LeaveCriticalSection;
  end;
end;

function TIndexList.GetItem(const Index: integer): pointer;
var
  i: integer;
begin
  EnterCriticalSection;
  try
    i:= FindNativeIndex(Index);
    if i <> -1 then
      Result:= TIndexRec(inherited Items[i].Data^).Data
    else
      begin
        Result:= nil;
        raise EIndexListError.Create('IndexList index out of bounds ('+inttostr(Index)+')');
      end;  
  finally
    LeaveCriticalSection;
  end;
end;

procedure TIndexList.SetItem(const Index: integer; const Data: pointer);
var
  i: integer;
begin
  EnterCriticalSection;
  try
    i:= FindNativeIndex(Index);
    if i <> -1 then
      TIndexRec(inherited Items[i].Data^).Data:= Data
    else
      raise EIndexListError.Create('IndexList index out of bounds ('+inttostr(Index)+')');
  finally
    LeaveCriticalSection;
  end;
end;

function TIndexList.IndexExists(const Index: integer): boolean;
begin
  EnterCriticalSection;
  try
    Result:= (FindNativeIndex(Index) <> -1);
  finally
    LeaveCriticalSection;
  end;
end;

function TIndexList.LastIndex: integer;
begin
  EnterCriticalSection;
  try
    Result:= Get_LastIndex;
  finally
    LeaveCriticalSection;
  end;
end;

function TIndexList.FirstIndex: integer;
begin
  EnterCriticalSection;
  try
    Result:= Get_FirstIndex;
  finally
    LeaveCriticalSection;
  end;
end;

function TIndexList.NextIndex(const CurIndex: integer): integer;
begin
  EnterCriticalSection;
  try
    Result:= Get_NextIndex(CurIndex);
  finally
    LeaveCriticalSection;
  end;
end;

function TIndexList.PrevIndex(const CurIndex: integer): integer;
begin
  EnterCriticalSection;
  try
    Result:= Get_PrevIndex(CurIndex);
  finally
    LeaveCriticalSection;
  end;
end;

procedure TIndexList.ForEachItemDo(const EachItemProc: TEachItemProc);
var
  i: integer;
begin
  if assigned(EachItemProc) then
    try
      EnterCriticalSection;
      i:= 0;
      while i < Count do
        begin
          EachItemProc(Self, TIndexRec(inherited Items[i].Data^).Data, TIndexRec(inherited Items[i].Data^).Index);
          inc(i);
        end;
    finally
      LeaveCriticalSection;
    end;
end;

end.



