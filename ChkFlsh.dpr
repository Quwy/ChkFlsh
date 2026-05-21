program ChkFlsh;

uses
  Forms,
  MainForm in 'MainForm.pas' {fMain},
  fdisk in 'fdisk.pas',
  PartForm in 'PartForm.pas' {fPartitions},
  PartEdit in 'PartEdit.pas' {fPartEdit},
  Trans in 'Trans.pas',
  MUI in 'MUI.pas',
  MuiDict in 'MuiDict.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.HintHidePause:= 10000;
  Application.CreateForm(TfMain, fMain);
  Application.Run;
end.
