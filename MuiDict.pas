{ Author: Михаил Черкес
  Summary: Словарный компонент для TMUI }

unit MuiDict;

interface

uses
  Classes, Trans;

type
  TLangError = (leFileError, leDefaultError);
  { leFileError: не удалось загрузить словарь, ошибка файлового ввода-вывода;
    leDefaultError: актуального словаря в текущем файле нет, а секция "по умолчанию" не назначена;}

type
  TDict = class(TComponent)
  private
    FTranslator: TTranslator; // хранитель словаря для текущего языка (и только его!)
    procedure   SetFileName(const Value: string); // см. ниже
    function    GetFileName: string; // см. ниже
    function    GetLangSelect: TLangSelect; // см. ниже
    procedure   SetLangSelect(const Value: TLangSelect); // см. ниже
    function    GetOnLangSelect: TOnLangSelect; // см. ниже
    procedure   SetOnLangSelect(const Value: TOnLangSelect); // см. ниже
    function    GetOnLangError: TOnLangError; // см. ниже
    procedure   SetOnLangError(const Value: TOnLangError); // см. ниже
    function    GetOnUnknownText: TOnUnknownText; // см. ниже
    procedure   SetOnUnknownText(const Value: TOnUnknownText);
    function    GetLanguageID: string; // см. ниже
  protected
    procedure   Loaded; override; // RTFM: Theory of Object Programming, Object Pascal Reference, VCL Manual, Self DNA integrity.
  public
    constructor Create(AOwner: TComponent); overload; override; // RTFM Object Pascal Reference
    constructor Create(AOwner: TComponent; const FileName: string); reintroduce; overload; // RTFM Object Pascal Reference
    destructor  Destroy; override; // RTFM Object Pascal Reference
    procedure   LoadFromFile(const FileName: string; const SupressException: Boolean = False);
                                                      { 1. загрузить словарь из файла FileName
                                                        2. если без коментария не понятно, то учить английский }
    procedure   Load; // Загрузить словарь из FTranslator.FileName
    function    Translate(const Text: string; const DefText: string = ''): string; // переводит произвольную строку

    property    LanguageID: string read GetLanguageID;
  published
    property    FileName: string read GetFileName write SetFileName; // файл со словорем
    property    LangSelectType: TLangSelect read GetLangSelect write SetLangSelect default lsUser; // способ выбора языка

    property    OnLangSelect: TOnLangSelect read GetOnLangSelect write SetOnLangSelect default nil; // вызывается сразу после выбора языка
    property    OnLangError: TOnLangError read GetOnLangError write SetOnLangError default nil; // ошибка ввода-вывода или синтаксиса словаря, см. TLangError
    property    OnUnknownText: TOnUnknownText read GetOnUnknownText write SetOnUnknownText default nil; // вызвается когда строка в словаре не найдена
  end;

implementation

{$R MuiDict.dcr}

uses
  Windows;

constructor TDict.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTranslator:= TTranslator.Create;
  FTranslator.AutoReload:= false;
end;

constructor TDict.Create(AOwner: TComponent; const FileName: string);
begin
  Create(AOwner);
  LoadFromFile(FileName);
end;

destructor TDict.Destroy;
begin
  FTranslator.Free;
  inherited Destroy;
end;

function TDict.Translate(const Text: string; const DefText: string = ''): string;
begin
  if DefText = '' then
    Result:= FTranslator.Translate(Text, Text)
  else
    Result:= FTranslator.Translate(Text, DefText);
end;

procedure TDict.SetFileName(const Value: string);
begin
  FTranslator.FileName:= Value;
end;

function TDict.GetFileName: string;
begin
  Result:= FTranslator.FileName;
end;

function TDict.GetLangSelect: TLangSelect;
begin
  Result:= FTranslator.LangSelectType;
end;

function TDict.GetLanguageID: string;
begin
  Result:= FTranslator.LanguageID;
end;

procedure TDict.SetLangSelect(const Value: TLangSelect);
begin
  FTranslator.LangSelectType:= Value;
end;

function TDict.GetOnLangSelect: TOnLangSelect;
begin
  Result:= FTranslator.OnLangSelect;
end;

procedure TDict.SetOnLangSelect(const Value: TOnLangSelect);
begin
  FTranslator.OnLangSelect:= Value;
end;

function TDict.GetOnLangError: TOnLangError;
begin
  Result:= FTranslator.OnLangError;
end;

procedure TDict.SetOnLangError(const Value: TOnLangError);
begin
  FTranslator.OnLangError:= Value;
end;

function TDict.GetOnUnknownText: TOnUnknownText;
begin
  Result:= FTranslator.OnUnknownText;
end;

procedure TDict.SetOnUnknownText(const Value: TOnUnknownText);
begin
  FTranslator.OnUnknownText:= Value;
end;

procedure TDict.Loaded;
begin
  inherited Loaded;
  if not (csDesigning in Self.ComponentState) then FTranslator.Load; // только для RunTime
end;

procedure TDict.LoadFromFile(const FileName: string; const SupressException: Boolean = False);
begin
  try
    FTranslator.FileName:= FileName;
    FTranslator.Load;
  except
    if not SupressException then raise;
  end;
end;

procedure TDict.Load;
begin
  FTranslator.Load;
end;

////////////////////////////////////////////////////////////////////////////////

end.

