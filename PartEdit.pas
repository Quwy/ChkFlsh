unit PartEdit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls;

type
  TfPartEdit = class(TForm)
    lblCapSystemID: TLabel;
    cbSystemID: TComboBox;
    cbActivate: TCheckBox;
    gbSize: TGroupBox;
    btnCancel: TButton;
    btnOk: TButton;
    tbSize: TTrackBar;
    lblState: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure tbSizeChange(Sender: TObject);
    procedure cbSystemIDDropDown(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fPartEdit: TfPartEdit;

implementation

{$R *.dfm}

uses
  MainForm, FDisk;

procedure TfPartEdit.cbSystemIDDropDown(Sender: TObject);
begin
  fMain.FixComboBox(Sender as TComboBox);
end;

procedure TfPartEdit.FormCreate(Sender: TObject);
begin
  fMain.FMui.ProcessForm(Self);
  cbSystemID.ItemIndex:= 0;
  tbSize.Position:= 0;
  lblState.Caption:= fMain.SafeFormat(fMain.FMui.Translate('tstMBofMB', '%n/%n'), [0.0, 0.0]);
end;

procedure TfPartEdit.tbSizeChange(Sender: TObject);
begin
  lblState.Caption:= fMain.SafeFormat(fMain.FMui.Translate('tstMBofMB', '%n/%n'), [Int64(tbSize.Position)*SizeOf(TSector)/MByte, Int64(tbSize.Max)*SizeOf(TSector)/MByte]);
end;

end.
