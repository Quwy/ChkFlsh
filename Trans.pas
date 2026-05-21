{ Author: Михаил Черкес
  Summary: Универсальный словарь для перевода строк. }

unit Trans;

interface

uses
  CustList, SysUtils;

type
  TMemIni = class(TStrList) // класс для хранения нужной части словаря в памяти
  private
    FChanging: boolean;
    procedure   OnListChange(Sender: TObject); // RTFM TList.OnChange
  public
    constructor Create; // RTFM Object Pascal reference

    function    GetSectionBase(const Section: string): integer; // возвращает номер строки (а что же еще, блин?), в которой сидит база раздела
    function    IsSectionBase(const Index: integer): boolean; // указанный номер строки содержит базу секции?
    function    GetKeyOffset(const SectionBase: integer; const Key: string): integer; // смещение ключа относительно индекса базы (для непонятливых: в количестве строк)

    function    ReadString(const Section, Key, Default: string): string; // RTFM English
    function    ReadInteger(const Section, Key: string; Default: integer): integer; // RTFM English
    function    SectionExists(const Section: string): boolean; // RTFM English
    function    KeyExists(const Section, Key: string): boolean; // RTFM English
  end;

type
  TLangSelect = (lsSystem, lsUser, lsManual);
  { lsSystem: язык "по умолчанию" для системы;
    lsUser: язык "по умолчанию" для текущего пользователя;
    lsManual: язык указывается в обработчике OnLangSelect;}
  TLangError = (leFileError, leDefaultError);
  { leFileError: не удалось загрузить словарь, ошибка файлового ввода-вывода;
    leDefaultError: актуального словаря в текущем файле нет, а секция "по умолчанию" не назначена;}

type
  TOnLangSelect = procedure(Sender: TObject; var Language: string) of object;
  { Sender: RTFM VCL Manual;
    Language: международное название языка, RTFM API Function GetLocaleInfo();}
  TOnLangError = procedure(Sender: TObject; const ErrorType: TLangError) of object;
  { Sender: RTFM VCL Manual;
    ErrorType: см. TLangError;}

  TOnUnknownText = procedure(Sender: TObject; var Text: string) of object;
  { Sender: RTFM VCL Manual;
    Text: незнакомый текст, пиши вместо него что хочеш!;}

type
  TTranslator = class(TObject) // собственно переводчик
  private
    FDict: TMemIni; // контейнер для словаря
    FLangId: string;
    FLangSelect: TLangSelect; // см. ниже
    FOnLangSelect: TOnLangSelect; // см. ниже
    FOnLangError: TOnLangError; // см. ниже
    FOnUnknownText: TOnUnknownText; // см. ниже
    FFileName: string; // см. ниже
    FAutoReload: boolean; // см. ниже
    procedure   SetFileName(const Value: string); // см. ниже
    procedure   SetLangSelect(const Value: TLangSelect); // см. ниже
  protected
    function    GetLanguageId: string; // возвращает низвание языка согласно текущему значению LangSelectType
  public
    constructor Create; // RTFM Object Pascal reference
    destructor  Destroy; override; // RTFM Object Pascal reference
    procedure   Load; // определить язык и загрузить его словарь из файла FileName
    function    Translate(const Text, DefText: string): string; { 1. ищет текст в загруженном словаре
                                                         2. если не находит, вызывает OnUnknownText()
                                                         3. возвращает либо перевод либо ту же строку
                                                         4. учит мыслить логически }

    property    LanguageID: string read FLangID;
    property    FileName: string read FFileName write SetFileName; // имя файла со словарем
    property    LangSelectType: TLangSelect read FLangSelect write SetLangSelect default lsUser; // способ определения языка, см. TLangSelect
    property    AutoReload: boolean read FAutoReload write FAutoReload default true; // перезагружать словарь из файла автоматически при смене свойств класса?

    property    OnLangSelect: TOnLangSelect read FOnLangSelect write FOnLangSelect default nil; // вызывается после автоопредеоения языка, можно повлиять на выбор, см. TOnLangSelect
    property    OnLangError: TOnLangError read FOnLangError write FOnLangError default nil; // вызывается при ошибке синтаксиса словаря или ввода-вывода файла, см. TOnLangError
    property    OnUnknownText: TOnUnknownText read FOnUnknownText write FOnUnknownText default nil; // вызывается когда текст в словаре не найден, см TOnUnknownText
  end;

implementation

uses
  Windows;

////////////////////////////////////////////////////////////////////////////////

constructor TMemIni.Create;
begin
  inherited Create;
  FChanging:= false;
  Self.OnChange:= OnListChange;
end;

procedure TMemIni.OnListChange(Sender: TObject); // парсинг словарного файла и сохранение в памяти нужной секции
var
  i, l, p: integer;
  s: string;
begin
  if not FChanging then
    try
      FChanging:= true;
      i:= 0;
      while i < Self.Count do
        begin
          s:= Trim(Self[i]);
          l:= Length(s);
          if s <> '' then
            if s[1] <> ';' then
              begin
                if (s[1] = '[') and (s[l] = ']') then
                  begin
                    s:= Trim(Copy(s, 2, l-2));
                    if s <> '' then
                      begin
                        Self[i]:= '['+AnsiUpperCase(s)+']';
                        Inc(i);
                      end
                    else
                      Self.Delete(i);
                  end
                else
                  begin
                    p:= Pos('=', s);
                    if p > 1 then
                      begin
                        Self[i]:= AnsiUpperCase(TrimRight(Copy(s, 1, p-1)))+'='+TrimLeft(Copy(s, p+1, l-p));
                        Inc(i);
                      end
                    else
                      Self.Delete(i);
                  end;
              end
            else
              Self.Delete(i)
          else
            Self.Delete(i);
        end;
    finally
      FChanging:= false;
    end;
end;

function TMemIni.GetSectionBase(const Section: string): integer;
var
  i: integer;
begin
  Result:= -1;
  i:= 0;
  while i < Self.Count do
    if Self[i] = '['+AnsiUpperCase(Trim(Section))+']' then
      begin
        Result:= i;
        i:= Self.Count;
      end
    else
      Inc(i);
end;

function TMemIni.IsSectionBase(const Index: integer): boolean;
begin
  Result:= ((Self[Index][1] = '[') and (Self[Index][Length(Self[Index])] = ']'));
end;

function TMemIni.GetKeyOffset(const SectionBase: integer; const Key: string): integer;
var
  i: integer;
begin
  Result:= 0;
  if SectionBase <> -1 then
    begin
      i:= 1;
      while (i <> 0) and (SectionBase+i < Self.Count) and (not IsSectionBase(SectionBase+i)) do
        if Pos(AnsiUpperCase(Trim(Key))+'=', Self[SectionBase+i]) = 1 then
          begin
            Result:= i;
            i:= 0;
          end
        else
          Inc(i);
    end;
end;

function TMemIni.ReadString(const Section, Key, Default: string): string; // см. TIniFile
var
  Base, Offs, l: integer;
  s: string;
begin
  Base:= GetSectionBase(Section);
  if Base <> -1 then
    begin
      Offs:= GetKeyOffset(Base, Key);
      if Offs > 0 then
        begin
          l:= Pos('=', Self[Base+Offs]);
          s:= Copy(Self[Base+Offs], l+1, Length(Self[Base+Offs])-l);
          if s <> '' then
            if (Length(s) >= 2) and (s[1] = '"') and (s[Length(s)] = '"') then
              Result:= Copy(s, 2, Length(s)-2)
            else
              Result:= s
          else
            Result:= s;
        end
      else
        Result:= Default;
    end
  else
    Result:= Default;
end;

function TMemIni.ReadInteger(const Section, Key: string; Default: integer): integer; // см. TIniFile
begin
  Result:= StrToIntDef(Self.ReadString(Section, Key, IntToStr(Default)), Default);
end;

function TMemIni.SectionExists(const Section: string): boolean;
begin
  Result:= (GetSectionBase(Section) <> -1);
end;

function TMemIni.KeyExists(const Section, Key: string): boolean;
begin
  Result:= (GetKeyOffset(GetSectionBase(Section), Key) > 0);
end;

////////////////////////////////////////////////////////////////////////////////

constructor TTranslator.Create;
begin
  inherited Create;
  FDict:= TMemIni.Create;
  FLangSelect:= lsUser;
  FFileName:= '';
  FAutoReload:= true;
  FOnLangSelect:= nil;
  FOnLangError:= nil;
  FOnUnknownText:= nil;
end;

destructor TTranslator.Destroy;
begin
  FDict.Free;
  inherited Destroy;
end;

procedure TTranslator.Load; 
var
  i: integer;
  Ini: TMemIni;
  LangSection, s: string;
begin
  if FFileName <> '' then
    begin
      Ini:= TMemIni.Create;

      try
        if FileExists(ExtractFilePath(ParamStr(0))+FFileName) then
          Ini.LoadFromFile(ExtractFilePath(ParamStr(0))+FFileName)
        else
          Ini.LoadFromFile(FFileName);

        try
          FLangId:= GetLanguageId;
          LangSection:= Ini.ReadString('Prefs', FLangId, '');
          if (LangSection = '') and (FLangId <> 'Default') then LangSection:= Ini.ReadString('Prefs', 'Default', '');
          if LangSection <> '' then
            begin
              s:= '[Current]'#13;
              i:= Ini.GetSectionBase(LangSection)+1;
              while (i < Ini.Count) and (not Ini.IsSectionBase(i)) do
                begin
                  s:= s+Ini[i]+#13;
                  inc(i);
                end;
              FDict.Text:= s;
            end
          else
            if Assigned(FOnLangError) then FOnLangError(Self, leDefaultError);
        finally
          Ini.Free;
        end;
      except
        if Assigned(FOnLangError) then FOnLangError(Self, leFileError);
      end;
    end;
end;

function TTranslator.GetLanguageId: string;
var
  Data: array [byte] of char;
begin
  StrPCopy(Data, 'Default');
  case FLangSelect of
    lsSystem: GetLocaleInfo(LOCALE_SYSTEM_DEFAULT, LOCALE_SENGLANGUAGE, Data, sizeof(Data));
    lsUser: GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_SENGLANGUAGE, Data, sizeof(Data));
    lsManual: { nothing to do };
  end;
  Result:= StrPas(Data);
  if Assigned(FOnLangSelect) then FOnLangSelect(Self, Result);
end;

function TTranslator.Translate(const Text, DefText: string): string;
var
  ResultLen: Integer;
begin
  if Text <> '' then
    begin
      Result:= FDict.ReadString('Current', StringReplace(Text, #13, '#13', [rfReplaceAll]), #13);
      if Result = #13 then
        begin
          Result:= DefText;
          if Assigned(FOnUnknownText) then FOnUnknownText(Self, Result);
        end
      else
        begin
          ResultLen:= Length(Result);
          if (ResultLen > 2) and (Result[1] = '%') and (Result[ResultLen] = '%') then
            Result:= Translate(Copy(Result, 2, ResultLen-2), DefText)
          else
            Result:= StringReplace(Result, '#13', #13, [rfReplaceAll]);
        end;
    end
  else
    Result:= DefText;
end;

procedure TTranslator.SetFileName(const Value: string);
begin
  if Value <> FFileName then
    begin
      FFileName:= Value;
      if FAutoReload then Load;
    end;
end;

procedure TTranslator.SetLangSelect(const Value: TLangSelect);
begin
  if Value <> FLangSelect then
    begin
      FLangSelect:= Value;
      if FAutoReload then Load;
    end;
end;

////////////////////////////////////////////////////////////////////////////////

end.

