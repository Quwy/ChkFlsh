unit PartForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Zlib, Graphics, Controls,
  Forms, Dialogs, StdCtrls, ExtCtrls, ComCtrls, FDisk, MainForm, ioctl;

type
  TfPartitions = class(TForm)
    gbPartTable: TGroupBox;
    lvPartTable: TListView;
    btnNew: TButton;
    btnUp: TButton;
    btnDn: TButton;
    btnDelete: TButton;
    btnCancel: TButton;
    btnOk: TButton;
    btnActivate: TButton;
    mmHint: TMemo;
    cbShowAll: TCheckBox;
    sdPartTable: TSaveDialog;
    btnLoad: TButton;
    odPartTable: TOpenDialog;
    btnSave: TButton;
    procedure btnNewClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnActivateClick(Sender: TObject);
    procedure btnDnClick(Sender: TObject);
    procedure btnUpClick(Sender: TObject);
    procedure lvPartTableSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbShowAllClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
  private
    FileHandle: THandle;
    MBR: TMBR;
    DG: TDISK_GEOMETRY;
    StartFreeSpace: TCHS;
    FullSize: Int64;
    WriteQueue: TList;
    function  ReadMBR(const Handle: THandle; var MBR: TMBR): boolean;
    procedure CorrectMBR(var MBR: TMBR);
    procedure LoadList(const MBR: TMBR; const ShowAll: Boolean);
    procedure IncCHS(var CHS: TCHS);
    procedure InsertToMbr(var MBR: TMBR; const Index: byte; const PartTableEntry: TPartTableEntry);
    procedure DeleteFromMBR(var MBR: TMBR; const Index: byte);
    procedure ActivateEntry(var MBR: TMBR; const Index: byte);
    function  IsMBRCorrect(const MBR: TMBR): byte;
    procedure AddWriteItem(const WriteTo: Int64; const Data; const Size: Cardinal);
    procedure ClearQueue;
    procedure FlushQueue(const Handle: THandle);
  public
    function  Execute(const Handle: THandle; const Size: Int64): boolean;
  end;

var
  fPartitions: TfPartitions;

implementation

{$R *.dfm}

uses
  PartEdit;

type
  TQueueItem = record
    WriteTo: Int64;
    Data: pointer;
    Size: Cardinal;
  end;
  PQueueItem = ^TQueueItem;

procedure TfPartitions.LoadList(const MBR: TMBR; const ShowAll: Boolean);
var
  ListItem: TListItem;
  Status: string;
  i, Index: integer;
begin
  if Mbr.Signature = BootSignature then
    begin
      lvPartTable.Items.BeginUpdate;
      if lvPartTable.Selected <> nil then
        Index:= StrToIntDef(lvPartTable.Selected.Caption, -1)
      else
        Index:= -1;
      lvPartTable.Items.Clear;
      for i:= 0 to 3 do
        begin
          ListItem:= lvPartTable.Items.Add;
          ListItem.Caption:= inttostr(i);
          if Mbr.PartTable[i].SystemID <> siEmpty then
            begin
              if MBR.PartTable[i].EndCylinder >= StartFreeSpace.Cylinder then
                begin
                  StartFreeSpace.Cylinder:= MBR.PartTable[i].EndCylinder;
                  StartFreeSpace.Head:= MBR.PartTable[i].EndHead;
                  StartFreeSpace.Sector:= MBR.PartTable[i].StartSector;
                end;
//              dec(FullSize, Int64(MBR.PartTable[i].SectorCount)*sizeof(TSector));

              case Mbr.PartTable[i].Active of
                afNone: Status:= fMain.FMui.Translate('tstPartExists', 'exists');
                afActive: Status:= fMain.FMui.Translate('tstPartActive', 'active');
              else
                Status:= fMain.FMui.Translate('tstPartError', 'ERROR');
              end;
              ListItem.SubItems.Add(Status);
              ListItem.SubItems.Add(GetSystemIDStr(Mbr.PartTable[i].SystemID));
              if (Mbr.PartTable[i].Active in [afNone, afActive]) or ShowAll then
                begin
                  ListItem.SubItems.Add(IntToStr(Mbr.PartTable[i].StartCylinder));
                  ListItem.SubItems.Add(IntToStr(Mbr.PartTable[i].StartHead));
                  ListItem.SubItems.Add(IntToStr(Mbr.PartTable[i].StartSector));
                  ListItem.SubItems.Add(IntToStr(Mbr.PartTable[i].SectorCount));
                  ListItem.SubItems.Add(fMain.SafeFormat(fMain.FMui.Translate('tstXMB', '%n MB'), [Int64(Mbr.PartTable[i].SectorCount)*SizeOf(TSector)/MByte]));
                end;
            end
          else
            ListItem.SubItems.Add(fMain.FMui.Translate('tstPartEmpty', 'empty'));
        end;
      for i:= 0 to lvPartTable.Items.Count-1 do
        if lvPartTable.Items[i].Caption = IntToStr(Index) then lvPartTable.Selected:= lvPartTable.Items[i];
      lvPartTable.Items.EndUpdate;
    end;
end;

procedure TfPartitions.IncCHS(var CHS: TCHS);
begin
  if CHS.Sector < DG.SectorsPerTrack then
    Inc(CHS.Sector)
  else
    if CHS.Head < DG.TracksPerCylinder then
      begin
        Inc(CHS.Head);
        CHS.Sector:= 1;
      end
    else
      begin
        Inc(CHS.Cylinder);
        CHS.Sector:= 1;
        CHS.Head:= 0;
      end;
end;

procedure TfPartitions.InsertToMbr(var MBR: TMBR; const Index: byte; const PartTableEntry: TPartTableEntry);
begin
  MBR.PartTable[Index]:= PartTableEntry;
end;

procedure TfPartitions.DeleteFromMBR(var MBR: TMBR; const Index: byte);
begin
  if Index <= 3 then MBR.PartTable[Index].SystemID:= siEmpty;
end;

procedure TfPartitions.ActivateEntry(var MBR: TMBR; const Index: byte);
var
  i: byte;
begin
  if Index <= 3 then
    for i:= 0 to 3 do
      if i = Index then
        MBR.PartTable[i].Active:= afActive
      else
        MBR.PartTable[i].Active:= afNone;
end;

function TfPartitions.ReadMBR(const Handle: THandle; var MBR: TMBR): boolean;
begin
  FileSeek(Handle, 0, 0);
  Result:= (FileRead(Handle, MBR, sizeof(MBR)) = sizeof(MBR));
end;

procedure TfPartitions.CorrectMBR(var MBR: TMBR);
const
  BigFloppy = 'This device is formatted as a "big floppy" and has no partition table. '+
              'Do you want to initialize an empty partition table?'#13+
              'This is a DESTRUCTIVE operation, but all changes will be written to '+
              'disk only after the completion of the new partition table editing.';
  IvalidMBR = 'The current master boot record (MBR) is probably invalid. '+
              'Do you want to replace it with empty one?'#13+
              'This is a DESTRUCTIVE operation, but all changes will be written to '+
              'disk only after the completion of the new partition table editing.';
begin
  case IsMBRCorrect(MBR) of
    000: { all OK, nothing to do };
    127: if Application.MessageBox(PChar(fMain.FMui.Translate('tstBigFloppy', BigFloppy)), PChar(fMain.FMui.Translate('tstWarning', 'Warning')), MB_YESNO+MB_ICONWARNING) = IDYES then MBR:= GetBlankMBR;
    255: MBR:= GetBlankMBR;
  else if Application.MessageBox(PChar(fMain.FMui.Translate('tstInvalidMBR', IvalidMBR)), PChar(fMain.FMui.Translate('tstWarning', 'Warning')), MB_YESNO+MB_ICONWARNING) = IDYES then MBR:= GetBlankMBR;
  end;
end;

function TfPartitions.IsMBRCorrect(const MBR: TMBR): byte;
var
  i: integer;
begin
  Result:= 0;

  if MBR.Signature <> BootSignature then Result:= 255;

  if Result = 0 then
    for i:= 0 to 3 do
      if (MBR.PartTable[i].Active <> afNone) and (MBR.PartTable[i].Active <> afActive) then
        Result:= 127;

  if Result = 0 then
    for i:= 0 to 3 do
      if (MBR.PartTable[i].SystemID <> siEmpty) and
         ((MBR.PartTable[i].StartHead >= DG.TracksPerCylinder) or (MBR.PartTable[i].EndHead >= DG.TracksPerCylinder) or
         ((DG.Cylinders <= 1023) and ((MBR.PartTable[i].StartCylinder > DG.Cylinders) or (MBR.PartTable[i].EndCylinder > DG.Cylinders) or (MBR.PartTable[i].StartSector > DG.SectorsPerTrack))) or
         (MBR.PartTable[i].SectorCount > FullSize div sizeof(TSector))) then Result:= 200;
end;

function TfPartitions.Execute(const Handle: THandle; const Size: Int64): boolean;
var
  Res: Cardinal;
  OldMBR: TMBR;
begin
  Result:= false;
  if Handle <> INVALID_HANDLE_VALUE then
    begin
      if Size <= MByte*512 then mmHint.Lines.Text:= fMain.FMui.Translate('tstPartLess512', 'Windows and some other operating systems may not support multiple partitions on removable drives smaller than 512 MB.');

      FileHandle:= Handle;

      FullSize:= Size;
      DeviceIoControl(FileHandle, IOCTL_DISK_GET_DRIVE_GEOMETRY, nil, 0, @DG, sizeof(DG), Res, nil);
      StartFreeSpace.Cylinder:= 0;
      StartFreeSpace.Head:= 0;
      StartFreeSpace.Sector:= DG.SectorsPerTrack;

      ReadMBR(FileHandle, MBR);
      OldMBR:= MBR;
      CorrectMBR(MBR);
      LoadList(MBR, cbShowAll.Checked);
      if ShowModal = mrOK then
        if not CompareMem(@MBR, @OldMBR, sizeof(TMBR)) then
          if Application.MessageBox(PChar(fMain.FMui.Translate('tstWriteChanges', 'Do you want to write all changes to the device?')), PChar(fMain.FMui.Translate('tstWarning', 'Warning')), MB_YESNO+MB_ICONWARNING) = IDYES then
            begin
              AddWriteItem(0, MBR, sizeof(MBR));
              FlushQueue(FileHandle);
              Result:= true;
            end
          else
            { do nothing }
        else
          Result:= true;
    end;
end;

procedure TfPartitions.btnNewClick(Sender: TObject);
//////////////////////////////
function GetSystemID(const Index: integer): TSystemID;
begin
  case Index of
    00: Result:= siFAT16;
    01: Result:= siFAT32;
    02: Result:= siFAT32_LBA;
    03: Result:= siFAT16_LBA;
  else Result:= siEmpty;
  end;
end;
//////////////////////////////
var
  FreeSpace, NewSize: Int64;
  PartTableEntry: TPartTableEntry;
  Index: integer;
  BR_FAT: TBR_FAT;
  BR_FAT32: TBR_FAT32;
begin
  Index:= StrToIntDef(lvPartTable.Selected.Caption, -1);
  FreeSpace:= FullSize-(Int64(StartFreeSpace.Cylinder)*DG.TracksPerCylinder*DG.SectorsPerTrack*DG.BytesPerSector+Int64(StartFreeSpace.Head)*DG.SectorsPerTrack*DG.BytesPerSector+Int64(StartFreeSpace.Sector-1)*DG.BytesPerSector);

  if (Index >= 0) and (Index <= 3) then
    if FreeSpace > Int64(DG.TracksPerCylinder)*DG.SectorsPerTrack*DG.BytesPerSector then
      begin
        fPartEdit:= TfPartEdit.Create(nil);
        fPartEdit.tbSize.Frequency:= (MByte div sizeof(TSector))*32;
        fPartEdit.tbSize.Max:= FreeSpace div Int64(sizeof(TSector));
        fPartEdit.tbSize.Position:= fPartEdit.tbSize.Max;
        fPartEdit.lblState.Caption:= fMain.SafeFormat(fMain.FMui.Translate('tstMBofMB', '%n/%n'), [FreeSpace/MByte, FreeSpace/MByte]);
        if fPartEdit.ShowModal = mrOK then
          begin
            NewSize:= Int64(fPartEdit.tbSize.Position)*sizeof(TSector);

            PartTableEntry.Active:= afNone;
            PartTableEntry.SystemID:= GetSystemID(fPartEdit.cbSystemID.ItemIndex);

            while StartFreeSpace.Sector <> 1 do IncCHS(StartFreeSpace);

            PartTableEntry.StartCylinder:= StartFreeSpace.Cylinder;
            PartTableEntry.StartHead:= StartFreeSpace.Head;
            PartTableEntry.StartSector:= StartFreeSpace.Sector;

            PartTableEntry.EndCylinder:= PartTableEntry.StartCylinder+(NewSize div Int64(DG.TracksPerCylinder*DG.SectorsPerTrack*DG.BytesPerSector))-1;
            PartTableEntry.EndHead:= DG.TracksPerCylinder-1;//(NewSize-Int64(PartTableEntry.EndCylinder-PartTableEntry.StartCylinder)*Int64(DG.TracksPerCylinder)*DG.SectorsPerTrack*DG.BytesPerSector) div Int64(DG.SectorsPerTrack*DG.BytesPerSector);
            PartTableEntry.SectorCount:= Cardinal(PartTableEntry.EndCylinder-PartTableEntry.StartCylinder-1)*DG.TracksPerCylinder*DG.SectorsPerTrack+(DG.TracksPerCylinder-PartTableEntry.StartHead)*DG.SectorsPerTrack-(PartTableEntry.StartSector-1)+PartTableEntry.EndHead*DG.SectorsPerTrack;//NewSize div Int64(sizeof(TSector));

            InsertToMbr(MBR, Index, PartTableEntry);
            if fPartEdit.cbActivate.Checked then ActivateEntry(MBR, Index);

            case PartTableEntry.SystemID of
              siFAT16,
              siFAT16_LBA: begin
                             BR_FAT:= GetBlankBR_FAT(DG.SectorsPerTrack, DG.TracksPerCylinder, PartTableEntry.SectorCount, GenerateSerialNumber);
                             AddWriteItem(Int64(Int64(PartTableEntry.StartCylinder)*DG.TracksPerCylinder*DG.SectorsPerTrack+Int64(PartTableEntry.StartHead)*DG.SectorsPerTrack+Int64(PartTableEntry.StartSector-1))*sizeof(TSector), BR_FAT, sizeof(BR_FAT));
                           end;
              siFAT32,
              siFAT32_LBA: begin
                             BR_FAT32:= GetBlankBR_FAT32(DG.SectorsPerTrack, DG.TracksPerCylinder, PartTableEntry.SectorCount, GenerateSerialNumber);
                             AddWriteItem(Int64(Int64(PartTableEntry.StartCylinder)*DG.TracksPerCylinder*DG.SectorsPerTrack+Int64(PartTableEntry.StartHead)*DG.SectorsPerTrack+Int64(PartTableEntry.StartSector-1))*sizeof(TSector), BR_FAT32, sizeof(BR_FAT32));
                             AddWriteItem(Int64(Int64(PartTableEntry.StartCylinder)*DG.TracksPerCylinder*DG.SectorsPerTrack+Int64(PartTableEntry.StartHead)*DG.SectorsPerTrack+Int64(PartTableEntry.StartSector-1))*sizeof(TSector), BR_FAT32, sizeof(BR_FAT32));
                           end;
            else
              Application.MessageBox(PChar(fMain.FMui.Translate('tstSysIDNotSupported', 'This System ID is not supported')), PChar(fMain.FMui.Translate('tstError', 'Error')), MB_OK);
            end;

            LoadList(MBR, cbShowAll.Checked);
          end;
        fPartEdit.Free;
      end
    else
      Application.MessageBox(PChar(fMain.FMui.Translate('tstNoFreeSpace', 'There is no free space on the device.')), PChar(fMain.FMui.Translate('tstWarning', 'Warning')), MB_OK+MB_ICONWARNING);
end;

procedure TfPartitions.btnDeleteClick(Sender: TObject);
var
  i: integer;
  IsPart: boolean;
begin
  if lvPartTable.Selected <> nil then
    begin
      DeleteFromMBR(MBR, StrToIntDef(lvPartTable.Selected.Caption, high(byte)));
      LoadList(MBR, cbShowAll.Checked);

      IsPart:= false;
      for i:= 0 to 3 do IsPart:= IsPart or (Mbr.PartTable[i].SystemID <> siEmpty);
      if not IsPart then
        begin
          StartFreeSpace.Cylinder:= 0;
          StartFreeSpace.Head:= 0;
          StartFreeSpace.Sector:= DG.SectorsPerTrack;
        end;
    end;
end;

procedure TfPartitions.btnActivateClick(Sender: TObject);
begin
  if lvPartTable.Selected <> nil then
    begin
      ActivateEntry(MBR, StrToIntDef(lvPartTable.Selected.Caption, high(byte)));
      LoadList(MBR, cbShowAll.Checked);
    end;
end;

procedure TfPartitions.btnDnClick(Sender: TObject);
var
  Index: integer;
  PartTableEntry: TPartTableEntry;
begin
  if lvPartTable.Selected <> nil then
    begin
      Index:= StrToIntDef(lvPartTable.Selected.Caption, -1);
      if (Index >= 0) and (Index < 3) then
        begin
          PartTableEntry:= MBR.PartTable[Index+1];
          MBR.PartTable[Index+1]:= MBR.PartTable[Index];
          MBR.PartTable[Index]:= PartTableEntry;
          LoadList(MBR, cbShowAll.Checked);
          lvPartTable.Selected:= lvPartTable.Items[Index+1]
        end;
    end;
end;

procedure TfPartitions.btnUpClick(Sender: TObject);
var
  Index: integer;
  PartTableEntry: TPartTableEntry;
begin
  if lvPartTable.Selected <> nil then
    begin
      Index:= StrToIntDef(lvPartTable.Selected.Caption, -1);
      if (Index > 0) and (Index <= 3) then
        begin
          PartTableEntry:= MBR.PartTable[Index-1];
          MBR.PartTable[Index-1]:= MBR.PartTable[Index];
          MBR.PartTable[Index]:= PartTableEntry;
          LoadList(MBR, cbShowAll.Checked);
          lvPartTable.Selected:= lvPartTable.Items[Index-1]
        end;
    end;
end;

procedure TfPartitions.lvPartTableSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
var
  Index: integer;
begin
  if Selected then
    begin
      Index:= StrToIntDef(Item.Caption, -1);
      if (Index >= 0) and (Index <= 3) then
        begin
          btnNew.Enabled:= (MBR.PartTable[Index].SystemID = siEmpty);
          btnDelete.Enabled:= (MBR.PartTable[Index].SystemID <> siEmpty);
          btnActivate.Enabled:= ((MBR.PartTable[Index].Active <> afActive) and (MBR.PartTable[Index].SystemID <> siEmpty));
          btnDn.Enabled:= (Index < 3);
          btnUp.Enabled:= (Index > 0);
        end;
    end
  else
    begin
      btnNew.Enabled:= false;
      btnUp.Enabled:= false;
      btnDn.Enabled:= false;
      btnDelete.Enabled:= false;
      btnActivate.Enabled:= false;
    end;
end;

procedure TfPartitions.FormCreate(Sender: TObject);
begin
  WriteQueue:= TList.Create;
  fMain.FMui.ProcessForm(Self);
end;

procedure TfPartitions.FormDestroy(Sender: TObject);
begin
  ClearQueue;
  WriteQueue.Free;
end;

procedure TfPartitions.AddWriteItem(const WriteTo: Int64; const Data; const Size: Cardinal);
var
  QI: PQueueItem;
begin
  New(QI);
  QI^.WriteTo:= WriteTo;
  if Size > 0 then
    begin
      GetMem(QI^.Data, Size);
      Move(Data, QI^.Data^, Size);
    end;
  QI^.Size:= Size;
  WriteQueue.Add(QI);
end;

procedure TfPartitions.ClearQueue;
var
  i: integer;
begin
  for i:= 0 to WriteQueue.Count-1 do
    begin
      if PQueueItem(WriteQueue[i])^.Size > 0 then FreeMem(PQueueItem(WriteQueue[i])^.Data, PQueueItem(WriteQueue[i])^.Size);
      Dispose(PQueueItem(WriteQueue[i]));
    end;
  WriteQueue.Clear;
end;

procedure TfPartitions.FlushQueue(const Handle: THandle);
var
  i: integer;
begin
  for i:= 0 to WriteQueue.Count-1 do
    if PQueueItem(WriteQueue[i])^.Size > 0 then
      begin
        FileSeek(Handle, PQueueItem(WriteQueue[i])^.WriteTo, 0);
        FileWrite(Handle, PQueueItem(WriteQueue[i])^.Data^, PQueueItem(WriteQueue[i])^.Size);
      end;
  ClearQueue;
end;

procedure TfPartitions.cbShowAllClick(Sender: TObject);
var
  i: Integer;
begin
  i:= lvPartTable.ItemIndex;
  LoadList(MBR, cbShowAll.Checked);
  lvPartTable.ItemIndex:= i;
end;

procedure TfPartitions.btnSaveClick(Sender: TObject);
var
  fOut: File of TMBR;
begin
  if sdPartTable.Execute then
    begin
      AssignFile(fOut, sdPartTable.FileName);
      Rewrite(fOut);
      Write(fOut, MBR);
      CloseFile(fOut);
    end;
end;

procedure TfPartitions.btnLoadClick(Sender: TObject);
var
  InFile: TFileStream;
  Stream: TStream;
  ZIMHeader: TZIMHeader;
begin
  if odPartTable.Execute then
    try
      InFile:= TFileStream.Create(odPartTable.FileName, fmOpenRead or fmShareDenyWrite);
      try
        if odPartTable.FilterIndex = 3 then
          if (InFile.Read(ZIMHeader, SizeOf(ZIMHeader)) = SizeOf(ZIMHeader)) and
             (ZIMHeader.Signature = ZIMSignature) and
             (ZIMHeader.Vesion and $FF00 <= ZIMVersion and $FF00) and
             (ZIMHeader.Size > 0) then
            Stream:= TDecompressionStream.Create(InFile)
          else
            raise EReadError.Create('ZIM header read error')
        else
          Stream:= InFile;
        Stream.Read(MBR, SizeOf(MBR));
        if odPartTable.FilterIndex = 3 then Stream.Free;
        CorrectMBR(MBR);
        LoadList(MBR, cbShowAll.Checked);
      finally
        InFile.Free;
      end;
    except
      Application.MessageBox(PChar(fMain.FMui.Translate('tstFileReadError', 'File read error.')), PChar(fMain.FMui.Translate('tstError', 'Error')), MB_OK);
    end;
end;

end.

