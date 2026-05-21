unit MainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Zlib, Graphics, Controls,
  Forms, Dialogs, StdCtrls, ComCtrls, Spin, ExtCtrls, DriveMap, FDisk, Buttons,
  MUI, MuiDict;

type
  TZIMSignature = array[0..3] of AnsiChar;
  TZIMHeader = packed record
    Signature: TZIMSignature;
    Vesion: Word;
    Size: Int64;
  end;

const
  MByte = 1024*1024;
  ProgressStep = SizeOf(TSector)*256;
  InitCRC = $FFFFFFFF;
  LogLimit = 64*1024;
  ZIMSignature: TZIMSignature = 'ZIM!';
  ZIMVersion = $0101;

type
  TDISK_GEOMETRY = record
                     Cylinders: Int64;
                     MediaType: integer;
                     TracksPerCylinder, SectorsPerTrack, BytesPerSector: Cardinal;
                   end;
  TFORMAT_TRACKS = record
    MediaType: integer;
    StartCylinderNumber, EndCylinderNumber, StartHeadNumber, EndHeadNumber: Cardinal;
  end;
  TPARTITION_INFORMATION = record
    StartingOffset: Int64;
    PartitionLength: Int64;
    HiddenSectors: Cardinal;
    PartitionNumber: Cardinal;
    PartitionType: byte;
    BootIndicator: boolean;
    RecognizedPartition: boolean;
    RewritePartition: boolean;
  end;

  PBAD_TRACK_NUMBER = ^word;

type
  TWriteType = (wtSmallPattern, wtFullPattern, wtWriteManual, wtVerifyManual);
  TTestResult = record
    ResultCode: (rtOk, rtGenericFail, rtWriteFail, rtReadFail, rtUserInterrupt);
    ErrorsCount: Integer;
    ResultString: string;
  end;

type
  TfMain = class(TForm)
    Panel5: TPanel;
    gbAccessType: TGroupBox;
    rbTempFile: TRadioButton;
    rbPhysical: TRadioButton;
    rbLogical: TRadioButton;
    gbInfo: TGroupBox;
    lblCapCompletedCycles: TLabel;
    lblCompletedCycles: TLabel;
    lblCapErrorsFound: TLabel;
    lblErrorsFound: TLabel;
    lblCapReadSpeed: TLabel;
    lblReadSpeed: TLabel;
    lblCapWriteSpeed: TLabel;
    lblWriteSpeed: TLabel;
    Panel1: TPanel;
    pcDeviceSelect: TPageControl;
    tsDrive: TTabSheet;
    lblCapDrive: TLabel;
    cbDrive: TComboBox;
    tsDevice: TTabSheet;
    lblCapDevice: TLabel;
    cbDevice: TComboBox;
    Panel6: TPanel;
    pbMain: TProgressBar;
    Panel3: TPanel;
    pcMain: TPageControl;
    tsDriveMap: TTabSheet;
    Panel4: TPanel;
    tsLog: TTabSheet;
    Panel7: TPanel;
    btnStart: TButton;
    btnStop: TButton;
    odImage: TOpenDialog;
    sdImage: TSaveDialog;
    Panel8: TPanel;
    lblBlockWeight: TLabel;
    lblStage: TLabel;
    tsLegend: TTabSheet;
    Panel9: TPanel;
    Panel10: TPanel;
    sbRedrives: TSpeedButton;
    shUntouched: TShape;
    lblCapUntouched: TLabel;
    shRead: TShape;
    lblCapRead: TLabel;
    shVerified: TShape;
    lblCapVerified: TLabel;
    shWritten: TShape;
    lblCapWritten: TLabel;
    shError: TShape;
    lblCapError: TLabel;
    shCRCError: TShape;
    lblCapCRCFail: TLabel;
    Panel2: TPanel;
    gbActionType: TGroupBox;
    sbActionType: TScrollBox;
    rbReadTest: TRadioButton;
    rbWriteTest: TRadioButton;
    Panel11: TPanel;
    rbSmallPattern: TRadioButton;
    rbFullPattern: TRadioButton;
    rbPartEdit: TRadioButton;
    rbSave: TRadioButton;
    rbLoad: TRadioButton;
    gbTestLength: TGroupBox;
    lblCapCycles: TLabel;
    rbContinous: TRadioButton;
    rbOnePass: TRadioButton;
    rbManual: TRadioButton;
    seCycles: TSpinEdit;
    rbTillError: TRadioButton;
    rbErase: TRadioButton;
    lblCapElapsed: TLabel;
    lblElapsed: TLabel;
    lblCapRemain: TLabel;
    lblRemain: TLabel;
    tmrTimer: TTimer;
    lblCapDetails: TLabel;
    Panel12: TPanel;
    reLog: TRichEdit;
    cbScrollLog: TCheckBox;
    rbDelayedWrite: TRadioButton;
    rbDelayedVerify: TRadioButton;
    cbPattern: TComboBox;
    lblCapPattern: TLabel;
    edPattern: TEdit;
    lblCapPattern2: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure rbTempFileClick(Sender: TObject);
    procedure rbPhysicalClick(Sender: TObject);
    procedure rbReadTestClick(Sender: TObject);
    procedure rbManualClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure rbLogicalClick(Sender: TObject);
    procedure sbRedrivesClick(Sender: TObject);
    procedure tmrTimerTimer(Sender: TObject);
    procedure cbDriveDropDown(Sender: TObject);
    procedure edPatternKeyPress(Sender: TObject; var Key: Char);
  private
    DriveMap: TDriveMap;

    AllDrives, Stop, FSupressWarning, FQuitOnDone, FSilent: Boolean;
    FDefFileName: string;
    FStartTime, FIterationStartTime: Cardinal;
    FReadSpeed, FWriteSpeed: Double;
    FLogFile: ^TextFile;

    procedure OnComponentTranslate(Sender: TObject; const Component: TComponent; var Process: Boolean);
    procedure OnDictLangSelect(Sender: TObject; var Language: String);

    function RescueFileRead(const Handle: Integer; var Buffer; const Cnt: Cardinal; const SectorSize: Word; out Fails: Word): Integer;

    function  CheckDrive(const Number: Integer; var Size: Int64; var DriveType: Integer): Boolean;
    function  DriveOpen(const Number: Integer; const Mode: Cardinal; var Size: Int64; var IdealBlockSize: Cardinal; var SectorSize: Word): THandle;
    function  TempOpen(const Letter: Char; const Mode: Cardinal; const LeaveFile: Boolean; var Size: Int64; var IdealBlockSize: Cardinal; var SectorSize: Word): THandle;
    function  PartOpen(const Letter: Char; const Mode: Cardinal; var Size: Int64; var IdealBlockSize: Cardinal; var SectorSize: Word): THandle;
    procedure DiskClose(const Handle: THandle);
    function  ReadTest(const Handle: THandle; const Size: Int64; const IdealBlockSize: Cardinal; const PerformPrepearing: boolean; var CRC: Cardinal): TTestResult;
    function  WriteTest(const Handle: THandle; const Size: Int64; const IdealBlockSize: Cardinal; const WriteType: TWriteType; const ManualPattern: Byte): TTestResult;
    function  SaveImage(const FileName: String; const Handle: THandle; const Size: Int64; const IdealBlockSize: Cardinal; const SectorSize: Word; const Compressed: Boolean): TTestResult;
    function  LoadImage(const FileName: String; const Handle: THandle; const Size: Int64; const IdealBlockSize: Cardinal; const SectorSize: Word; const Compressed: Boolean): TTestResult;
    function  FullErase(const Handle: THandle; const Size: Int64; const IdealBlockSize: Cardinal; const TestNumber: Integer; const FillData: TBytes): TTestResult;
//    function  CompareMem(const p1, p2: pointer; const Size: Cardinal): integer;
    function  CompareMemWith(const p: pointer; const Size: Integer; const Pattern: byte): integer;
    function  InitDisk(const Handle: THandle; const Size: Int64; const IdealBlockSize: Cardinal): TTestResult;
    function  CalcCRC(const Data: pointer; const Size: Integer; const PrevCRC: Cardinal = $FFFFFFFF): Cardinal;
    procedure Remount(const Handle: THandle; const Timeout: Byte = 5);

    function  GetSwitch(const Name: string; const Position: Integer; out Value: string): Boolean;
    function  GetIntSwitch(const Name: string; const Position: Integer; const Default: Integer): Integer;
    function  GetStrSwitch(const Name: string; const Position: Integer; const Default: string): string;
    function  IsSwitch(const Name: string; const Position: Integer): Boolean;
    function  SIf(const Expr: Boolean; const IfTrue, IfFalse: string): string;
    function  FormatTime(const Msecs: Cardinal): string;

    procedure BeginInit;
    procedure ProcessAutomationCmdLine;
    function  Min64(const Arg1, Arg2: Int64): Int64;
//    function  Max64(const Arg1, Arg2: Int64): Int64;
    function  Min32(const Arg1, Arg2: integer): integer;
    function  Max32(const Arg1, Arg2: integer): integer;
    function  StrToHexArray(const Hex: string): TBytes;
    procedure Test;
    procedure AddDiagMessage(const Text: string; const Color: TColor; const WriteLogFileIfOpened: Boolean = True);
    function  IntToBin(const Data: byte): string;
    function  GetFSLimit(const FSName: string): Int64;
  public
    FMui: TMUI;
    function  SafeFormat(const Text: string; Args: array of const): string;
    procedure FixComboBox(const Combobox: TComboBox);
  end;

var
  fMain: TfMain;

implementation

{$R *.dfm}

uses
  ComObj, ActiveX, UrlMon, IOCtl, PartForm;

type
  TFSLimit = record
    Name: string;
    Limit: Int64;
  end;

const
  FSLimits: array[0..1] of TFSLimit = ((Name: 'FAT'; Limit: Int64(2*1024)*MByte-1),
                                       (Name: 'FAT32'; Limit: $FFA00000));

const
  TmpFileName = '$chkflsh.tmp';
  SmallPattern = $AA;

function TfMain.CheckDrive(const Number: Integer; var Size: Int64; var DriveType: Integer): Boolean;
var
  Res: Cardinal;
  PI: TPARTITION_INFORMATION;
  DG: TDISK_GEOMETRY;
  Handle: THandle;
begin
  Result:= False;
  Handle:= CreateFile(PChar('\\.\PHYSICALDRIVE'+IntToStr(Number)), GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE, nil, OPEN_EXISTING, FILE_FLAG_NO_BUFFERING or FILE_FLAG_WRITE_THROUGH or FILE_FLAG_SEQUENTIAL_SCAN, 0);
  if Handle <> INVALID_HANDLE_VALUE then
    begin
      if DeviceIoControl(Handle, IOCTL_DISK_GET_DRIVE_GEOMETRY, nil, 0, @DG, SizeOf(DG), Res, nil) then
        begin
          if DeviceIoControl(Handle, IOCTL_DISK_GET_PARTITION_INFO, nil, 0, @PI, SizeOf(PI), Res, nil) then
            Size:= PI.PartitionLength
          else
            Size:= DG.Cylinders*DG.TracksPerCylinder*DG.SectorsPerTrack*DG.BytesPerSector;
          DriveType:= DG.MediaType;
          Result:= True;
        end
      else
        begin
          //ShowMessage(SysErrorMessage(GetLastError));
          Size:= -1;
          DriveType:= 11;
        end;
      DiskClose(Handle);
    end;
end;

function TfMain.DriveOpen(const Number: Integer; const Mode: Cardinal; var Size: Int64; var IdealBlockSize: Cardinal; var SectorSize: Word): THandle;
var
  Res: Cardinal;
  PI: TPARTITION_INFORMATION;
  DG: TDISK_GEOMETRY;
begin
  if Number <> High(Number) then
    Result:= CreateFile(PChar('\\.\PHYSICALDRIVE'+IntToStr(Number)), Mode, FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE, nil, OPEN_EXISTING, FILE_FLAG_NO_BUFFERING or FILE_FLAG_WRITE_THROUGH or FILE_FLAG_SEQUENTIAL_SCAN, 0)
  else
    begin
      SetLastError(ERROR_BAD_DEVICE);
      Result:= INVALID_HANDLE_VALUE;
    end;

  if Result <> INVALID_HANDLE_VALUE then
    begin
      if DeviceIoControl(Result, IOCTL_DISK_GET_DRIVE_GEOMETRY, nil, 0, @DG, SizeOf(DG), Res, nil) then
        begin
          IdealBlockSize:= DG.SectorsPerTrack*DG.BytesPerSector;
          SectorSize := DG.BytesPerSector;
          if DeviceIoControl(Result, IOCTL_DISK_GET_PARTITION_INFO, nil, 0, @PI, SizeOf(PI), Res, nil) then
            Size:= PI.PartitionLength
          else
            Size:= DG.Cylinders*DG.TracksPerCylinder*DG.SectorsPerTrack*DG.BytesPerSector;
        end
      else
        begin
          Res:= GetLastError;
          DiskClose(Result);
          SetLastError(Res);
          Result:= INVALID_HANDLE_VALUE;
        end;
    end;
end;

procedure TfMain.edPatternKeyPress(Sender: TObject; var Key: Char);
begin
  if not (Upcase(Key) in ['0'..'9', 'A'..'F', #$08]) then
    begin
      Key:= #00;
      Beep;
    end;
end;

function TfMain.TempOpen(const Letter: Char; const Mode: Cardinal; const LeaveFile: Boolean; var Size: Int64; var IdealBlockSize: Cardinal; var SectorSize: Word): THandle;
var
  All, Limit: Int64;
  pVolName, pFSName: array[Byte] of Char;
  Disposition, Flags, tmp: Cardinal;
begin
  if not (Upcase(Letter) in ['A'..'Z']) then
    begin
      SetLastError(ERROR_INVALID_DRIVE);
      Result:= INVALID_HANDLE_VALUE;
    end
  else
    if GetDiskFreeSpaceEx(PChar(Letter+':\'), Size, All, nil) then
      begin
        if Mode <> GENERIC_READ then
          begin
            if GetVolumeInformation(PChar(Letter+':\'), pVolName, SizeOf(pVolName), nil, tmp, tmp, pFSName, SizeOf(pFSName)) then
              Limit:= GetFSLimit(StrPas(pFSName))
            else
              Limit:= 0;

            if (Limit > 0) and (Size > Limit) then
              begin
                Size:= Limit;
                if not FSilent then
                  Application.MessageBox(PChar(SafeFormat(FMui.Translate('tstFileSizeLimit', 'Used file system does not support the desired file size and in the selected access type will be tested only %n MBytes.'), [Size/MByte])), PChar(FMui.Translate('tstWarning', 'Warning')), MB_OK+MB_ICONINFORMATION);
              end
            else
              if (Size < All-(All div 100)) and (not FSilent) then
                Application.MessageBox(PChar(FMui.Translate('tstDriveNotEmpty', 'Drive is not empty, complete space test will impossible.')), PChar(FMui.Translate('tstWarning', 'Warning')), MB_OK+MB_ICONINFORMATION);

            Disposition:= CREATE_ALWAYS;
          end
        else
          Disposition:= OPEN_EXISTING;

        Flags:= FILE_ATTRIBUTE_TEMPORARY or FILE_FLAG_NO_BUFFERING or FILE_FLAG_WRITE_THROUGH or FILE_FLAG_SEQUENTIAL_SCAN;
        if not LeaveFile then Flags:= Flags or FILE_FLAG_DELETE_ON_CLOSE;

        IdealBlockSize:= SizeOf(TSector);
        SectorSize := SizeOf(TSector);
        Result:= CreateFile(PChar(Letter+':\'+TmpFileName), Mode, 0, nil, Disposition, Flags, 0);

        if (Result <> INVALID_HANDLE_VALUE) and (Disposition = OPEN_EXISTING) then PCardinal(@Size)^:= GetFileSize(Result, Pointer(Integer(@Size)+SizeOf(Cardinal)));
      end
    else
      Result:= INVALID_HANDLE_VALUE;
end;

function TfMain.PartOpen(const Letter: char; const Mode: Cardinal; var Size: Int64; var IdealBlockSize: Cardinal; var SectorSize: Word): THandle;
var
  Res: Cardinal;
  PI: TPARTITION_INFORMATION;
  DG: TDISK_GEOMETRY;
begin
  if Upcase(Letter) in ['A'..'Z'] then
    Result:= CreateFile(PChar('\\.\'+Letter+':'), Mode, 0, nil, OPEN_EXISTING, FILE_FLAG_NO_BUFFERING or FILE_FLAG_WRITE_THROUGH or FILE_FLAG_SEQUENTIAL_SCAN, 0)
  else
    begin
      SetLastError(ERROR_INVALID_DRIVE);
      Result:= INVALID_HANDLE_VALUE;
    end;

  if Result <> INVALID_HANDLE_VALUE then
    begin
      if DeviceIoControl(Result, IOCTL_DISK_GET_DRIVE_GEOMETRY, nil, 0, @DG, SizeOf(DG), Res, nil) then
        begin
          IdealBlockSize:= DG.SectorsPerTrack*DG.BytesPerSector;
          SectorSize := DG.BytesPerSector;
          if DeviceIoControl(Result, IOCTL_DISK_GET_PARTITION_INFO, nil, 0, @PI, SizeOf(PI), Res, nil) then
            Size:= PI.PartitionLength
          else
            Size:= DG.Cylinders*DG.TracksPerCylinder*DG.SectorsPerTrack*DG.BytesPerSector;
        end
      else
        begin
          Res:= GetLastError;
          DiskClose(Result);
          SetLastError(Res);
          Result:= INVALID_HANDLE_VALUE;
        end;
    end;
end;

procedure TfMain.ProcessAutomationCmdLine;
var
  rb: TRadioButton;
  cb: TComboBox;
  Drive: string;
  i: Integer;
begin
  case GetIntSwitch('/ACCESS', 1, 0) of
    0: rb:= rbTempFile;
    1: rb:= rbLogical;
    2: rb:= rbPhysical;
  else
    rb:= nil;
  end;
  if Assigned(rb) and rb.Enabled and not rb.Checked then rb.Checked:= True;

  case GetIntSwitch('/ACTION', 1, 0) of
    0: rb:= rbReadTest;
    1: rb:= rbWriteTest;
    2: rb:= rbPartEdit;
    3: rb:= rbSave;
    4: rb:= rbLoad;
    5: rb:= rbErase;
  else
    rb:= nil;
  end;
  if Assigned(rb) and rb.Enabled and not rb.Checked then
    begin
      rb.Checked:= True;
      sbActionType.VertScrollBar.Position:= rb.Top+rb.Height-sbActionType.Height;
    end;

  case GetIntSwitch('/PATTERN', 1, 0) of
    0: rb:= rbSmallPattern;
    1: rb:= rbFullPattern;
    2: rb:= rbDelayedWrite;
    3: rb:= rbDelayedVerify;
  else
    rb:= nil;
  end;
  if Assigned(rb) and not rb.Checked then rb.Checked:= True;

  case GetIntSwitch('/TESTLEN', 1, 0) of
    0: rb:= rbOnePass;
    1: rb:= rbContinous;
    2: rb:= rbManual;
    3: rb:= rbTillError;
  else
    rb:= nil;
  end;
  if Assigned(rb) and rb.Enabled and not rb.Checked then rb.Checked:= True;

  if IsSwitch('/NOSCROLL', 1) then cbScrollLog.Checked:= False;

  edPattern.Text:= Trim(GetStrSwitch('/ERASEPATTERN', 1, edPattern.Text));
  cbPattern.ItemIndex:= cbPattern.Items.IndexOf(UpperCase(Trim(GetStrSwitch('/DELAYED', 1, cbPattern.Items[0]))));
  seCycles.Value:= GetIntSwitch('/TESTCOUNT', 1, 1);
  FSupressWarning:= IsSwitch('/SURE', 1);
  FDefFileName:= Trim(GetStrSwitch('/FILE', 1, ''));
  FSilent:= IsSwitch('/SILENT', 1);
  FQuitOnDone:= False;

  Drive:= Trim(GetStrSwitch('/LOG', 1, ''));
  if Drive <> '' then
    begin
      New(FLogFile);
      AssignFile(FLogFile^, Drive);
      try
        if FileExists(Drive) then
          Append(FLogFile^)
        else
          Rewrite(FLogFile^);
      except
        on E: Exception do
          begin
            Application.MessageBox(PChar(SafeFormat(FMui.Translate('tstLogOpenError', 'Create/open log file error: %s'), [E.Message])), PChar(FMui.Translate('tstError', 'Error')), MB_OK or MB_ICONWARNING);
            Dispose(FLogFile);
            FLogFile:= nil;
          end;
      end;
    end
  else
    FLogFile:= nil;

  Drive:= UpperCase(Copy(Trim(GetStrSwitch('/START', 1, '')), 1, 3));
  if Drive <> '' then
    begin
      if not (Drive[Length(Drive)] in [':', '\']) then Drive:= Drive+':';

      case pcDeviceSelect.ActivePageIndex of
        0: cb:= cbDrive;
        1: cb:= cbDevice;
      else
        cb:= nil;
      end;

      if Assigned(cb) then
        begin
          i:= cb.Items.Count-1;
          while i >= 0 do
            if Pos(Drive, cb.Items[i]) = 1 then
              begin
                cb.ItemIndex:= i;
                i:= -2;
              end
            else
              Dec(i);

          if i = -2 then
            if btnStart.Enabled then
              begin
                FQuitOnDone:= IsSwitch('/QUIT', 1);
                PostMessage(btnStart.Handle, WM_LBUTTONDOWN, 0, 0);
                PostMessage(btnStart.Handle, WM_LBUTTONUP, 0, 0);
              end
            else
          else
            Application.MessageBox(PChar(SafeFormat(FMui.Translate('tstDriveNotFound', 'Drive "%s" not found!'), [Drive])), PChar(FMui.Translate('tstError', 'Error')), MB_OK or MB_ICONHAND);
        end;
    end;

  if cbPattern.ItemIndex = -1 then cbPattern.ItemIndex:= 0;
end;

procedure TfMain.DiskClose(const Handle: THandle);
begin
  FileClose(Handle);
end;

procedure TfMain.BeginInit;
var
  Ver: TOSVersionInfo;
  Buffer: array [0..4095] of Char;
  pStr1, pStr2: array [Byte] of Char;
  s, Detail: string;
  i, Len, Item: Integer;
  Tmp: Cardinal;
  Size: Int64;

  WMIService: IDispatch;
  DeviceList, Device: OleVariant;
  Enum: IEnumVARIANT;
  Ctx: IBindCtx;
  Mk: IMoniker;
  Value: Cardinal;
begin
  AllDrives:= IsSwitch('/ALL', 1);
  Item:= cbDrive.ItemIndex;
  cbDrive.Items.Clear;
  Len:= GetLogicalDriveStrings(SizeOf(Buffer), Buffer);
  if Len <= SizeOf(Buffer) then
    begin
      i:= 0;
      while i <= Len do
        begin
          s:= '';
          while (i <= Len) and (Buffer[i] <> #0) do
            begin
              s:= s+Upcase(Buffer[i]);
              inc(i);
            end;
          if s <> '' then
            begin
              if (GetDriveType(PChar(s)) = DRIVE_REMOVABLE) or AllDrives then
                begin
                  Detail:= ' - ';
                  if GetVolumeInformation(PChar(s), @pStr1, SizeOf(pStr1), nil, Tmp, Tmp, @pStr2, SizeOf(pStr2)) then
                    begin
                      if StrLen(pStr1) > 0 then
                        Detail:= Detail+'"'+StrPas(pStr1)+'" '
                      else
                        Detail:= Detail+FMui.Translate('tstNoLabel', '<NO LABEL>')+#32;

                      if StrLen(pStr2) > 0 then
                        Detail:= Detail+'['+StrPas(pStr2)+']'
                      else
                        Detail:= Detail+FMui.Translate('tstNotFormatted', '<NOT FORMATTED>');
                    end
                  else
                    Detail:= Detail+FMui.Translate('tstNotFormattedNoMedia', '<NOT FORMATTED OR NO MEDIA>');

                  cbDrive.Items.AddObject(s+Detail, Pointer(Byte(s[1])));
                end;
            end;
          inc(i);
        end;
    end;
  cbDrive.ItemIndex:= Item;

  Item:= cbDevice.ItemIndex;
  cbDevice.Items.Clear;
  if not IsSwitch('/NOWMI', 1) and
     Succeeded(CreateBindCtx(0, Ctx)) and
     Succeeded(MkParseDisplayNameEx(Ctx, 'winmgmts:\\.\root\cimv2', Tmp, Mk)) and
     Succeeded(Mk.BindToObject(Ctx, nil, IUnknown, WMIService)) then
    begin
      DeviceList:= OleVariant(WMIService).ExecQuery('SELECT * FROM Win32_DiskDrive WHERE StatusInfo <> 4');
      Enum:= IUnknown(DeviceList._NewEnum) as IEnumVariant;
      while Enum.Next(1, Device, Value) = 0 do
        begin
          if (UpperCase(Copy(Device.DeviceID, 1, 17)) = '\\.\PHYSICALDRIVE') and
             (AllDrives or
             ((Device.MediaType <> Null) and
              (Device.MediaType <> Unassigned) and
              ((UpperCase(Copy(Device.MediaType, 1, 9)) = 'REMOVABLE') or
               (UpperCase(Copy(Device.MediaType, 1, 8)) = 'EXTERNAL')))) then
            begin
              s:= Copy(Device.DeviceID, 18, $FF);
              Detail:= ' - ';
              if (Device.Caption <> Null) and (Device.Caption <> Unassigned) and (Device.Caption <> '') then
                Detail:= Detail+'"'+Device.Caption+'" ';
              Detail:= Detail+'[';
              if (Device.InterfaceType <> Null) and (Device.InterfaceType <> Unassigned) and (Device.InterfaceType <> '') then
                Detail:= Detail+Device.InterfaceType+'; ';
              if (Device.Size <> Null) and (Device.Size <> Unassigned) and (Device.Size >= 0) then
                Detail:= Detail+SafeFormat(FMui.Translate('tstXMB', '%n MB'), [Double(Device.Size/MByte)])
              else
                Detail:= Detail+FMui.Translate('tstNoMedia', '<NO MEDIA>');
              Detail:= Detail+']';

              cbDevice.Items.AddObject(s+':\'+Detail, Pointer(StrToIntDef(s, High(Integer))));
            end;
          Device:= Unassigned;
        end;
      DeviceList:= Unassigned;
      WMIService:= Unassigned;
    end
  else
    for i:= 0 to 255 do
      if CheckDrive(i, Size, Len) then
        if ((Len >= 1) and (Len <= 11)) or AllDrives then
          if Size > -1 then
            cbDevice.Items.AddObject(inttostr(i)+':\ - ['+SafeFormat(FMui.Translate('tstXMB', '%n MB'), [Size/MByte])+']', Pointer(i))
          else
            cbDevice.Items.AddObject(inttostr(i)+':\ - '+FMui.Translate('tstNoMedia', '<NO MEDIA>'), Pointer(i));
  cbDevice.ItemIndex:= Item;

  if cbDrive.Items.Count > 0 then
    begin
      if pcDeviceSelect.ActivePageIndex = 0 then btnStart.Enabled:= True;
      if cbDrive.ItemIndex = -1 then cbDrive.ItemIndex:= 0;
    end;
  if cbDevice.Items.Count > 0 then
    begin
      if pcDeviceSelect.ActivePageIndex = 1 then btnStart.Enabled:= True;
      if cbDevice.ItemIndex = -1 then cbDevice.ItemIndex:= 0;
    end;

  Ver.dwOSVersionInfoSize:= SizeOf(Ver);
  if GetVersionEx(Ver) then
    rbPhysical.Enabled:= (Ver.dwPlatformId = VER_PLATFORM_WIN32_NT)
  else
    rbPhysical.Enabled:= False;
  rbLogical.Enabled:= rbPhysical.Enabled;
end;

function TfMain.CalcCRC(const Data: pointer; const Size: Integer; const PrevCRC: Cardinal = $FFFFFFFF): Cardinal;
const
  CRC32Table: array [Byte] of Cardinal = (
    $00000000, $77073096, $EE0E612C, $990951BA,
    $076DC419, $706AF48F, $E963A535, $9E6495A3,
    $0EDB8832, $79DCB8A4, $E0D5E91E, $97D2D988,
    $09B64C2B, $7EB17CBD, $E7B82D07, $90BF1D91,
    $1DB71064, $6AB020F2, $F3B97148, $84BE41DE,
    $1ADAD47D, $6DDDE4EB, $F4D4B551, $83D385C7,
    $136C9856, $646BA8C0, $FD62F97A, $8A65C9EC,
    $14015C4F, $63066CD9, $FA0F3D63, $8D080DF5,
    $3B6E20C8, $4C69105E, $D56041E4, $A2677172,
    $3C03E4D1, $4B04D447, $D20D85FD, $A50AB56B,
    $35B5A8FA, $42B2986C, $DBBBC9D6, $ACBCF940,
    $32D86CE3, $45DF5C75, $DCD60DCF, $ABD13D59,
    $26D930AC, $51DE003A, $C8D75180, $BFD06116,
    $21B4F4B5, $56B3C423, $CFBA9599, $B8BDA50F,
    $2802B89E, $5F058808, $C60CD9B2, $B10BE924,
    $2F6F7C87, $58684C11, $C1611DAB, $B6662D3D,
    $76DC4190, $01DB7106, $98D220BC, $EFD5102A,
    $71B18589, $06B6B51F, $9FBFE4A5, $E8B8D433,
    $7807C9A2, $0F00F934, $9609A88E, $E10E9818,
    $7F6A0DBB, $086D3D2D, $91646C97, $E6635C01,
    $6B6B51F4, $1C6C6162, $856530D8, $F262004E,
    $6C0695ED, $1B01A57B, $8208F4C1, $F50FC457,
    $65B0D9C6, $12B7E950, $8BBEB8EA, $FCB9887C,
    $62DD1DDF, $15DA2D49, $8CD37CF3, $FBD44C65,
    $4DB26158, $3AB551CE, $A3BC0074, $D4BB30E2,
    $4ADFA541, $3DD895D7, $A4D1C46D, $D3D6F4FB,
    $4369E96A, $346ED9FC, $AD678846, $DA60B8D0,
    $44042D73, $33031DE5, $AA0A4C5F, $DD0D7CC9,
    $5005713C, $270241AA, $BE0B1010, $C90C2086,
    $5768B525, $206F85B3, $B966D409, $CE61E49F,
    $5EDEF90E, $29D9C998, $B0D09822, $C7D7A8B4,
    $59B33D17, $2EB40D81, $B7BD5C3B, $C0BA6CAD,
    $EDB88320, $9ABFB3B6, $03B6E20C, $74B1D29A,
    $EAD54739, $9DD277AF, $04DB2615, $73DC1683,
    $E3630B12, $94643B84, $0D6D6A3E, $7A6A5AA8,
    $E40ECF0B, $9309FF9D, $0A00AE27, $7D079EB1,
    $F00F9344, $8708A3D2, $1E01F268, $6906C2FE,
    $F762575D, $806567CB, $196C3671, $6E6B06E7,
    $FED41B76, $89D32BE0, $10DA7A5A, $67DD4ACC,
    $F9B9DF6F, $8EBEEFF9, $17B7BE43, $60B08ED5,
    $D6D6A3E8, $A1D1937E, $38D8C2C4, $4FDFF252,
    $D1BB67F1, $A6BC5767, $3FB506DD, $48B2364B,
    $D80D2BDA, $AF0A1B4C, $36034AF6, $41047A60,
    $DF60EFC3, $A867DF55, $316E8EEF, $4669BE79,
    $CB61B38C, $BC66831A, $256FD2A0, $5268E236,
    $CC0C7795, $BB0B4703, $220216B9, $5505262F,
    $C5BA3BBE, $B2BD0B28, $2BB45A92, $5CB36A04,
    $C2D7FFA7, $B5D0CF31, $2CD99E8B, $5BDEAE1D,
    $9B64C2B0, $EC63F226, $756AA39C, $026D930A,
    $9C0906A9, $EB0E363F, $72076785, $05005713,
    $95BF4A82, $E2B87A14, $7BB12BAE, $0CB61B38,
    $92D28E9B, $E5D5BE0D, $7CDCEFB7, $0BDBDF21,
    $86D3D2D4, $F1D4E242, $68DDB3F8, $1FDA836E,
    $81BE16CD, $F6B9265B, $6FB077E1, $18B74777,
    $88085AE6, $FF0F6A70, $66063BCA, $11010B5C,
    $8F659EFF, $F862AE69, $616BFFD3, $166CCF45,
    $A00AE278, $D70DD2EE, $4E048354, $3903B3C2,
    $A7672661, $D06016F7, $4969474D, $3E6E77DB,
    $AED16A4A, $D9D65ADC, $40DF0B66, $37D83BF0,
    $A9BCAE53, $DEBB9EC5, $47B2CF7F, $30B5FFE9,
    $BDBDF21C, $CABAC28A, $53B39330, $24B4A3A6,
    $BAD03605, $CDD70693, $54DE5729, $23D967BF,
    $B3667A2E, $C4614AB8, $5D681B02, $2A6F2B94,
    $B40BBE37, $C30C8EA1, $5A05DF1B, $2D02EF8D);
var
  i: Integer;
begin
  Result:= PrevCRC;
  for i:= 0 to Size-1 do
    Result:= (Result shr 8) xor CRC32Table[PByte(Integer(Data)+i)^ xor Byte(Result and $000000FF)];
end;

procedure TfMain.cbDriveDropDown(Sender: TObject);
begin
  FixComboBox(Sender as TComboBox);
end;

function TfMain.ReadTest(const Handle: THandle; const Size: Int64; const IdealBlockSize: Cardinal; const PerformPrepearing: boolean; var CRC: Cardinal): TTestResult;
var
  i, Cnt, Res, NextStart, RBytes: Int64;
  Buffer: Pointer;
  BufferSize, tc, NewCRC, RTime: Cardinal;
begin
  if (Handle <> INVALID_HANDLE_VALUE) and (Size > 0) then
    begin
      Result.ResultCode:= rtOk;
      Result.ResultString:= '';
      Result.ErrorsCount:= 0;
      Stop:= False;
      Res:= 0;
      Cnt:= 0;
      NextStart:= 0;
      RBytes:= 0;
      RTime:= 0;
      NewCRC:= InitCRC;

      DriveMap.MinUnitPerBlock:= IdealBlockSize;
      DriveMap.Max:= Size;
      lblBlockWeight.Caption:= SafeFormat(FMui.Translate('tstBlockWeight', '1 block = %d sectors'), [DriveMap.UnitPerBlock div SizeOf(TSector)]);
      BufferSize:= Min64(DriveMap.UnitPerBlock, RoundTo(MByte, IdealBlockSize, False));
      GetMem(Buffer, BufferSize);

      if PerformPrepearing then
        begin
          CRC:= NewCRC;
          DriveMap.Reset;
          pbMain.Max:= (Size div ProgressStep)*2;
          pbMain.Position:= pbMain.Min;
          lblStage.Caption:= FMui.Translate('tstReading', 'Reading');
          Application.ProcessMessages;

          FileSeek(Handle, 0, 0);
          i:= 0;
          repeat
            Cnt:= Min64(BufferSize, Size-i);
            tc:= GetTickCount;
            Res:= FileRead(Handle, Buffer^, Cnt);
            tc:= Max32(GetTickCount-tc, 1);
            Inc(i, Cnt);

            if Res = Cnt then
              begin
                Inc(RBytes, Res);
                Inc(RTime, tc);
                //lblReadSpeed.Caption:= SafeFormat(FMui.Translate('tstXMBpS', '%n MB/s'), [(RBytes/Mbyte)/(RTime/1000)]);
                FReadSpeed:= (RBytes/Mbyte)/(RTime/1000);
                CRC:= CalcCRC(Buffer, Res, CRC);

                DriveMap.Blocks[i].Color:= clBlue;
              end
            else
              DriveMap.Blocks[i].Color:= clRed;
            pbMain.Position:= NextStart+(i div ProgressStep);
            Application.ProcessMessages;
          until (Cnt < BufferSize) or (Res <> Cnt) or Stop;
          Inc(NextStart, i div ProgressStep);
        end
      else
        begin
          DriveMap.Reset;
          pbMain.Max:= Size div ProgressStep;
          pbMain.Position:= pbMain.Min;
          Application.ProcessMessages;
        end;

      if (not Stop) and (Result.ResultCode = rtOk) and (Res = Cnt) then
        begin
          DriveMap.Reset;
          lblStage.Caption:= FMui.Translate('tstVerifying', 'Verifying');
          Application.ProcessMessages;

          FileSeek(Handle, 0, 0);
          i:= 0;
          repeat
            Cnt:= Min64(Size-i, BufferSize);
            tc:= GetTickCount;
            Res:= FileRead(Handle, Buffer^, Cnt);
            tc:= Max32(GetTickCount-tc, 1);
            Inc(i, Cnt);

            if Res = Cnt then
              begin
                Inc(RBytes, Res);
                Inc(RTime, tc);
                //lblReadSpeed.Caption:= SafeFormat(FMui.Translate('tstXMBpS', '%n MB/s'), [(RBytes/Mbyte)/(RTime/1000)]);
                FReadSpeed:= (RBytes/Mbyte)/(RTime/1000);
                NewCRC:= CalcCRC(Buffer, Res, NewCRC);

                DriveMap.Blocks[i].Color:= clGreen;
              end
            else
              DriveMap.Blocks[i].Color:= clRed;
            pbMain.Position:= NextStart+(i div ProgressStep);
            Application.ProcessMessages;
          until (Cnt < BufferSize) or (Res <> Cnt) or (Stop);
        end;
      FreeMem(Buffer, BufferSize);

      if Res <> Cnt then
        begin
          Result.ResultCode:= rtReadFail;
          if Res <> -1 then
            Result.ResultString:= Result.ResultString+SafeFormat(FMui.Translate('tstReadError', 'Device read error, only %d from %d bytes was read.'), [Res, Cnt])
          else
            Result.ResultString:= Result.ResultString+SafeFormat(FMui.Translate('tstTotalReadError', 'Device read error: %s'), [SysErrorMessage(GetLastError)]);
        end
      else
        if Stop then
          Result.ResultCode:= rtUserInterrupt
        else
          if CRC <> NewCRC then
            begin
              AddDiagMessage(FMui.Translate('tstCRCError', 'CRC error detected.'), clRed);
              inc(Result.ErrorsCount);
              Result.ResultString:= FMui.Translate('tstErrorsFound', 'One or more errors found.');
            end;
    end
  else
    begin
      Result.ResultCode:= rtGenericFail;
      Result.ResultString:= FMui.Translate('tstInvalidHanle', 'Invalid handle.');
      Result.ErrorsCount:= 0;
    end;
end;

procedure TfMain.Remount(const Handle: THandle; const Timeout: Byte);
var
  i: Byte;
  Res: Cardinal;
begin
  i:= 0;
  while (i < TimeOut) and not DeviceIoControl(Handle, FSCTL_Dismount_Volume, nil, 0, nil, 0, Res, nil) do
    begin
      Sleep(1000);
      Inc(i);
    end;
  if not FSilent then
    Application.MessageBox(PChar(FMui.Translate('tstReplug', 'Please replug device now (without dismounting) and press "OK".')), PChar(FMui.Translate('tstInfo', 'Info')), MB_OK+MB_ICONINFORMATION);
  BeginInit;
end;

function TfMain.RescueFileRead(const Handle: Integer; var Buffer; const Cnt: Cardinal; const SectorSize: Word; out Fails: Word): Integer;
begin
  Result := FileRead(Handle, Buffer, Cnt);
  if Result = Integer(Cnt) then
    Fails := 0
  else
    if (Cnt > SectorSize) and (Cnt mod SectorSize = 0) then
      begin
        Fails := 0;
        Result := 0;

        while Result < Integer(Cnt) do
          begin
            if FileRead(Handle, Pointer(NativeInt(@Buffer) + Result)^, SectorSize) <> SectorSize then
              begin
                Inc(Fails);
                FileSeek(Handle, SectorSize, soFromCurrent);
                ZeroMemory(Pointer(NativeInt(@Buffer) + Result), SectorSize);
              end;

            Inc(Result, SectorSize);
          end;
      end
    else
      Fails := 1;
end;

function TfMain.WriteTest(const Handle: THandle; const Size: Int64; const IdealBlockSize: Cardinal; const WriteType: TWriteType; const ManualPattern: Byte): TTestResult;
//----------------------
procedure Rol(var Data: byte); assembler;
asm
  rol           BYTE PTR [Data], 1
end;
//----------------------
var
  i, Cnt, Res, DiffPos, NextStart, RBytes, WBytes: Int64;
  Buffer: Pointer;
  tc, BufferSize, RTime, WTime: Cardinal;
  Pattern: Byte;
  TestEnd: Boolean;
  FullPatternStage: (fpWalkOne, fpWalkZero, fpInterleave);
begin
  if (Handle <> INVALID_HANDLE_VALUE) and (Size > 0) then
    begin
      Result.ResultCode:= rtOk;
      Result.ResultString:= '';
      Result.ErrorsCount:= 0;
      Stop:= False;
      TestEnd:= False;
      RBytes:= 0;
      RTime:= 0;
      WBytes:= 0;
      WTime:= 0;
      Pattern:= 0;
      NextStart:= 0;

      DriveMap.MinUnitPerBlock:= IdealBlockSize;
      DriveMap.Max:= Size;
      lblBlockWeight.Caption:= SafeFormat(FMui.Translate('tstBlockWeight', '1 block = %d sectors'), [DriveMap.UnitPerBlock div SizeOf(TSector)]);
      BufferSize:= Min32(DriveMap.UnitPerBlock, RoundTo(MByte, IdealBlockSize, False));
      GetMem(Buffer, BufferSize);

      pbMain.Position:= pbMain.Min;
      FullPatternStage:= fpWalkOne;
      case WriteType of
        wtSmallPattern:
          begin
            Pattern:= SmallPattern;
            pbMain.Max:= (Size div ProgressStep)*2*2;
          end;
        wtFullPattern:
          begin
            Pattern:= $01;
            pbMain.Max:= (Size div ProgressStep)*(8+8+2)*2;
          end;
        wtWriteManual,
        wtVerifyManual:
          begin
            Pattern:= ManualPattern;
            pbMain.Max:= Size div ProgressStep;
          end;
      end;

      repeat
        if WriteType <> wtVerifyManual then
          begin
            lblStage.Caption:= FMui.Translate('tstWriting', 'Writing');
            Application.ProcessMessages;

            FileSeek(Handle, 0, 0);
            FillMemory(Buffer, BufferSize, Pattern);
            DriveMap.Reset;

            i:= 0;
            repeat
              Cnt:= Min64(BufferSize, Size-i);
              tc:= GetTickCount;
              Res:= FileWrite(Handle, Buffer^, Cnt);
              tc:= Max32(GetTickCount-tc, 1);
              Inc(i, Cnt);
              if Res = Cnt then
                begin
                  Inc(WBytes, Res);
                  Inc(WTime, tc);
                  //lblWriteSpeed.Caption:= SafeFormat(FMui.Translate('tstXMBpS', '%n MB/s'), [(WBytes/Mbyte)/(WTime/1000)]);
                  FWriteSpeed:= (WBytes/Mbyte)/(WTime/1000);
                  DriveMap.Blocks[i].Color:= clPurple;
                end
              else
                begin
                  DriveMap.Blocks[i].Color:= clRed;
                  AddDiagMessage(SafeFormat(FMui.Translate('tstWriteErrorAtRange', 'Error at range [%.8xh..%.8xh]: device write error.'), [i-Cnt, i]), clRed);
                  Result.ResultString:= FMui.Translate('tstErrorsFound', 'One or more errors found.');
                  Inc(Result.ErrorsCount);
                  lblErrorsFound.Caption:= inttostr(Result.ErrorsCount);
                  FileSeek(Handle, i, 0);
                end;
              pbMain.Position:= NextStart+(i div ProgressStep);
              Application.ProcessMessages;
            until (Cnt < BufferSize) or Stop;
            FlushFileBuffers(Handle);
            Inc(NextStart, i div ProgressStep);
          end;

        if (WriteType <> wtWriteManual) and (not Stop) and (Result.ResultCode = rtOk) then
          begin
            lblStage.Caption:= FMui.Translate('tstVerifying', 'Verifying');
            if WriteType = wtVerifyManual then DriveMap.Reset;
            Application.ProcessMessages;

            FileSeek(Handle, 0, 0);
            i:= 0;
            repeat
              Cnt:= Min64(Size-i, BufferSize);
              tc:= GetTickCount;
              Res:= FileRead(Handle, Buffer^, Cnt);
              tc:= Max32(GetTickCount-tc, 1);
              Inc(i, Cnt);

              if Res = Cnt then
                begin
                  Inc(RBytes, Res);
                  Inc(RTime, tc);
                  //lblReadSpeed.Caption:= SafeFormat(FMui.Translate('tstXMBpS', '%n MB/s'), [(RBytes/Mbyte)/(RTime/1000)]);
                  FReadSpeed:= (RBytes/Mbyte)/(RTime/1000);
                  DiffPos:= CompareMemWith(Buffer, Res, Pattern);
                  //if Random(20) = 0 then DiffPos:= Random(Cnt);
                  if DiffPos <> -1 then
                    begin
                      AddDiagMessage(SafeFormat(FMui.Translate('tstErrorAtExpectedFound', 'Error at address %.8xh: expected "%s", found "%s".'), [i-Cnt+DiffPos, IntToBin(Pattern), IntToBin(PByte(Integer(Buffer)+DiffPos)^)]), clRed);
                      Result.ResultString:= FMui.Translate('tstErrorsFound', 'One or more errors found.');
                      DriveMap.Blocks[i].Color:= clYellow;
                      Inc(Result.ErrorsCount);
                      lblErrorsFound.Caption:= inttostr(Result.ErrorsCount);
                    end;
                end
              else
                DiffPos:= -1;

              if DiffPos = -1 then
                if Res = Cnt then
                  DriveMap.Blocks[i].Color:= clGreen
                else
                  begin
                    DriveMap.Blocks[i].Color:= clRed;
                    AddDiagMessage(SafeFormat(FMui.Translate('tstReadErrorAtRange', 'Error at range [%.8xh..%.8xh]: device read error.'), [i-Cnt, i]), clRed);
                    Result.ResultString:= FMui.Translate('tstErrorsFound', 'One or more errors found.');
                    Inc(Result.ErrorsCount);
                    lblErrorsFound.Caption:= inttostr(Result.ErrorsCount);
                    FileSeek(Handle, i, 0);
                  end;
              pbMain.Position:= NextStart+(i div ProgressStep);
              Application.ProcessMessages;
            until (Cnt < BufferSize) or Stop;
            Inc(NextStart, i div ProgressStep);
          end;

        case WriteType of
          wtSmallPattern:
            if Pattern = SmallPattern then
              Pattern:= SmallPattern xor $FF
            else
              TestEnd:= True;
          wtFullPattern:
            case FullPatternStage of
              fpWalkOne:
                if Pattern <> $80 then
                  Rol(Pattern)
                else
                  begin
                    FullPatternStage:= fpWalkZero;
                    Pattern:= $FE;
                  end;
              fpWalkZero:
                if Pattern <> $7F then
                  Rol(Pattern)
                else
                  begin
                    FullPatternStage:= fpInterleave;
                    Pattern:= SmallPattern;
                  end;
              fpInterleave:
                if Pattern = SmallPattern then
                  Pattern:= SmallPattern xor $FF
                else
                  TestEnd:= True;
            end;
          wtWriteManual,
          wtVerifyManual:
            TestEnd:= True;
        end;

      until TestEnd or Stop or (Result.ResultCode <> rtOk);
      FreeMem(Buffer, BufferSize);
      if Stop then Result.ResultCode:= rtUserInterrupt;
    end
  else
    begin
      Result.ResultCode:= rtGenericFail;
      Result.ResultString:= FMui.Translate('tstInvalidHanle', 'Invalid handle.');
      Result.ErrorsCount:= 0;
    end;
end;

function TfMain.SaveImage(const FileName: String; const Handle: THandle; const Size: Int64; const IdealBlockSize: Cardinal; const SectorSize: Word; const Compressed: Boolean): TTestResult;
const
  Warning = 'Do you REALLY want to write over then %d MBytes to the drive %s\ ?';
var
  i, Cnt, Res, RBytes: Int64;
  Buffer: Pointer;
  tc, BufferSize, RTime: Cardinal;
  OutFile: TFileStream;
  Stream: TStream;
  TestEnd: Boolean;
  ZIMHeader: TZIMHeader;
  Fails: Word;
begin
  if Handle <> INVALID_HANDLE_VALUE then
    if (Size <= Int64(MByte)*1024*4) or
       (FSupressWarning or (Application.MessageBox(PChar(SafeFormat(FMui.Translate('tstImgSizeMore', Warning), [Size div MByte, ExtractFileDrive(FileName)])), PChar(FMui.Translate('tstWarning', 'Warning')), MB_YESNO+MB_ICONWARNING) = IDYES)) then
      try
        OutFile:= TFileStream.Create(FileName, fmCreate);
        OutFile.Size:= 0;
        Stop:= False;
        TestEnd:= False;
        try
          Result.ResultCode:= rtOk;
          Result.ResultString:= '';
          Result.ErrorsCount:= 0;
          RBytes:= 0;
          RTime:= 0;
          if Compressed then
            begin
              ZIMHeader.Signature:= ZIMSignature;
              ZIMHeader.Vesion:= ZIMVersion;
              ZIMHeader.Size:= Size;
              if OutFile.Write(ZIMHeader, SizeOf(ZIMHeader)) = SizeOf(ZIMHeader) then
                Stream:= TCompressionStream.Create(clMax, OutFile)
              else
                raise EWriteError.Create('ZIM header write error');  
            end
          else
            Stream:= OutFile;

          DriveMap.MinUnitPerBlock:= IdealBlockSize;
          DriveMap.Max:= Size;
          DriveMap.Reset;
          lblBlockWeight.Caption:= SafeFormat(FMui.Translate('tstBlockWeight', '1 block = %d sectors'), [DriveMap.UnitPerBlock div SizeOf(TSector)]);
          lblStage.Caption:= FMui.Translate('tstReading', 'Reading');
          BufferSize:= Min32(DriveMap.UnitPerBlock, RoundTo(MByte, IdealBlockSize, False));
          GetMem(Buffer, BufferSize);
          FileSeek(Handle, 0, 0);

          pbMain.Max:= Size div ProgressStep;
          pbMain.Position:= pbMain.Min;
          i:= 0;
          repeat
            Cnt:= Min64(BufferSize, Size-i);
            tc:= GetTickCount;
            Res:= RescueFileRead(Handle, Buffer^, Cnt, SectorSize, Fails);
            tc:= Max32(GetTickCount-tc, 1);
            Inc(i, Cnt);
            if Res = Cnt then
              begin
                Inc(RBytes, Res);
                Inc(RTime, tc);
                //lblReadSpeed.Caption:= SafeFormat(FMui.Translate('tstXMBpS', '%n MB/s'), [(RBytes/Mbyte)/(RTime/1000)]);
                FReadSpeed:= (RBytes/Mbyte)/(RTime/1000);
                if Fails > 0 then
                  DriveMap.Blocks[i].Color:= clRed
                else
                  if DriveMap.Blocks[i].Color <> clRed then
                    DriveMap.Blocks[i].Color:= clBlue;
              end
            else
              begin
                DriveMap.Blocks[i].Color:= clRed;
                AddDiagMessage(SafeFormat(FMui.Translate('tstReadErrorAtRange', 'Error at range [%.8xh..%.8xh]: device read error.'), [i-Cnt, i]), clRed);
                Result.ResultString:= FMui.Translate('tstErrorsFound', 'One or more errors found.');
                Inc(Result.ErrorsCount);
                lblErrorsFound.Caption:= inttostr(Result.ErrorsCount);
                ZeroMemory(Buffer, Cnt);
                FileSeek(Handle, i, 0);
              end;
            pbMain.Position:= i div ProgressStep;
            Application.ProcessMessages;

            Res:= Stream.Write(Buffer^, Cnt);
            if Res <> Cnt then
              begin
                AddDiagMessage(SafeFormat(FMui.Translate('tstImgWriteError', 'Error writing image file: %s'), [SysErrorMessage(GetLastError)]), clRed);
                Result.ResultString:= FMui.Translate('tstFileWriteError', 'File write error.');
                TestEnd:= True;
              end;
          until (Cnt < BufferSize) or Stop or TestEnd;
          FreeMem(Buffer, BufferSize);
          if Compressed then Stream.Free;
        finally
          OutFile.Free;
        end;
        if Stop then
          begin
            Result.ResultCode:= rtUserInterrupt;
            DeleteFile(FileName);
          end;
        if TestEnd then
          begin
            Result.ResultCode:= rtWriteFail;
            DeleteFile(FileName);
          end;
      except
        DeleteFile(FileName);
        Result.ResultCode:= rtWriteFail;
        Result.ResultString:= FMui.Translate('tstImgCreateError', 'Error creating image file.');
        Result.ErrorsCount:= 0;
      end
    else
      begin
        Result.ResultCode:= rtUserInterrupt;
        Result.ErrorsCount:= 0;
      end
  else
    begin
      Result.ResultCode:= rtGenericFail;
      Result.ResultString:= FMui.Translate('tstInvalidHanle', 'Invalid handle.');
      Result.ErrorsCount:= 0;
    end;
end;

procedure TfMain.sbRedrivesClick(Sender: TObject);
begin
  BeginInit;
end;

function TfMain.SIf(const Expr: Boolean; const IfTrue, IfFalse: string): string;
begin
  if Expr then
    Result:= IfTrue
  else
    Result:= IfFalse;
end;

function TfMain.StrToHexArray(const Hex: string): TBytes;
var
  i, Val: Integer;
begin
  SetLength(Result, 0);
  i:= 1;                                             
  while i <= Length(Hex) do
    if TryStrToInt('$'+Copy(Hex, i, 2), Val) then
      begin
        SetLength(Result, Length(Result)+1);
        Result[Length(Result)-1]:= Byte(Val);
        Inc(i, 2);
      end
    else
      i:= Length(Hex)+1;
end;

function TfMain.LoadImage(const FileName: String; const Handle: THandle; const Size: Int64; const IdealBlockSize: Cardinal; const SectorSize: Word; const Compressed: Boolean): TTestResult;
const
  Warning = 'The image size is less than the device or partition capacity! There is not safe to write this image. Do you want to proceed?';
var
  i, Cnt, Res, FileSize, WBytes: Int64;
  Buffer: Pointer;
  tc, BufferSize, WTime: Cardinal;
  InFile: TFileStream;
  Stream: TStream;
  TestEnd: Boolean;
  ZIMHeader: TZIMHeader;
begin
  if Handle <> INVALID_HANDLE_VALUE then
    try
      InFile:= TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
      try
        Result.ResultCode:= rtOk;
        Result.ResultString:= '';
        Result.ErrorsCount:= 0;
        Stop:= False;
        TestEnd:= False;
        WBytes:= 0;
        WTime:= 0;
        if Compressed then
          if (InFile.Read(ZIMHeader, SizeOf(ZIMHeader)) = SizeOf(ZIMHeader)) and
             (ZIMHeader.Signature = ZIMSignature) and
             (ZIMHeader.Vesion and $FF00 <= ZIMVersion and $FF00) and
             (ZIMHeader.Size > 0) then
            begin
              FileSize:= ZIMHeader.Size;
              Stream:= TDecompressionStream.Create(InFile);
            end
          else
            raise EReadError.Create('ZIM header read error')
        else
          begin
            FileSize:= InFile.Size;
            Stream:= InFile;
          end;

        if (FileSize = Size) or
           ((FileSize < Size) and
            (FSupressWarning or (Application.MessageBox(PChar(FMui.Translate('tstImgSizeLess', Warning)), PChar(FMui.Translate('tstWarning', 'Warning')), MB_YESNO+MB_ICONWARNING) = IDYES))) then
          begin
            DriveMap.MinUnitPerBlock:= IdealBlockSize;
            DriveMap.Max:= Size;
            DriveMap.Reset;
            lblBlockWeight.Caption:= SafeFormat(FMui.Translate('tstBlockWeight', '1 block = %d sectors'), [DriveMap.UnitPerBlock div SizeOf(TSector)]);
            lblStage.Caption:= FMui.Translate('tstWriting', 'Writing');
            BufferSize:= Min32(DriveMap.UnitPerBlock, RoundTo(MByte, IdealBlockSize, False));
            GetMem(Buffer, BufferSize);
            FileSeek(Handle, 0, 0);

            pbMain.Max:= FileSize div ProgressStep;
            pbMain.Position:= pbMain.Min;
            i:= 0;
            repeat
              Cnt:= Min64(BufferSize, FileSize-i);
              Res:= Stream.Read(Buffer^, Cnt);
              if Res <> Cnt then
                begin
                  AddDiagMessage(SafeFormat(FMui.Translate('tstImgReadError', 'Error reading image file: %s'), [SysErrorMessage(GetLastError)]), clRed);
                  Result.ResultString:= FMui.Translate('tstFileReadError', 'File read error.');
                  TestEnd:= True;
                end;

              if not TestEnd then
                begin
                  tc:= GetTickCount;
                  Res:= FileWrite(Handle, Buffer^, Cnt);
                  tc:= Max32(GetTickCount-tc, 1);
                  Inc(i, Cnt);
                  if Res = Cnt then
                    begin
                      Inc(WBytes, Res);
                      Inc(WTime, tc);
                      //lblWriteSpeed.Caption:= SafeFormat(FMui.Translate('tstXMBpS', '%n MB/s'), [(WBytes/Mbyte)/(WTime/1000)]);
                      FWriteSpeed:= (WBytes/Mbyte)/(WTime/1000);
                      DriveMap.Blocks[i].Color:= clPurple;
                    end
                  else
                    begin
                      DriveMap.Blocks[i].Color:= clRed;
                      AddDiagMessage(SafeFormat(FMui.Translate('tstWriteErrorAtRange', 'Error at range [%.8xh..%.8xh]: device write error.'), [i-Cnt, i]), clRed);
                      Result.ResultString:= FMui.Translate('tstErrorsFound', 'One or more errors found.');
                      Inc(Result.ErrorsCount);
                      lblErrorsFound.Caption:= inttostr(Result.ErrorsCount);
                      FileSeek(Handle, i, 0);
                    end;
                  pbMain.Position:= i div ProgressStep;
                  Application.ProcessMessages;
                end;
            until (Cnt < BufferSize) or Stop or TestEnd;
            FreeMem(Buffer, BufferSize);

            if Stop then Result.ResultCode:= rtUserInterrupt;
            if TestEnd then Result.ResultCode:= rtWriteFail;

            FlushFileBuffers(Handle);
            Remount(Handle);
          end
        else
          begin
            Result.ResultCode:= rtGenericFail;
            Result.ResultString:= FMui.Translate('tstImgSizeMismatch', 'Image size mismatch.');
            Result.ErrorsCount:= 0;
          end;
        if Compressed then Stream.Free;
      finally
        InFile.Free;
      end;
    except
      Result.ResultCode:= rtReadFail;
      Result.ResultString:= FMui.Translate('tstImgOpenError', 'Error opening image file.');
      Result.ErrorsCount:= 0;
    end
  else
    begin
      Result.ResultCode:= rtGenericFail;
      Result.ResultString:= FMui.Translate('tstInvalidHanle', 'Invalid handle.');
      Result.ErrorsCount:= 0;
    end;
end;

function TfMain.FullErase(const Handle: THandle; const Size: Int64;
  const IdealBlockSize: Cardinal; const TestNumber: Integer; const FillData: TBytes): TTestResult;
var
  i, Cnt, Res, WBytes: Int64;
  Buffer: Pointer;
  tc, BufferSize, WTime, FillLen, j: Cardinal;
begin
  if Handle <> INVALID_HANDLE_VALUE then
    begin
      Result.ResultCode:= rtOk;
      Result.ResultString:= '';
      Result.ErrorsCount:= 0;
      Stop:= False;
      WBytes:= 0;
      WTime:= 0;

      DriveMap.MinUnitPerBlock:= IdealBlockSize;
      DriveMap.Max:= Size;
      DriveMap.Reset;
      lblBlockWeight.Caption:= SafeFormat(FMui.Translate('tstBlockWeight', '1 block = %d sectors'), [DriveMap.UnitPerBlock div SizeOf(TSector)]);
      lblStage.Caption:= FMui.Translate('tstWriting', 'Writing');
      BufferSize:= Min32(DriveMap.UnitPerBlock, RoundTo(MByte, IdealBlockSize, False));
      FillLen:= Length(FillData);
      GetMem(Buffer, BufferSize);
      if FillLen > 0 then
        begin
          j:= 0;
          while j < BufferSize div FillLen do
            begin
              Move(FillData[0], Pointer(Cardinal(Buffer)+j*FillLen)^, FillLen);
              Inc(j);
            end;
          Move(FillData[0], Pointer(Cardinal(Buffer)+j*FillLen)^, BufferSize mod FillLen);
        end
      else
        begin
          Randomize;
          for j:= 0 to BufferSize-1 do
            PByte(Cardinal(Buffer)+j)^:= Byte(Random($100));
        end;
      FileSeek(Handle, 0, 0);

      pbMain.Max:= Size div ProgressStep;
      pbMain.Position:= pbMain.Min;
      i:= 0;
      repeat
        Cnt:= Min64(BufferSize, Size-i);

        tc:= GetTickCount;
        Res:= FileWrite(Handle, Buffer^, Cnt);
        tc:= Max32(GetTickCount-tc, 1);
        Inc(i, Cnt);
        if Res = Cnt then
          begin
            Inc(WBytes, Res);
            Inc(WTime, tc);
            //lblWriteSpeed.Caption:= SafeFormat(FMui.Translate('tstXMBpS', '%n MB/s'), [(WBytes/Mbyte)/(WTime/1000)]);
            FWriteSpeed:= (WBytes/Mbyte)/(WTime/1000);
            DriveMap.Blocks[i].Color:= clPurple;
          end
        else
          begin
            DriveMap.Blocks[i].Color:= clRed;
            AddDiagMessage(SafeFormat(FMui.Translate('tstWriteErrorAtRange', 'Error at range [%.8xh..%.8xh]: device write error.'), [i-Cnt, i]), clRed);
            Result.ResultString:= FMui.Translate('tstErrorsFound', 'One or more errors found.');
            Inc(Result.ErrorsCount);
            lblErrorsFound.Caption:= inttostr(Result.ErrorsCount);
            FileSeek(Handle, i, 0);
          end;
        pbMain.Position:= i div ProgressStep;
        Application.ProcessMessages;
      until (Cnt < BufferSize) or Stop;
      FreeMem(Buffer, BufferSize);

      if Stop then Result.ResultCode:= rtUserInterrupt;

      FlushFileBuffers(Handle);
      Remount(Handle);
    end
  else
    begin
      Result.ResultCode:= rtGenericFail;
      Result.ResultString:= FMui.Translate('tstInvalidHanle', 'Invalid handle.');
      Result.ErrorsCount:= 0;
    end;
end;

function TfMain.Min64(const Arg1, Arg2: Int64): Int64;
begin
  if Arg1 < Arg2 then
    Result:= Arg1
  else
    Result:= Arg2;
end;

{function TForm1.Max64(const Arg1, Arg2: Int64): Int64;
begin
  if Arg1 > Arg2 then
    Result:= Arg1
  else
    Result:= Arg2;
end;}

function TfMain.Min32(const Arg1, Arg2: integer): integer;
begin
  if Arg1 < Arg2 then
    Result:= Arg1
  else
    Result:= Arg2;
end;

function TfMain.Max32(const Arg1, Arg2: integer): integer;
begin
  if Arg1 > Arg2 then
    Result:= Arg1
  else
    Result:= Arg2;
end;

{function TForm1.CompareMem(const p1, p2: pointer; const Size: Cardinal): integer;
var
  i: Cardinal;
begin
  Result:= -1;
  i:= 0;
  while i < Size do
    if pbyte(Cardinal(p1)+i)^ <> pbyte(Cardinal(p2)+i)^ then
      begin
        Result:= i;
        i:= Size;
      end
    else
      inc(i);
end;}

function TfMain.CompareMemWith(const p: pointer; const Size: Integer; const Pattern: byte): integer;
var
  i: Integer;
begin
  Result:= -1;
  i:= 0;
  while i < Size do
    if pbyte(Integer(p)+i)^ <> Pattern then
      begin
        Result:= i;
        i:= Size;
      end
    else
      inc(i);
end;

procedure TfMain.Test;
var
  Handle: THandle;
  Size: Int64;
  Letter: Char;
  Number: Integer;
  WriteType: TWriteType;
  TestCount, i, Errors: Integer;
  TestResult: TTestResult;
  IdealBlockSize, TestData, Mode: Cardinal;
  SectorSize: Word;
begin
  reLog.Lines.Clear;
  Mode:= GENERIC_READ or GENERIC_WRITE;
  Handle:= INVALID_HANDLE_VALUE;
  Size:= -1;
  IdealBlockSize:= SizeOf(TSector);
  FReadSpeed:= 0.0;
  FWriteSpeed:= 0.0;
  i:= 0;
  Errors:= 0;
  TestResult.ResultCode:= rtOk;
  TestResult.ResultString:= '';

  TestCount:= 1;
  if rbContinous.Checked then TestCount:= 0;
  if rbOnePass.Checked then TestCount:= 1;
  if rbManual.Checked then TestCount:= seCycles.Value;
  if rbTillError.Checked then TestCount:= -1;

  WriteType:= wtSmallPattern;
  if rbSmallPattern.Checked then WriteType:= wtSmallPattern;
  if rbFullPattern.Checked then WriteType:= wtFullPattern;
  if rbDelayedWrite.Checked then WriteType:= wtWriteManual;
  if rbDelayedVerify.Checked then WriteType:= wtVerifyManual;

  lblCompletedCycles.Caption:= '0';
  lblErrorsFound.Caption:= '0';
  lblReadSpeed.Caption:= SafeFormat(FMui.Translate('tstXMBpS', '%n MB/s'), [FReadSpeed]);
  lblWriteSpeed.Caption:= SafeFormat(FMui.Translate('tstXMBpS', '%n MB/s'), [FWriteSpeed]);
  lblElapsed.Caption:= FormatTime(0);
  lblRemain.Caption:= FMui.Translate('tstNA', 'n/a');

  if rbReadTest.Checked then Mode:= GENERIC_READ;
  if rbWriteTest.Checked then
    if rbDelayedVerify.Checked then
      Mode:= GENERIC_READ
    else
      Mode:= GENERIC_READ or GENERIC_WRITE;
  if rbPartEdit.Checked then Mode:= GENERIC_READ or GENERIC_WRITE;
  if rbSave.Checked then Mode:= GENERIC_READ;
  if rbLoad.Checked then Mode:= GENERIC_READ or GENERIC_WRITE;
  if rbErase.Checked then Mode:= GENERIC_READ or GENERIC_WRITE;

  if cbDevice.Items.Count > 0 then
    Number:= Integer(cbDevice.Items.Objects[cbDevice.ItemIndex])
  else
    Number:= High(Number);
  if cbDrive.Items.Count > 0 then
    Letter:= Char(cbDrive.Items.Objects[cbDrive.ItemIndex])
  else
    Letter:= High(Letter);
  if rbTempFile.Checked then Handle:= TempOpen(Letter, Mode, rbWriteTest.Checked and rbDelayedWrite.Checked, Size, IdealBlockSize, SectorSize);
  if rbLogical.Checked then Handle:= PartOpen(Letter, Mode, Size, IdealBlockSize, SectorSize);
  if rbPhysical.Checked then Handle:= DriveOpen(Number, Mode, Size, IdealBlockSize, SectorSize);
  if Handle <> INVALID_HANDLE_VALUE then
    begin
      //Application.MessageBox(PChar(IntToStr(IdealBlockSize)), 'IdealBlockSize', MB_OK);
      //size:= 10*MByte;
      FStartTime:= GetTickCount;
      tmrTimer.Enabled:= True;
      pcMain.ActivePageIndex:= 0;
      Panel5.Enabled:= False;
      btnStop.Enabled:= True;
      btnStart.Enabled:= False;
      if rbReadTest.Checked then
        begin
          FIterationStartTime:= FStartTime;
          TestResult:= ReadTest(Handle, Size, IdealBlockSize, True, TestData);
          inc(Errors, TestResult.ErrorsCount);
          inc(i);
          lblCompletedCycles.Caption:= inttostr(i);
          lblErrorsFound.Caption:= inttostr(Errors);
          if TestResult.ResultCode = rtOk then AddDiagMessage(SafeFormat(FMui.Translate('tstPassCompleted', 'Pass #%d completed, %d errors found.'), [i, TestResult.ErrorsCount]), clBlack);
          Application.ProcessMessages;
          while ((i < TestCount) or (TestCount = 0) or ((TestCount = -1) and (TestResult.ErrorsCount = 0))) and (TestResult.ResultCode = rtOk) do
            begin
              FIterationStartTime:= GetTickCount;
              TestResult:= ReadTest(Handle, Size, IdealBlockSize, False, TestData);
              inc(Errors, TestResult.ErrorsCount);
              inc(i);
              lblCompletedCycles.Caption:= inttostr(i);
              lblErrorsFound.Caption:= inttostr(Errors);
              if TestResult.ResultCode = rtOk then AddDiagMessage(SafeFormat(FMui.Translate('tstPassCompleted', 'Pass #%d completed, %d errors found.'), [i, TestResult.ErrorsCount]), clBlack);
              Application.ProcessMessages;
            end;
        end;

      if rbWriteTest.Checked then
        begin
          while ((i < TestCount) or (TestCount = 0) or ((TestCount = -1) and (TestResult.ErrorsCount = 0))) and ((i = 0) or (not rbDelayedWrite.Checked)) and (TestResult.ResultCode = rtOk) do
            begin
              FIterationStartTime:= GetTickCount;
              TestResult:= WriteTest(Handle, Size, IdealBlockSize, WriteType, Byte(StrToIntDef('$'+cbPattern.Text, $55)));
              inc(Errors, TestResult.ErrorsCount);
              inc(i);
              lblCompletedCycles.Caption:= inttostr(i);
              lblErrorsFound.Caption:= inttostr(Errors);
              if TestResult.ResultCode = rtOk then AddDiagMessage(SafeFormat(FMui.Translate('tstPassCompleted', 'Pass #%d completed, %d errors found.'), [i, TestResult.ErrorsCount]), clBlack);
              Application.ProcessMessages;
            end;
          if rbDelayedWrite.Checked and (rbPhysical.Checked or rbLogical.Checked) then Remount(Handle);
        end;

      if rbPartEdit.Checked then
        begin
          FIterationStartTime:= 0;
          TestResult:= InitDisk(Handle, Size, IdealBlockSize);
          inc(Errors, TestResult.ErrorsCount);
          inc(i);
          lblCompletedCycles.Caption:= inttostr(i);
          lblErrorsFound.Caption:= inttostr(Errors);
          if TestResult.ResultCode = rtOk then AddDiagMessage(SafeFormat(FMui.Translate('tstPassCompleted', 'Pass #%d completed, %d errors found.'), [i, TestResult.ErrorsCount]), clBlack);
          Application.ProcessMessages;
        end;

      if rbSave.Checked and ((FDefFileName <> '') or sdImage.Execute) then
        begin
          FIterationStartTime:= GetTickCount;
          TestResult:= SaveImage(SIf(FDefFileName <> '', FDefFileName, sdImage.FileName), Handle, Size, IdealBlockSize, SectorSize, (sdImage.FilterIndex = 2) or SameText(ExtractFileExt(FDefFileName), '.ZIM'));
          inc(Errors, TestResult.ErrorsCount);
          Inc(i);
          lblCompletedCycles.Caption:= inttostr(i);
          lblErrorsFound.Caption:= inttostr(Errors);
          if TestResult.ResultCode = rtOk then AddDiagMessage(SafeFormat(FMui.Translate('tstPassCompleted', 'Pass #%d completed, %d errors found.'), [i, TestResult.ErrorsCount]), clBlack);
          Application.ProcessMessages;
          FDefFileName:= '';
        end;

      if rbLoad.Checked and ((FDefFileName <> '') or odImage.Execute) then
        begin
          FIterationStartTime:= GetTickCount;
          TestResult:= LoadImage(SIf(FDefFileName <> '', FDefFileName, odImage.FileName), Handle, Size, IdealBlockSize, SectorSize, (odImage.FilterIndex = 2) or SameText(ExtractFileExt(FDefFileName), '.ZIM'));
          inc(Errors, TestResult.ErrorsCount);
          Inc(i);
          lblCompletedCycles.Caption:= inttostr(i);
          lblErrorsFound.Caption:= inttostr(Errors);
          if TestResult.ResultCode = rtOk then AddDiagMessage(SafeFormat(FMui.Translate('tstPassCompleted', 'Pass #%d completed, %d errors found.'), [i, TestResult.ErrorsCount]), clBlack);
          Application.ProcessMessages;
          FDefFileName:= '';
        end;

      if rbErase.Checked then
        begin
          while ((i < TestCount) or (TestCount = 0) or ((TestCount = -1) and (TestResult.ErrorsCount = 0))) and (TestResult.ResultCode = rtOk) do
            begin
              FIterationStartTime:= GetTickCount;
              TestResult:= FullErase(Handle, Size, IdealBlockSize, i, StrToHexArray(edPattern.Text));
              inc(Errors, TestResult.ErrorsCount);
              inc(i);
              lblCompletedCycles.Caption:= inttostr(i);
              lblErrorsFound.Caption:= inttostr(Errors);
              if TestResult.ResultCode = rtOk then AddDiagMessage(SafeFormat(FMui.Translate('tstPassCompleted', 'Pass #%d completed, %d errors found.'), [i, TestResult.ErrorsCount]), clBlack);
              Application.ProcessMessages;
            end;
        end;

      AddDiagMessage('', clDefault);
      case TestResult.ResultCode of
        rtOk: AddDiagMessage(SafeFormat(FMui.Translate('tstTestCompleted', 'Test completed, total %d errors found.'), [Errors]), clBlack);
        rtGenericFail,
        rtWriteFail,
        rtReadFail: AddDiagMessage(SafeFormat(FMui.Translate('tstTestFail', 'Test fail: %s'), [TestResult.ResultString]), clRed);
        rtUserInterrupt: AddDiagMessage(SafeFormat(FMui.Translate('tstInterrupted', 'Test interrupted by user, total %d errors found.'), [Errors]), clBlack);
      end;
      lblStage.Caption:= FMui.Translate('tstReady', 'Ready');
      pbMain.Position:= pbMain.Min;
      btnStop.Enabled:= False;
      btnStart.Enabled:= True;
      Panel5.Enabled:= True;
      tmrTimer.Enabled:= False;
      lblReadSpeed.Caption:= SafeFormat(FMui.Translate('tstXMBpS', '%n MB/s'), [FReadSpeed]);
      lblWriteSpeed.Caption:= SafeFormat(FMui.Translate('tstXMBpS', '%n MB/s'), [FWriteSpeed]);

      DiskClose(Handle);
      if FQuitOnDone and ((TestResult.ResultCode = rtOk) or FSilent) then Close;
    end
  else
    AddDiagMessage(SafeFormat(FMui.Translate('tstFileOrDeviceError', 'File or device error: %s'), [SysErrorMessage(GetLastError)]), clRed);

  FQuitOnDone:= False;
  pcMain.ActivePageIndex:= 1;
end;

procedure TfMain.tmrTimerTimer(Sender: TObject);
var
  Tc: Cardinal;
begin
  if FIterationStartTime > 0 then
    begin
      Tc:= GetTickCount;
      lblElapsed.Caption:= FormatTime(Tc-FStartTime);
      if pbMain.Position > pbMain.Min then
        lblRemain.Caption:= FormatTime(Round(((Tc-FIterationStartTime)/(pbMain.Position-pbMain.Min))*(pbMain.Max-pbMain.Position)));
      lblReadSpeed.Caption:= SafeFormat(FMui.Translate('tstXMBpS', '%n MB/s'), [FReadSpeed]);
      lblWriteSpeed.Caption:= SafeFormat(FMui.Translate('tstXMBpS', '%n MB/s'), [FWriteSpeed]);  
    end;
end;

procedure TfMain.AddDiagMessage(const Text: string; const Color: TColor; const WriteLogFileIfOpened: Boolean);
var
  LastPos: Integer;
begin
  LockWindowUpdate(reLog.Handle);
  LastPos:= Length(reLog.Lines.Text);
  while cbScrollLog.Checked and (LastPos >= LogLimit) do
    begin
      reLog.Lines.Delete(0);
      LastPos:= Length(reLog.Lines.Text);
    end;
  reLog.Lines.Add(Text);
  reLog.SelStart:= LastPos;
  reLog.SelLength:= Length(Text);
  reLog.SelAttributes.Color:= Color;
  reLog.SelLength:= 0;
  LockWindowUpdate(0);

  if WriteLogFileIfOpened and Assigned(FLogFile) then
    try
      Writeln(FLogFile^, Text);
      Flush(FLogFile^);
    except
      on E: Exception do
        AddDiagMessage(SafeFormat(FMui.Translate('tstLogFileWriteError', 'Write log file error: %s'), [E.Message]), clRed, False);
    end;
end;

function TfMain.IntToBin(const Data: byte): string;
var
  Buf: byte;
begin
  Buf:= Data;
  Result:= '';
  while Buf > 0 do
    begin
      Result:= inttostr(Buf mod 2)+Result;
      Buf:= Buf div 2;
    end;
  while Length(Result) < 8 do Result:= '0'+Result;
end;

function TfMain.IsSwitch(const Name: string; const Position: Integer): Boolean;
var
  Value: string;
begin
  Result:= GetSwitch(Name, Position, Value);
end;

function TfMain.InitDisk(const Handle: THandle; const Size: Int64; const IdealBlockSize: Cardinal): TTestResult;
begin
  pbMain.Position:= pbMain.Min;
  Application.ProcessMessages;

  Result.ResultCode:= rtOk;
  Result.ErrorsCount:= 0;
  Result.ResultString:= '';
  fPartitions:= TfPartitions.Create(nil);
  if fPartitions.Execute(Handle, Size) then
    begin
      FlushFileBuffers(Handle);
      Remount(Handle);
    end
  else
    Result.ResultCode:= rtUserInterrupt;
  fPartitions.Free;
end;

////////////////////////////////////////////////////////////////////////////////

function TfMain.FormatTime(const Msecs: Cardinal): string;
var
  AllSec: Cardinal;
begin
  AllSec:= Msecs div 1000;
  Result:= Format('%.2d'+TimeSeparator+'%.2d'+TimeSeparator+'%.2d', [AllSec div 3600, (AllSec mod 3600) div 60, (AllSec mod 3600) mod 60]);
end;

procedure TfMain.OnComponentTranslate(Sender: TObject;
  const Component: TComponent; var Process: Boolean);
begin
  Process:= True;
end;

procedure TfMain.OnDictLangSelect(Sender: TObject; var Language: String);
var
  Str: string;
begin
  Str:= GetStrSwitch('/LANG', 1, '');
  if Str <> '' then Language:= Str;
end;

function TfMain.SafeFormat(const Text: string; Args: array of const): string;
begin
  try
    Result:= Format(Text, Args);
  except
    on E: Exception do
      begin
        Application.MessageBox(PChar('Exception while formatting language-specific string for language "'+FMui.Dictionary.LanguageID+'":'#13'==================='#13'"'+Text+'"'#13'==================='#13'Error message: "'+E.Message+'"'), 'Language string error!', MB_OK or MB_ICONHAND);
        Result:= Text;
      end;
  end;
end;

procedure TfMain.FormCreate(Sender: TObject);
begin
  DriveMap:= TDriveMap.Create(nil);
  DriveMap.Align:= alClient;
  DriveMap.MaxHorizontal:= 15;
  DriveMap.MaxVertical:= 14;
  DriveMap.MinUnitPerBlock:= SizeOf(TSector);
  DriveMap.Min:= 0;
  DriveMap.Max:= 512*MByte;
  DriveMap.Parent:= Panel4;

  FMui:= TMUI.Create(nil);
  FMui.OnComponentTranslate:= OnComponentTranslate;
  FMui.Dictionary:= TDict.Create(FMui);
  FMui.Dictionary.OnLangSelect:= OnDictLangSelect;
  FMui.Dictionary.LoadFromFile(ChangeFileExt(Application.ExeName, '.lng'), True);
  FMui.ProcessForm(Self);

  pcDeviceSelect.ActivePage:= tsDrive;
  pcMain.ActivePage:= tsDriveMap;
  sbActionType.VertScrollBar.Position:= 0;
  rbWriteTest.Checked:= True;
  rbTempFile.Checked:= True;
  rbOnePass.Checked:= True;

  lblBlockWeight.Caption:= SafeFormat(FMui.Translate('tstBlockWeight', '1 block = %d sectors'), [0]);
  lblStage.Caption:= FMui.Translate('tstReady', 'Ready');
  lblCompletedCycles.Caption:= '0';
  lblErrorsFound.Caption:= '0';
  lblReadSpeed.Caption:= SafeFormat(FMui.Translate('tstXMBpS', '%n MB/s'), [0.0]);
  lblWriteSpeed.Caption:= SafeFormat(FMui.Translate('tstXMBpS', '%n MB/s'), [0.0]);
  lblElapsed.Caption:= FormatTime(0);
  lblRemain.Caption:= FMui.Translate('tstNA', 'n/a');

  BeginInit;
  ProcessAutomationCmdLine;
end;

procedure TfMain.rbTempFileClick(Sender: TObject);
begin
  if (Sender as TRadioButton).Checked then
    begin
      pcDeviceSelect.ActivePageIndex:= 0;
      rbPartEdit.Enabled:= False;
      rbReadTest.Enabled:= False;
      if not rbWriteTest.Checked then rbWriteTest.Checked:= True;
      rbSave.Enabled:= False;
      rbLoad.Enabled:= False;
      rbErase.Enabled:= False;
    end;
  btnStart.Enabled:= (cbDrive.Items.Count > 0);
end;

procedure TfMain.rbPhysicalClick(Sender: TObject);
begin
  if (Sender as TRadioButton).Checked then
    begin
      pcDeviceSelect.ActivePageIndex:= 1;
      rbPartEdit.Enabled:= True;
      rbReadTest.Enabled:= True;
      if not rbReadTest.Checked then rbReadTest.Checked:= True;
      rbSave.Enabled:= True;
      rbLoad.Enabled:= True;
      rbErase.Enabled:= True;
      rbReadTest.Checked:= True;
    end;
  btnStart.Enabled:= (cbDevice.Items.Count > 0);
end;

procedure TfMain.rbLogicalClick(Sender: TObject);
begin
  if (Sender as TRadioButton).Checked then
    begin
      pcDeviceSelect.ActivePageIndex:= 0;
      rbPartEdit.Enabled:= False;
      rbReadTest.Enabled:= True;
      if not rbReadTest.Checked then rbReadTest.Checked:= True;
      rbSave.Enabled:= True;
      rbLoad.Enabled:= True;
      rbErase.Enabled:= True;
    end;
  btnStart.Enabled:= (cbDrive.Items.Count > 0);
end;

procedure TfMain.rbReadTestClick(Sender: TObject);
begin
  rbSmallPattern.Enabled:= rbWriteTest.Checked;
  rbFullPattern.Enabled:= rbSmallPattern.Enabled;
  rbDelayedWrite.Enabled:= rbSmallPattern.Enabled;
  rbDelayedVerify.Enabled:= rbSmallPattern.Enabled;
  lblCapReadSpeed.Enabled:= rbReadTest.Checked or (rbWriteTest.Checked and not rbDelayedWrite.Checked) or rbSave.Checked;
  lblReadSpeed.Enabled:= lblCapReadSpeed.Enabled;
  lblCapWriteSpeed.Enabled:= (rbWriteTest.Checked and not rbDelayedVerify.Checked) or rbLoad.Checked or rbErase.Checked;
  lblWriteSpeed.Enabled:= lblCapWriteSpeed.Enabled;
  rbContinous.Enabled:= not (rbPartEdit.Checked or rbSave.Checked or rbLoad.Checked or (rbWriteTest.Checked and rbDelayedWrite.Checked));
  rbOnePass.Enabled:= rbContinous.Enabled;
  rbManual.Enabled:= rbContinous.Enabled;
  rbTillError.Enabled:= rbContinous.Enabled;
  lblCapCompletedCycles.Enabled:= rbContinous.Enabled;
  lblCompletedCycles.Enabled:= lblCapCompletedCycles.Enabled;
  lblCapElapsed.Enabled:= not rbPartEdit.Checked;
  lblElapsed.Enabled:= lblCapElapsed.Enabled;
  lblCapRemain.Enabled:= lblCapElapsed.Enabled;
  lblRemain.Enabled:= lblCapElapsed.Enabled;
  cbPattern.Enabled:= rbWriteTest.Checked and (rbDelayedWrite.Checked or rbDelayedVerify.Checked);
  lblCapPattern.Enabled:= cbPattern.Enabled;
  lblCapPattern2.Enabled:= rbErase.Checked;
  edPattern.Enabled:= lblCapPattern2.Enabled;
  rbManualClick(rbManual);
end;

procedure TfMain.rbManualClick(Sender: TObject);
begin
  seCycles.Enabled:= rbManual.Enabled and rbManual.Checked;
  lblCapCycles.Enabled:= seCycles.Enabled;
end;

procedure TfMain.btnStartClick(Sender: TObject);
const
  Warning = 'All data on the target device will be DESTROYED during this test!'#13+
            'After testing, the selected partition or device must be re-formatted by the operating system format procedure.'#13#13+
            'Are you really want to perform this test?';
var
  Ok: Boolean;
begin
  if (rbLogical.Checked or rbPhysical.Checked) and ((rbWriteTest.Checked and not rbDelayedVerify.Checked) or rbErase.Checked) then
    Ok:= FSupressWarning or (Application.MessageBox(PChar(FMui.Translate('tstDataWillDestroyed', Warning)), PChar(FMui.Translate('tstWarning', 'Warning!')), MB_YESNO+MB_ICONWARNING) = IDYES)
  else
    Ok:= True;

  if Ok then Test;
end;

procedure TfMain.btnStopClick(Sender: TObject);
begin
  Stop:= True;
end;

procedure TfMain.FormDestroy(Sender: TObject);
begin
  FMui.Free;
  DriveMap.Free;
  if Assigned(FLogFile) then
    begin
      CloseFile(FLogFile^);
      Dispose(FLogFile);
    end;
end;

function TfMain.GetFSLimit(const FSName: string): Int64;
var
  i: Integer;
begin
  Result:= 0;
  i:= Length(FSLimits)-1;
  while i >= 0 do
    if Pos(FSLimits[i].Name, UpperCase(FSName)) = 1 then
      begin
        Result:= FSLimits[i].Limit;
        i:= -1;
      end
    else
      Dec(i);
end;

function TfMain.GetIntSwitch(const Name: string; const Position,
  Default: Integer): Integer;
var
  Value: string;
begin
  if GetSwitch(Name, Position, Value) then
    Result:= StrToIntDef(Value, Default)
  else
    Result:= Default;
end;

function TfMain.GetStrSwitch(const Name: string; const Position: Integer;
  const Default: string): string;
begin
  if not GetSwitch(Name, Position, Result) then Result:= Default;
end;

function TfMain.GetSwitch(const Name: string; const Position: Integer;
  out Value: string): Boolean;
var
  i, p, Index: Integer;
  s, n: string;
begin
  Result:= False;
  if Position > 0 then
    begin
      Index:= 0;
      n:= Trim(Name);
      if n <> '' then
        begin
          i:= 1;
          while (not Result) and (i <= ParamCount) do
            begin
              s:= Trim(ParamStr(i));
              p:= Pos(UpperCase(n), UpperCase(s));
              if p = 1 then
                if Length(s) = Length(n) then
                  begin
                    Inc(Index);
                    if Index = Position then
                      begin
                        Value:= '';
                        Result:= True;
                      end
                    else
                      Inc(i);
                  end
                else
                  if s[Length(n)+1] in [':','='] then
                    begin
                      Inc(Index);
                      if Index = Position then
                        begin
                          Value:= Copy(s, Length(n)+2, High(Integer));
                          Result:= True;
                        end
                      else
                        Inc(i);
                    end
                  else
                    Inc(i)
              else
                Inc(i);
            end;
        end;
    end;
end;

procedure TfMain.FixComboBox(const Combobox: TComboBox);
var
  i, Width: Integer;
begin
  Combobox.Canvas.Font.Assign(Combobox.Font);
  Width:= 0;
  for i:= 0 to Combobox.Items.Count-1 do
    if Combobox.Canvas.TextWidth(Combobox.Items[i]) > Width then
      Width:= Combobox.Canvas.TextWidth(Combobox.Items[i]);
  SendMessage(Combobox.Handle, CB_SETDROPPEDWIDTH, Max32(Combobox.Width, Width+5), 0);
end;


end.

