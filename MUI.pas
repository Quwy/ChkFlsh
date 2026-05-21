{ Author: Михаил Черкес
  Summary: Компонент перевода визуальных компонентов формы }

unit MUI;

interface

uses
  Classes, Graphics, Controls, Forms, MuiDict;

type
  TOnComponentTranslate = procedure(Sender: TObject; const Component: TComponent; var Process: boolean) of object;
  { Sender: RTFM VCL Manual;
    Component: текущий контрол;
    Process: флаг, указывающий на необходимость обработки компонента или пропуска его;}
  TTranslateBase = (tbName, tbCaption);

type
  TMUI = class(TComponent) // Компонент перевода форм
  private
    FParent: TForm; // см. ниже
    FParentOnCreate, FParentOnDestroy: TNotifyEvent; // см. ниже
    FIgnoreTag: integer; // см. ниже
    FDict: TDict; // см. ниже
    FAutoProcess: boolean; // см. ниже
    FOnComponentTranslate: TOnComponentTranslate; // см. ниже
    procedure   TranslateFont(const Name: string; const Font: TFont);
    procedure   TranslateHint(const Control: TControl);
  protected
    procedure   SetParent(const Value: TForm); // см. ниже
    procedure   ParentCreate(Sender: TObject); // прокси-процедура OnCreate формы Paent
    procedure   ParentDestroy(Sender: TObject); // прокси-процедура OnDestroy формы Paent
    procedure   SetDict(const Value: TDict); // см. ниже
  public
    constructor Create(AOwner: TComponent); overload; override; // RTFM Object Pascal Reference
    constructor Create(AOwner: TComponent; const Dict: TDict); reintroduce; overload; // RTFM Object Pascal Reference
    constructor Create(AOwner: TComponent; const Dict: TDict; const OwnerAutoProcess: boolean); reintroduce; overload; // RTFM Object Pascal Reference
    destructor  Destroy; override; // RTFM Object Pascal Reference
    procedure   ProcessForm(const Form: TForm); // переводит форму и все ее контролы
    procedure   ProcessParent; // переводит текущий Parent
    function    Translate(const Text: string; const DefText: string = ''): string;
                              { 1. ищет текст в словаре Dictionary
                                2. если не находит, вызывает Dictionary.OnUnknownText()
                                3. возвращает либо перевод либо ту же строку
                                4. учит мыслить логически }
  published
    property    IgnoreTag: integer read FIgnoreTag write FIgnoreTag default 0; // не переводить контролы с таким тагом (0 - переводить все)
    property    ParentForm: TForm read FParent write SetParent default nil; // форма, на которую бросили компонент
    property    Dictionary: TDict read FDict write SetDict default nil; // сюда присваивается готовый к работе словарь (созданный и проинициализированный!)
    property    AutoProcess: boolean read FAutoProcess write FAutoProcess default true; // начинать переводить сразу как только для этого все готово

    property    OnComponentTranslate: TOnComponentTranslate read FOnComponentTranslate write FOnComponentTranslate default nil; // перед переводом каждого контрола.
  end;

implementation

{$R MUI.dcr}

uses // все возможные TControl и TWinControl должны быть доступны модулю
  SysUtils, StdCtrls, ExtCtrls, Buttons, {Menus,} Dialogs, {CheckLst,} ComCtrls{,
  Valedit, Mask, Grids, Chart}, Spin;

constructor TMUI.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FParent:= nil;
  FParentOnCreate:= nil;
  FParentOnDestroy:= nil;
  FIgnoreTag:= 0;
  FDict:= nil;
  FOnComponentTranslate:= nil;
  FAutoProcess:= true;
end;

constructor TMUI.Create(AOwner: TComponent; const Dict: TDict);
begin
  Create(AOwner);
  FDict:= Dict;
end;

constructor TMUI.Create(AOwner: TComponent; const Dict: TDict; const OwnerAutoProcess: boolean);
begin
  Create(AOwner);
  FDict:= Dict;
  if OwnerAutoProcess and (AOwner is TForm) then ProcessForm(AOwner as TForm);
end;

destructor TMUI.Destroy;
begin
  SetParent(nil);
  inherited Destroy;
end;

procedure TMUI.SetParent(const Value: TForm);
begin
  if Value <> FParent then
    begin
      if Assigned(FParent) and (not (csDesigning in Self.ComponentState)) then
        try
          FParent.OnCreate:= FParentOnCreate;
          FParent.OnDestroy:= FParentOnDestroy;
        except
        end;

      FParent:= Value;
      if Assigned(FParent) and (not (csDesigning in Self.ComponentState)) then // только для RunTime
        begin
          FParentOnCreate:= FParent.OnCreate;
          FParent.OnCreate:= ParentCreate;
          FParentOnDestroy:= FParent.OnDestroy;
          FParent.OnDestroy:= ParentDestroy;
        end;
    end;
end;

procedure TMUI.ParentCreate(Sender: TObject);
begin
  if FAutoProcess then ProcessParent;
  if Assigned(FParentOnCreate) then FParentOnCreate(FParent);
end;

procedure TMUI.ParentDestroy(Sender: TObject);
begin
  try
    if Assigned(FParentOnDestroy) then FParentOnDestroy(FParent);
  finally
    FParent:= nil;
    FParentOnCreate:= nil;
    FParentOnDestroy:= nil;
  end;
end;

procedure TMUI.SetDict(const Value: TDict);
begin
  if Value <> FDict then
    begin
      FDict:= Value;
//      if FAutoProcess and not (csDesigning in Self.ComponentState) then ProcessParent;
    end;
end;

function TMUI.Translate(const Text: string; const DefText: string = ''): string;
begin
  if Assigned(FDict) then
    Result:= FDict.Translate(Text, DefText)
  else
    if DefText = '' then
      Result:= Text
    else
      Result:= DefText;
end;

procedure TMUI.TranslateFont(const Name: string; const Font: TFont);
begin
  Font.Name:= Translate(Name+'.font', Font.Name);
  Font.Size:= StrToIntDef(Translate(Name+'.font.size'), Font.Size);
  Font.Charset:= TFontCharset(StrToIntDef(Translate(Name+'.font.charset'), Font.Charset));
end;

procedure TMUI.TranslateHint(const Control: TControl);
begin
  Control.Hint:= Translate(Control.Name+'.hint', Control.Hint);
end;

procedure TMUI.ProcessForm(const Form: TForm);
var
  i, j, k: integer;
  Control: TComponent;
  Process: boolean;
begin
  if Assigned(Form) then
    begin
      Process:= true;
      if Assigned(FOnComponentTranslate) then FOnComponentTranslate(Self, Form, Process);
      if Process then
        begin
          TranslateFont(Form.Name, Form.Font);
          TranslateHint(Form);
          Form.Caption:= Translate(Form.Name, Form.Caption);
        end;

      for j:= 0 to Form.ComponentCount-1 do
        if (FIgnoreTag = 0) or (Form.Components[j].Tag <> FIgnoreTag) then
          begin
            Control:= Form.Components[j];
            Process:= true;
            if Assigned(FOnComponentTranslate) then FOnComponentTranslate(Self, Control, Process);
            if Process then
              begin
                // Visual components
                if Control is TButton then
                  begin
                    TranslateFont(Control.Name, (Control as TButton).Font);
                    TranslateHint(Control as TControl);
                    (Control as TButton).Caption:= Translate((Control as TButton).Name, (Control as TButton).Caption);
                  end;
                if Control is TLabel then
                  begin
                    TranslateFont(Control.Name, (Control as TLabel).Font);
                    TranslateHint(Control as TControl);
                    (Control as TLabel).Caption:= Translate((Control as TLabel).Name, (Control as TLabel).Caption);
                  end;
                {if Control is TMenuItem then
                  begin
                    TranslateHint(Control as TMenuItem);
                    (Control as TMenuItem).Caption:= Translate((Control as TMenuItem).Name, (Control as TMenuItem).Caption);
                  end;}
                if Control is TCheckBox then
                  begin
                    TranslateFont(Control.Name, (Control as TCheckBox).Font);
                    TranslateHint(Control as TControl);
                    (Control as TCheckBox).Caption:= Translate((Control as TCheckBox).Name, (Control as TCheckBox).Caption);
                  end;
                if Control is TRadioButton then
                  begin
                    TranslateFont(Control.Name, (Control as TRadioButton).Font);
                    TranslateHint(Control as TControl);
                    (Control as TRadioButton).Caption:= Translate((Control as TRadioButton).Name, (Control as TRadioButton).Caption);
                  end;
                {if Control is TBitBtn then
                  begin
                    TranslateFont(Control.Name, (Control as TBitBtn).Font);
                    TranslateHint(Control as TControl);
                    (Control as TBitBtn).Caption:= Translate((Control as TBitBtn).Name, (Control as TBitBtn).Caption);
                  end;}
                if Control is TSpeedButton then
                  begin
                    TranslateFont(Control.Name, (Control as TSpeedButton).Font);
                    TranslateHint(Control as TControl);
                    (Control as TSpeedButton).Caption:= Translate((Control as TSpeedButton).Name, (Control as TSpeedButton).Caption);
                  end;
                {if Control is TStaticText then
                  begin
                    TranslateFont(Control.Name, (Control as TStaticText).Font);
                    TranslateHint(Control as TControl);
                    (Control as TStaticText).Caption:= Translate((Control as TStaticText).Name, (Control as TStaticText).Caption);
                  end;
                if Control is TLabeledEdit then
                  begin
                    TranslateFont(Control.Name, (Control as TLabeledEdit).Font);
                    TranslateHint(Control as TControl);
                    (Control as TLabeledEdit).EditLabel.Caption:= Translate((Control as TLabeledEdit).Name, (Control as TLabeledEdit).EditLabel.Caption);
                  end;}

                // Hint-only visual components
                {if Control is TImage then
                  begin
                    TranslateHint(Control as TControl);
                  end;
                if Control is TEdit then
                  begin
                    TranslateFont(Control.Name, (Control as TEdit).Font);
                    TranslateHint(Control as TControl);
                  end;
                if Control is TMemo then
                  begin
                    TranslateFont(Control.Name, (Control as TMemo).Font);
                    TranslateHint(Control as TControl);
                  end;
                if Control is TScrollBar then
                  begin
                    TranslateHint(Control as TControl);
                  end;
                if Control is TMaskEdit then
                  begin
                    TranslateFont(Control.Name, (Control as TMaskEdit).Font);
                    TranslateHint(Control as TControl);
                  end;
                if Control is TStringGrid then
                  begin
                    TranslateFont(Control.Name, (Control as TStringGrid).Font);
                    TranslateHint(Control as TControl);
                  end;
                if Control is TDrawGrid then
                  begin
                    TranslateFont(Control.Name, (Control as TDrawGrid).Font);
                    TranslateHint(Control as TControl);
                  end;}
                if Control is TShape then
                  begin
                    TranslateHint(Control as TControl);
                  end;
                {if Control is TBevel then
                  begin
                    TranslateHint(Control as TControl);
                  end;}
                if Control is TScrollBox then
                  begin
                    TranslateFont(Control.Name, (Control as TScrollBox).Font);
                    TranslateHint(Control as TControl);
                  end;
                {if Control is TSplitter then
                  begin
                    TranslateHint(Control as TControl);
                  end;}
                if Control is TRichEdit then
                  begin
                    TranslateFont(Control.Name, (Control as TRichEdit).Font);
                    TranslateHint(Control as TControl);
                  end;
                if Control is TTrackBar then
                  begin
                    TranslateHint(Control as TControl);
                  end;
                if Control is TProgressBar then
                  begin
                    TranslateHint(Control as TControl);
                  end;
                {if Control is TUpDown then
                  begin
                    TranslateHint(Control as TControl);
                  end;
                if Control is THotKey then
                  begin
                    TranslateHint(Control as TControl);
                  end;
                if Control is TAnimate then
                  begin
                    TranslateHint(Control as TControl);
                  end;
                if Control is TDateTimePicker then
                  begin
                    TranslateFont(Control.Name, (Control as TDateTimePicker).Font);
                    TranslateHint(Control as TControl);
                  end;
                if Control is TMonthCalendar then
                  begin
                    TranslateFont(Control.Name, (Control as TMonthCalendar).Font);
                    TranslateHint(Control as TControl);
                  end;}
                if Control is TSpinEdit then
                  begin
                    TranslateFont(Control.Name, (Control as TSpinEdit).Font);
                    TranslateHint(Control as TControl);
                  end;

                // Non-visual components
                if Control is TSaveDialog then
                  begin
                    (Control as TSaveDialog).Title:= Translate((Control as TSaveDialog).Name+'.title', (Control as TSaveDialog).Title);
                    k:= (Control as TSaveDialog).FilterIndex;
                    (Control as TSaveDialog).Filter:= Translate((Control as TSaveDialog).Name+'.filter', (Control as TSaveDialog).Filter);
                    (Control as TSaveDialog).FilterIndex:= k;
                  end;
                if Control is TOpenDialog then
                  begin
                    (Control as TOpenDialog).Title:= Translate((Control as TOpenDialog).Name+'.title', (Control as TOpenDialog).Title);
                    k:= (Control as TOpenDialog).FilterIndex;
                    (Control as TOpenDialog).Filter:= Translate((Control as TOpenDialog).Name+'.filter', (Control as TOpenDialog).Filter);
                    (Control as TOpenDialog).FilterIndex:= k;
                  end;

                // List components
                {if Control is TRadioGroup then
                  begin
                    TranslateFont(Control.Name, (Control as TRadioGroup).Font);
                    TranslateHint(Control as TControl);
                    (Control as TRadioGroup).Caption:= Translate((Control as TRadioGroup).Name, (Control as TRadioGroup).Caption);
                    for i:= 0 to (Control as TRadioGroup).Items.Count-1 do (Control as TRadioGroup).Items[i]:= Translate((Control as TRadioGroup).Name+'['+IntToStr(i)+']', (Control as TRadioGroup).Items[i]);
                  end;
                if Control is TListBox then
                  begin
                    TranslateFont(Control.Name, (Control as TListBox).Font);
                    TranslateHint(Control as TControl);
                    k:= (Control as TListBox).ItemIndex;
                    for i:= 0 to (Control as TListBox).Items.Count-1 do (Control as TListBox).Items[i]:= Translate((Control as TListBox).Name+'['+IntToStr(i)+']', (Control as TListBox).Items[i]);
                    (Control as TListBox).ItemIndex:= k;
                  end;}
                if Control is TComboBox then
                  begin
                    TranslateFont(Control.Name, (Control as TComboBox).Font);
                    TranslateHint(Control as TControl);
                    k:= (Control as TComboBox).ItemIndex;
                    for i:= 0 to (Control as TComboBox).Items.Count-1 do (Control as TComboBox).Items[i]:= Translate((Control as TComboBox).Name+'['+IntToStr(i)+']', (Control as TComboBox).Items[i]);
//                    (Control as TComboBox).Text:= Translate((Control as TComboBox).Name, (Control as TComboBox).Text);
                    (Control as TComboBox).ItemIndex:= k;
                  end;
                if Control is TPageControl then
                  begin
                    TranslateFont(Control.Name, (Control as TPageControl).Font);
                    TranslateHint(Control as TControl);
                  end;
                {if Control is TCheckListBox then
                  begin
                    TranslateFont(Control.Name, (Control as TCkeckListbox).Font);
                    TranslateHint(Control as TControl);
                    k:= (Control as TCheckListBox).ItemIndex;
                    for i:= 0 to (Control as TCheckListBox).Items.Count-1 do (Control as TListBox).Items[i]:= Translate((Control as TCheckListBox).Name+'['+IntToStr(i)+']', (Control as TCheckListBox).Items[i]);
                    (Control as TCheckListBox).ItemIndex:= k;
                  end;}
                {if Control is TTabControl then
                  begin
                    TranslateFont(Control.Name, (Control as TTabControl).Font);
                    TranslateHint(Control as TControl);
                    for i:= 0 to (Control as TTabControl).Tabs.Count-1 do (Control as TTabControl).Tabs[i]:= Translate((Control as TTabControl).Name+'['+IntToStr(i)+']', (Control as TTabControl).Tabs[i]);
                  end;}
                {if Control is TValueListEditor then
                  begin
                    TranslateFont(Control.Name, (Control as TValueListEditor).Font);
                    TranslateHint(Control as TControl);
                    for i:= 0 to (Control as TValueListEditor).TitleCaptions.Count-1 do
                      (Control as TValueListEditor).TitleCaptions[i]:= Translate((Control as TValueListEditor).Name+'.titles['+IntToStr(i)+']', (Control as TValueListEditor).TitleCaptions[i]);
                    for i:= 1 to (Control as TValueListEditor).RowCount-1 do
                      begin
                        (Control as TValueListEditor).Values[(Control as TValueListEditor).Keys[i]]:= Translate((Control as TValueListEditor).Name+'.values['+(Control as TValueListEditor).Keys[i]+']', (Control as TValueListEditor).Values[(Control as TValueListEditor).Keys[i]]);
                        (Control as TValueListEditor).Keys[i]:= Translate((Control as TValueListEditor).Name+'.keys['+IntToStr(i)+']', (Control as TValueListEditor).Keys[i]);
                      end;
                  end;}
                {if Control is TTreeView then
                  begin
                    TranslateFont(Control.Name, (Control as TTreeView).Font);
                    TranslateHint(Control as TControl);
                    for i:= 0 to (Control as TTreeView).Items.Count-1 do
                      (Control as TTreeView).Items[i].Text:= Translate((Control as TTreeView).Name+'['+IntToStr(i)+']', (Control as TTreeView).Items[i].Text);
                  end;}
                if Control is TListView then
                  begin
                    TranslateFont(Control.Name, (Control as TListView).Font);
                    TranslateHint(Control as TControl);
                    for i:= 0 to (Control as TListView).Columns.Count-1 do
                      (Control as TListView).Columns[i].Caption:= Translate((Control as TListView).Name+'.columns['+IntToStr(i)+']', (Control as TListView).Columns[i].Caption);
                    for i:= 0 to (Control as TListView).Items.Count-1 do
                      begin
                        (Control as TListView).Items[i].Caption:= Translate((Control as TListView).Name+'.items['+IntToStr(i)+']', (Control as TListView).Items[i].Caption);
                        for k:= 0 to (Control as TListView).Items[i].SubItems.Count-1 do
                          (Control as TListView).Items[i].SubItems[k]:= Translate((Control as TListView).Name+'.items['+IntToStr(i)+'].subitems['+IntToStr(k)+']', (Control as TListView).Items[i].SubItems[k]);
                      end;
                  end;
                {if Control is TStatusBar then
                  begin
                    TranslateFont(Control.Name, (Control as TStatusBar).Font);
                    TranslateHint(Control as TControl);
                    for i:= 0 to (Control as TStatusBar).Panels.Count-1 do
                      (Control as TStatusBar).Panels[i].Text:= Translate((Control as TStatusBar).Name+'['+IntToStr(i)+']', (Control as TStatusBar).Panels[i].Text);
                    (Control as TStatusBar).SimpleText:= Translate((Control as TStatusBar).Name+'.simpletext', (Control as TStatusBar).SimpleText);
                  end;
                if Control is TComboBoxEx then
                  begin
                      TranslateFont(Control.Name, (Control as TComboBoxEx).Font);
                      TranslateHint(Control as TControl);
//                    for i:= 0 to (Control as TComboBoxEx).ItemsEx.Count-1 do
//                      (Control as TComboBoxEx).ItemsEx[i].Caption:= Translate((Control as TComboBoxEx).Name+'.itemsex['+IntToStr(i)+']', (Control as TComboBoxEx).ItemsEx[i].Caption);
//                    for i:= 0 to (Control as TComboBoxEx).Items.Count-1 do
//                      (Control as TComboBoxEx).Items[i]:= Translate((Control as TComboBoxEx).Name+'['+IntToStr(i)+']', (Control as TComboBoxEx).Items[i]);
//                    (Control as TComboBoxEx).Text:= Translate((Control as TComboBoxEx).Name, (Control as TComboBoxEx).Text);
                  end;
                if Control is TToolBar then
                  begin
                    TranslateFont(Control.Name, (Control as TToolBar).Font);
                    TranslateHint(Control as TControl);
                    for i:= 0 to (Control as TToolBar).ButtonCount-1 do
                      begin
                        (Control as TToolBar).Buttons[i].Caption:= Translate((Control as TToolBar).Name+'['+IntToStr(i)+']', (Control as TToolBar).Buttons[i].Caption);
                        (Control as TToolBar).Buttons[i].Hint:= Translate((Control as TToolBar).Name+'.hints['+IntToStr(i)+']', (Control as TToolBar).Buttons[i].Hint);
                      end;
                  end;}
                {if Control is TCheckListBox then
                  begin
                    TranslateFont(Control.Name, (Control as TckeckListBox).Font);
                    TranslateHint(Control as TControl);
                    for i:= 0 to (Control as TCheckListBox).Items.Count-1 do (Control as TCheckListBox).Items[i]:= Translate((Control as TCheckListBox).Name+'['+IntToStr(i)+']', (Control as TCheckListBox).Items[i]);
                  end;}

                // Group components
                if Control is TForm then
                  begin
                    TranslateFont(Control.Name, (Control as TForm).Font);
                    TranslateHint(Control as TControl);
                    (Control as TForm).Caption:= Translate((Control as TForm).Name, (Control as TForm).Caption);
                  end;
                if Control is TFrame then
                  begin
                    TranslateFont(Control.Name, (Control as TFrame).Font);
                    TranslateHint(Control as TControl);
                  end;
                if Control is TPanel then
                  begin
                    TranslateFont(Control.Name, (Control as TPanel).Font);
                    TranslateHint(Control as TControl);
                    (Control as TPanel).Caption:= Translate((Control as TPanel).Name, (Control as TPanel).Caption);
                  end;
                if Control is TGroupBox then
                  begin
                    TranslateFont(Control.Name, (Control as TGroupBox).Font);
                    TranslateHint(Control as TControl);
                    (Control as TGroupBox).Caption:= Translate((Control as TGroupBox).Name, (Control as TGroupBox).Caption);
                  end;
                if Control is TTabSheet then
                  begin
                    TranslateFont(Control.Name, (Control as TTabSheet).Font);
                    TranslateHint(Control as TControl);
                    (Control as TTabSheet).Caption:= Translate((Control as TTabSheet).Name, (Control as TTabSheet).Caption);
                  end;

                // Other components
                {if Control is TChart then
                  begin
                    //
                    TranslateFont(Control.Name, (Control as TChart).Font);
                    TranslateHint(Control as TControl);
                  end;}
              end;
          end;
      end;
end;

procedure TMUI.ProcessParent;
begin
  ProcessForm(FParent);
end;

end.

