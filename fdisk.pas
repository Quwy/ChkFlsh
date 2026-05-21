unit fdisk;

interface

uses
  Types;

type
  TSector = array [0..511] of Byte;
  PSector = ^TSector;  

const
  BootSignature = $AA55;

type
  TActivityFlag = (afNone = $00, afActive = $80);
  TSystemID = (siEmpty=$00, siFAT12=$01, siFAT16_32MB=$04, siExtended=$05, siFAT16=$06, siNTFS=$07, siFAT32=$0B, siFAT32_LBA=$0C, siFAT16_LBA=$0E, siExtended_LBA=$0F, siLinuxSwap=$82, siLinux=$83, siLinuxExt=$85);

type
  TPartTableEntry = packed record
    Active: TActivityFlag;
    StartHead: byte;
    StartCylinder: word;
    SystemID: TSystemID;
    EndHead: byte;
    EndCylinder: word;
    StartSector: Cardinal;
    SectorCount: Cardinal;
  end;
  
  TPartTable = array [0..3] of TPartTableEntry;

  TMBR = packed record
    Loader: array [0..445] of byte;
    PartTable: TPartTable;
    Signature: word; // $AA55
  end;

type
  TMediaType = (mt2x18=$F0, mtFixed=$F8, mt2x15=$F9, mt1x9=$FC, mt2x9=$FD, mt1x8=$FE, mt2x8=$FF);
  TPhysicalType = byte;

const
  ptBaseFloppy = $00;
  ptBaseFixed = $80;

type
  TBPB_FAT = packed record
    BytesPerSector: word;   // 512
    SectorsPerCluster: byte;
    TotalBootSectors: word; // SectorsPerTrack
    FatCount: byte;         // 2
    MaxRootDescriptors: word;
    TotalSectors: word;
    MediaType: TMediaType;
    TotalFatSectors: word;
    SectorsPerTrack: word;
    HeadsCount: word;
    HiddenSectors: Cardinal;   // 0
    TotalSectorsEx: Cardinal; // TotalSectors > $FFFF
  end;

  TBR_FAT = packed record
    Jump: array [0..2] of byte;
    OsDescription: array [0..7] of char; // 'MSWIN4.1'
    BPB: TBPB_FAT;
    PhysicalType: TPhysicalType;
    Reserved: byte; // $00
    ExtSign: byte; // $29
    SerialNumber: Cardinal;
    VolumeLabel: array [0..10] of char;
    FatDescription: array [0..7] of char; // 'FAT16   '
    Loader: array [0..447] of byte;
    Signature: word; // $AA55
  end;

type
  TBPB_FAT32 = packed record
    StdBPB: TBPB_FAT;
    TotalFatSectorsEx: Cardinal;
    Flags: word; // $0000
    FatVersion: word; // $0000
    FirstRootCluster: Cardinal; // 2
    FSInfoSector: word; // 1
    FirstBackupSector: word; // 6
    Reserved: array [0..11] of byte; // $00
  end;

  TFSInfo = packed record
    Signature1: Cardinal; // $41615252
    Reserved1: array [0..479] of byte; // $00
    Signature2: Cardinal; // $61417272
    TotalFreeClusters: Cardinal; // $FFFFFFFF
    FirstFreeCluster: Cardinal; // $FFFFFFFF
    Reserved2: array [0..11] of byte; // $00
    Reserved3: word; // $0000
    Signature: word; // $AA55
  end;

  TExtSector = packed record
    LoaderEx: array [0..509] of byte;
    Signature: word; // $AA55
  end;

  TBR_FAT32 = packed record
    Jump: array [0..2] of byte;
    OsDescription: array [0..7] of char; // 'MSWIN4.1'
    BPB: TBPB_FAT32;
    PhysicalNumber: TPhysicalType;
    Reserved: byte; // $00
    ExtSign: byte; // $29
    SerialNumber: Cardinal;
    VolumeLabel: array [0..10] of char;
    FatDescription: array [0..7] of char; // 'FAT32   '
    Loader: array [0..419] of byte;
    Signature: word; // $AA55
    FSInfo: TFSInfo;
    ExtSector: TExtSector;
  end;

type
  TCHS = record
    Cylinder: Word;
    Sector: Cardinal;
    Head: Byte;
  end;


function GetBlankMBR: TMBR;
function GetBlankBR_FAT(const SectorsPerTrack, HeadsCount: word; const TotalSectors, SerialNumber: Cardinal): TBR_FAT;
function GetBlankBR_FAT32(const SectorsPerTrack, HeadsCount: word; const TotalSectors, SerialNumber: Cardinal): TBR_FAT32;
function GenerateSerialNumber: Cardinal;

function GetSystemIDStr(const SystemID: TSystemID): string;

function RoundTo64(const Value: Int64; const Base: Cardinal; const Up: boolean): Int64;
function RoundTo32(const Value: integer; const Base: word; const Up: boolean): integer;
function RoundTo(const Value: Cardinal; const Base: word; const Up: boolean): Cardinal;

implementation

uses
  Windows;

const
  BlankMBR: TMBR = (Loader:($33,$C0,$8E,$D0,$BC,$00,$7C,$FB,$50,$07,$50,$1F,$FC,$BE,$1B,$7C,
                            $BF,$1B,$06,$50,$57,$B9,$E5,$01,$F3,$A4,$CB,$BD,$BE,$07,$B1,$04,
                            $38,$6E,$00,$7C,$09,$75,$13,$83,$C5,$10,$E2,$F4,$CD,$18,$8B,$F5,
                            $83,$C6,$10,$49,$74,$19,$38,$2C,$74,$F6,$A0,$B5,$07,$B4,$07,$8B,
                            $F0,$AC,$3C,$00,$74,$FC,$BB,$07,$00,$B4,$0E,$CD,$10,$EB,$F2,$88,
                            $4E,$10,$E8,$46,$00,$73,$2A,$FE,$46,$10,$80,$7E,$04,$0B,$74,$0B,
                            $80,$7E,$04,$0C,$74,$05,$A0,$B6,$07,$75,$D2,$80,$46,$02,$06,$83,
                            $46,$08,$06,$83,$56,$0A,$00,$E8,$21,$00,$73,$05,$A0,$B6,$07,$EB,
                            $BC,$81,$3E,$FE,$7D,$55,$AA,$74,$0B,$80,$7E,$10,$00,$74,$C8,$A0,
                            $B7,$07,$EB,$A9,$8B,$FC,$1E,$57,$8B,$F5,$CB,$BF,$05,$00,$8A,$56,
                            $00,$B4,$08,$CD,$13,$72,$23,$8A,$C1,$24,$3F,$98,$8A,$DE,$8A,$FC,
                            $43,$F7,$E3,$8B,$D1,$86,$D6,$B1,$06,$D2,$EE,$42,$F7,$E2,$39,$56,
                            $0A,$77,$23,$72,$05,$39,$46,$08,$73,$1C,$B8,$01,$02,$BB,$00,$7C,
                            $8B,$4E,$02,$8B,$56,$00,$CD,$13,$73,$51,$4F,$74,$4E,$32,$E4,$8A,
                            $56,$00,$CD,$13,$EB,$E4,$8A,$56,$00,$60,$BB,$AA,$55,$B4,$41,$CD,
                            $13,$72,$36,$81,$FB,$55,$AA,$75,$30,$F6,$C1,$01,$74,$2B,$61,$60,
                            $6A,$00,$6A,$00,$FF,$76,$0A,$FF,$76,$08,$6A,$00,$68,$00,$7C,$6A,
                            $01,$6A,$10,$B4,$42,$8B,$F4,$CD,$13,$61,$61,$73,$0E,$4F,$74,$0B,
                            $32,$E4,$8A,$56,$00,$CD,$13,$EB,$D6,$61,$F9,$C3,$49,$6E,$76,$61,
                            $6C,$69,$64,$20,$70,$61,$72,$74,$69,$74,$69,$6F,$6E,$20,$74,$61,
                            $62,$6C,$65,$00,$45,$72,$72,$6F,$72,$20,$6C,$6F,$61,$64,$69,$6E,
                            $67,$20,$6F,$70,$65,$72,$61,$74,$69,$6E,$67,$20,$73,$79,$73,$74,
                            $65,$6D,$00,$4D,$69,$73,$73,$69,$6E,$67,$20,$6F,$70,$65,$72,$61,
                            $74,$69,$6E,$67,$20,$73,$79,$73,$74,$65,$6D,$00,$00,$00,$00,$00,
                            $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                            $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                            $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                            $00,$00,$00,$00,$00,$2C,$44,$63,$CC,$11,$58,$DC,$00,$00);
                    PartTable:((Active:afNone; StartHead:0; StartCylinder:0; SystemID:siEmpty; EndHead:0; EndCylinder:0; StartSector:0; SectorCount:0),
                               (Active:afNone; StartHead:0; StartCylinder:0; SystemID:siEmpty; EndHead:0; EndCylinder:0; StartSector:0; SectorCount:0),
                               (Active:afNone; StartHead:0; StartCylinder:0; SystemID:siEmpty; EndHead:0; EndCylinder:0; StartSector:0; SectorCount:0),
                               (Active:afNone; StartHead:0; StartCylinder:0; SystemID:siEmpty; EndHead:0; EndCylinder:0; StartSector:0; SectorCount:0));
                    Signature:BootSignature);

  BlankBR_FAT: TBR_FAT = (Jump:($EB,$3C,$90);
                          OsDescription:('M','S','D','O','S','5','.','0');
                          BPB:(BytesPerSector:512;
                               SectorsPerCluster:16;
                               TotalBootSectors:1;
                               FatCount:2;
                               MaxRootDescriptors:512;
                               TotalSectors:0;
                               MediaType:mtFixed;
                               TotalFatSectors:255;
                               SectorsPerTrack:63; // !!!
                               HeadsCount:255;     // !!!
                               HiddenSectors:0;
                               TotalSectorsEx:0);  // !!!
                           PhysicalType:$80;
                           Reserved:0;
                           ExtSign:$29;
                           SerialNumber:$00000000; // !!!
                           VolumeLabel:('N','O',' ','N','A','M','E',' ',' ',' ',' ');
                           FatDescription:('F','A','T','1','6',' ',' ',' ');
                           Loader:($33,$C9,$8E,$D1,$BC,$F0,$7B,$8E,$D9,$B8,$00,$20,$8E,$C0,$FC,$BD,
                                   $00,$7C,$38,$4E,$24,$7D,$24,$8B,$C1,$99,$E8,$3C,$01,$72,$1C,$83,
                                   $EB,$3A,$66,$A1,$1C,$7C,$26,$66,$3B,$07,$26,$8A,$57,$FC,$75,$06,
                                   $80,$CA,$02,$88,$56,$02,$80,$C3,$10,$73,$EB,$33,$C9,$8A,$46,$10,
                                   $98,$F7,$66,$16,$03,$46,$1C,$13,$56,$1E,$03,$46,$0E,$13,$D1,$8B,
                                   $76,$11,$60,$89,$46,$FC,$89,$56,$FE,$B8,$20,$00,$F7,$E6,$8B,$5E,
                                   $0B,$03,$C3,$48,$F7,$F3,$01,$46,$FC,$11,$4E,$FE,$61,$BF,$00,$00,
                                   $E8,$E6,$00,$72,$39,$26,$38,$2D,$74,$17,$60,$B1,$0B,$BE,$A1,$7D,
                                   $F3,$A6,$61,$74,$32,$4E,$74,$09,$83,$C7,$20,$3B,$FB,$72,$E6,$EB,
                                   $DC,$A0,$FB,$7D,$B4,$7D,$8B,$F0,$AC,$98,$40,$74,$0C,$48,$74,$13,
                                   $B4,$0E,$BB,$07,$00,$CD,$10,$EB,$EF,$A0,$FD,$7D,$EB,$E6,$A0,$FC,
                                   $7D,$EB,$E1,$CD,$16,$CD,$19,$26,$8B,$55,$1A,$52,$B0,$01,$BB,$00,
                                   $00,$E8,$3B,$00,$72,$E8,$5B,$8A,$56,$24,$BE,$0B,$7C,$8B,$FC,$C7,
                                   $46,$F0,$3D,$7D,$C7,$46,$F4,$29,$7D,$8C,$D9,$89,$4E,$F2,$89,$4E,
                                   $F6,$C6,$06,$96,$7D,$CB,$EA,$03,$00,$00,$20,$0F,$B6,$C8,$66,$8B,
                                   $46,$F8,$66,$03,$46,$1C,$66,$8B,$D0,$66,$C1,$EA,$10,$EB,$5E,$0F,
                                   $B6,$C8,$4A,$4A,$8A,$46,$0D,$32,$E4,$F7,$E2,$03,$46,$FC,$13,$56,
                                   $FE,$EB,$4A,$52,$50,$06,$53,$6A,$01,$6A,$10,$91,$8B,$46,$18,$96,
                                   $92,$33,$D2,$F7,$F6,$91,$F7,$F6,$42,$87,$CA,$F7,$76,$1A,$8A,$F2,
                                   $8A,$E8,$C0,$CC,$02,$0A,$CC,$B8,$01,$02,$80,$7E,$02,$0E,$75,$04,
                                   $B4,$42,$8B,$F4,$8A,$56,$24,$CD,$13,$61,$61,$72,$0B,$40,$75,$01,
                                   $42,$03,$5E,$0B,$49,$75,$06,$F8,$C3,$41,$BB,$00,$00,$60,$66,$6A,
                                   $00,$EB,$B0,$4E,$54,$4C,$44,$52,$20,$20,$20,$20,$20,$20,$0D,$0A,
                                   $52,$65,$6D,$6F,$76,$65,$20,$64,$69,$73,$6B,$73,$20,$6F,$72,$20,
                                   $6F,$74,$68,$65,$72,$20,$6D,$65,$64,$69,$61,$2E,$FF,$0D,$0A,$44,
                                   $69,$73,$6B,$20,$65,$72,$72,$6F,$72,$FF,$0D,$0A,$50,$72,$65,$73,
                                   $73,$20,$61,$6E,$79,$20,$6B,$65,$79,$20,$74,$6F,$20,$72,$65,$73,
                                   $74,$61,$72,$74,$0D,$0A,$00,$00,$00,$00,$00,$00,$00,$AC,$CB,$D8);
                           Signature:BootSignature);

  BlankBR_FAT32: TBR_FAT32 = (Jump:($EB,$58,$90);
                              OsDescription:('M','S','D','O','S','5','.','0');
                              BPB:(StdBPB:(BytesPerSector:512;
                                           SectorsPerCluster:8;
                                           TotalBootSectors:36;
                                           FatCount:2;
                                           MaxRootDescriptors:0;
                                           TotalSectors:0;
                                           MediaType:mtFixed;
                                           TotalFatSectors:0;
                                           SectorsPerTrack:63;  // !!!
                                           HeadsCount:255;      // !!!
                                           HiddenSectors:0;
                                           TotalSectorsEx:0);   // !!!
                                   TotalFatSectorsEx:0;
                                   Flags:0;
                                   FatVersion:0;
                                   FirstRootCluster:2;
                                   FSInfoSector:1;
                                   FirstBackupSector:6;
                                   Reserved:($00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00));
                              PhysicalNumber:$80;
                              Reserved:0;
                              ExtSign:$29;
                              SerialNumber:$00000000;           // !!!
                              VolumeLabel:('N','O',' ','N','A','M','E',' ',' ',' ',' ');
                              FatDescription:('F','A','T','3','2',' ',' ',' ');
                              Loader:($33,$C9,$8E,$D1,$BC,$F4,$7B,$8E,$C1,$8E,$D9,$BD,$00,$7C,$88,$4E,
                                      $02,$8A,$56,$40,$B4,$08,$CD,$13,$73,$05,$B9,$FF,$FF,$8A,$F1,$66,
                                      $0F,$B6,$C6,$40,$66,$0F,$B6,$D1,$80,$E2,$3F,$F7,$E2,$86,$CD,$C0,
                                      $ED,$06,$41,$66,$0F,$B7,$C9,$66,$F7,$E1,$66,$89,$46,$F8,$83,$7E,
                                      $16,$00,$75,$38,$83,$7E,$2A,$00,$77,$32,$66,$8B,$46,$1C,$66,$83,
                                      $C0,$0C,$BB,$00,$80,$B9,$01,$00,$E8,$2B,$00,$E9,$48,$03,$A0,$FA,
                                      $7D,$B4,$7D,$8B,$F0,$AC,$84,$C0,$74,$17,$3C,$FF,$74,$09,$B4,$0E,
                                      $BB,$07,$00,$CD,$10,$EB,$EE,$A0,$FB,$7D,$EB,$E5,$A0,$F9,$7D,$EB,
                                      $E0,$98,$CD,$16,$CD,$19,$66,$60,$66,$3B,$46,$F8,$0F,$82,$4A,$00,
                                      $66,$6A,$00,$66,$50,$06,$53,$66,$68,$10,$00,$01,$00,$80,$7E,$02,
                                      $00,$0F,$85,$20,$00,$B4,$41,$BB,$AA,$55,$8A,$56,$40,$CD,$13,$0F,
                                      $82,$1C,$00,$81,$FB,$55,$AA,$0F,$85,$14,$00,$F6,$C1,$01,$0F,$84,
                                      $0D,$00,$FE,$46,$02,$B4,$42,$8A,$56,$40,$8B,$F4,$CD,$13,$B0,$F9,
                                      $66,$58,$66,$58,$66,$58,$66,$58,$EB,$2A,$66,$33,$D2,$66,$0F,$B7,
                                      $4E,$18,$66,$F7,$F1,$FE,$C2,$8A,$CA,$66,$8B,$D0,$66,$C1,$EA,$10,
                                      $F7,$76,$1A,$86,$D6,$8A,$56,$40,$8A,$E8,$C0,$E4,$06,$0A,$CC,$B8,
                                      $01,$02,$CD,$13,$66,$61,$0F,$82,$54,$FF,$81,$C3,$00,$02,$66,$40,
                                      $49,$0F,$85,$71,$FF,$C3,$4E,$54,$4C,$44,$52,$20,$20,$20,$20,$20,
                                      $20,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                      $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                      $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                      $00,$00,$0D,$0A,$52,$65,$6D,$6F,$76,$65,$20,$64,$69,$73,$6B,$73,
                                      $20,$6F,$72,$20,$6F,$74,$68,$65,$72,$20,$6D,$65,$64,$69,$61,$2E,
                                      $FF,$0D,$0A,$44,$69,$73,$6B,$20,$65,$72,$72,$6F,$72,$FF,$0D,$0A,
                                      $50,$72,$65,$73,$73,$20,$61,$6E,$79,$20,$6B,$65,$79,$20,$74,$6F,
                                      $20,$72,$65,$73,$74,$61,$72,$74,$0D,$0A,$00,$00,$00,$00,$00,$AC,
                                      $CB,$D8,$00,$00);
                              Signature:BootSignature;
                              FSInfo:(Signature1:$41615252;
                                      Reserved1:($00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                 $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00);
                                      Signature2:$61417272;
                                      TotalFreeClusters:$FFFFFFFF;
                                      FirstFreeCluster:$FFFFFFFF;
                                      Reserved2:($00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00);
                                      Reserved3:0;
                                      Signature:BootSignature);
                              ExtSector:(LoaderEx:($00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,
                                                   $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00);
                                         Signature:BootSignature));

function GetBlankMBR: TMBR;
begin
  Result:= BlankMBR;
end;

function GetBlankBR_FAT(const SectorsPerTrack, HeadsCount: word; const TotalSectors, SerialNumber: Cardinal): TBR_FAT;
begin
  Result:= BlankBR_FAT;
  Result.BPB.SectorsPerTrack:= SectorsPerTrack;
  Result.BPB.HeadsCount:= HeadsCount;
  if TotalSectors <= $FFFF then
    begin
      Result.BPB.TotalSectors:= TotalSectors;
      Result.BPB.TotalSectorsEx:= 0;
    end
  else
    begin
      Result.BPB.TotalSectors:= 0;
      Result.BPB.TotalSectorsEx:= TotalSectors;
    end;
  Result.SerialNumber:= SerialNumber;
end;

function GetBlankBR_FAT32(const SectorsPerTrack, HeadsCount: word; const TotalSectors, SerialNumber: Cardinal): TBR_FAT32;
begin
  Result:= BlankBR_FAT32;
  Result.BPB.StdBPB.SectorsPerTrack:= SectorsPerTrack;
  Result.BPB.StdBPB.HeadsCount:= HeadsCount;
  Result.BPB.StdBPB.TotalSectors:= 0;
  Result.BPB.StdBPB.TotalSectorsEx:= TotalSectors;
  Result.SerialNumber:= SerialNumber;
end;

function GenerateSerialNumber: Cardinal;
begin
  Result:= GetTickCount xor $AA55AA55;
end;

function GetSystemIDStr(const SystemID: TSystemID): string;
begin
  case SystemID of
    siEmpty: Result:= 'Empty';
    siFAT12: Result:= 'FAT12';
    siFAT16_32MB: Result:= 'FAT16 < 32 MB';
    siExtended: Result:= 'Extended';
    siFAT16: Result:= 'FAT16';
    siNTFS: Result:= 'NTFS';
    siFAT32: Result:= 'FAT32';
    siFAT32_LBA: Result:= 'FAT32 (LBA)';
    siFAT16_LBA: Result:= 'FAT16 (LBA)';
    siExtended_LBA: Result:= 'Extended (LBA)';
    siLinuxSwap: Result:= 'Linux Swap';
    siLinux: Result:= 'Linux';
    siLinuxExt: Result:= 'Linux Ext';
  else Result:= 'Unknown';
  end;
end;

function RoundTo64(const Value: Int64; const Base: Cardinal; const Up: boolean): Int64;
begin
  Result:= (Value div Int64(Base))*Base;
  if (Up) and (Value mod Int64(Base) > 0) then Inc(Result, Base);
end;

function RoundTo32(const Value: integer; const Base: word; const Up: boolean): integer;
begin
  Result:= (Value div Base)*Base;
  if (Up) and (Value mod Base > 0) then Inc(Result, Base);
end;

function RoundTo(const Value: Cardinal; const Base: word; const Up: boolean): Cardinal;
begin
  Result:= (Value div Base)*Base;
  if (Up) and (Value mod Base > 0) then Inc(Result, Base);
end;

end.

