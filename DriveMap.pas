// MIKE (C) http://mikelab.kiev.ua/

unit DriveMap;

interface

uses
  Classes, Controls, Graphics, Types;

type
  TRange = record
    BlockFrom, BlockTo: int64;
  end;
  TLastBlockSize = (bsFull, bsHalf, bsProportional);
  TPaintBlock = procedure(Sender: TObject; const Canvas: TCanvas; const Rect: TRect; const Range: TRange) of object;

type
  TDriveProgressBar = class(TGraphicControl)
  private
    FHorCount, FVertCount, FBlockSpace, FBlockBoderWidth: word;
    FColor, FBlankBlockColor, FPassedBlockColor, FCurrentBlockColor, FBlankBorderColor, FPassedBorderColor, FCurrentBorderColor: TColor;
    FMinUnitPerBlock, FUnitPerBlock: int64;
    FMin, FMax, FPos: int64;
    FAfterBlockPaint: TPaintBlock;
    FBitMap: TBitMap;
    FLastBlockSize: TLastBlockSize;
    procedure   SetHorCount(const Value: word);
    procedure   SetVertCount(const Value: word);
    procedure   SetMin(const Value: int64);
    procedure   SetMax(const Value: int64);
    procedure   SetPos(const Value: int64);
    procedure   SetMinUnitPerBlock(const Value: int64);
    procedure   SetLastBlockSize(const Value: TLastBlockSize);

    procedure   SetColor(const Value: TColor);
    procedure   SetBlankBlockColor(const Value: TColor);
    procedure   SetPassedBlockColor(const Value: TColor);
    procedure   SetCurrentBlockColor(const Value: TColor);
    procedure   SetBlankBorderColor(const Value: TColor);
    procedure   SetPassedBorderColor(const Value: TColor);
    procedure   SetCurrentBorderColor(const Value: TColor);
  protected
    function    Min64(const Arg1, Arg2: int64): int64;
    function    Max32(const Arg1, Arg2: integer): integer;
    procedure   Recalculate;
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure   Paint; override;

    procedure   Reset;

    property    UnitPerBlock: int64 read FUnitPerBlock;
  published
    property    MaxHorizontal: word read FHorCount write SetHorCount default 10;
    property    MaxVertical: word read FVertCount write SetVertCount default 10;
    property    Min: int64 read FMin write SetMin default 0;
    property    Max: int64 read FMax write SetMax default 1000;
    property    Position: int64 read FPos write SetPos default 0;
    property    MinUnitPerBlock: int64 read FMinUnitPerBlock write SetMinUnitPerBlock default 1;
    property    LastBlockSize: TLastBlockSize read FLastBlockSize write SetLastBlockSize default bsFull;

    property    Color: TColor read FColor write SetColor default clBtnFace;
    property    BlankBlockColor: TColor read FBlankBlockColor write SetBlankBlockColor default clGray;
    property    PassedBlockColor: TColor read FPassedBlockColor write SetPassedBlockColor default clGreen;
    property    CurrentBlockColor: TColor read FCurrentBlockColor write SetCurrentBlockColor default clYellow;
    property    BlankBorderColor: TColor read FBlankBorderColor write SetBlankBorderColor default clBlack;
    property    PassedBorderColor: TColor read FPassedBorderColor write SetPassedBorderColor default clBlack;
    property    CurrentBorderColor: TColor read FCurrentBorderColor write SetCurrentBorderColor default clBlack;

    property    AfterBlockPaint: TPaintBlock read FAfterBlockPaint write FAfterBlockPaint default nil;

    property    Align;
  end;


type
  TBlocks = class;

  TBlock = class(TObject)
  private
    FDefault: boolean;
    FColor, FBorderColor: TColor;
    FChanged: TNotifyEvent;
    procedure   SetColor(const Value: TColor);
    procedure   SetBorderColor(const Value: TColor);
  public
    constructor Create;
    destructor  Destroy; override;

    property    Default: boolean read FDefault write FDefault default true;
    property    Color: TColor read FColor write SetColor default clGray;
    property    BorderColor: TColor read FBorderColor write SetBorderColor default clBlack;

    property    OnChanged: TNotifyEvent read FChanged write FChanged default nil;
  end;

  TBlocks = class(TObject)
  private
    FLockUpdate: boolean;
    FList: TList;
    FChanged: TNotifyEvent;
    function    GetCount: integer;
    function    GetItem(const Index: integer): TBlock;
  protected
    procedure   OnBlocksChanged(Sender: TObject);

    property    LockUpdate: boolean read FLockUpdate write FLockUpdate default false;
  public
    constructor Create;
    destructor  Destroy; override;

    function    Add(const Color, BorderColor: TColor): integer;
    procedure   Truncate(const NewCount: integer);
    procedure   Clear;
    procedure   ReInit(const Color, BorderColor: TColor);

    property    Count: integer read GetCount;
    property    Items[const Index: integer]: TBlock read GetItem; default;

    property    OnChanged: TNotifyEvent read FChanged write FChanged default nil;
  end;

type
  TDriveMap = class(TGraphicControl)
  private
    FBlocks: TBlocks;
    FHorCount, FVertCount, FBlockSpace, FBlockBoderWidth: word;
    FColor, FDefaultBlockColor, FDefaultBorderColor: TColor;
    FMinUnitPerBlock, FUnitPerBlock: int64;
    FMin, FMax: int64;
    FAfterBlockPaint: TPaintBlock;
    FBitMap: TBitMap;
    FLastBlockSize: TLastBlockSize;
    FNilBlock: TBlock;
    procedure   OnNilBlockChanged(Sender: TObject);

    procedure   SetHorCount(const Value: word);
    procedure   SetVertCount(const Value: word);
    procedure   SetMin(const Value: int64);
    procedure   SetMax(const Value: int64);
    procedure   SetMinUnitPerBlock(const Value: int64);
    procedure   SetLastBlockSize(const Value: TLastBlockSize);

    procedure   SetColor(const Value: TColor);
    procedure   SetDefaultBlockColor(const Value: TColor);
    procedure   SetDefaultBorderColor(const Value: TColor);
    function    GetBlock(const Position: int64): TBlock;
  protected
    function    Min64(const Arg1, Arg2: int64): int64;
    function    Max32(const Arg1, Arg2: integer): integer;
    procedure   Recalculate;
    function    GetBlockIndex(const Position: int64): integer;
    procedure   OnBlocksChanged(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure   Paint; override;

    procedure   Reset;

    property    Blocks[const Position: int64]: TBlock read GetBlock;
    property    UnitPerBlock: int64 read FUnitPerBlock;
  published
    property    MaxHorizontal: word read FHorCount write SetHorCount default 10;
    property    MaxVertical: word read FVertCount write SetVertCount default 10;
    property    Min: int64 read FMin write SetMin default 0;
    property    Max: int64 read FMax write SetMax default 1000;
    property    MinUnitPerBlock: int64 read FMinUnitPerBlock write SetMinUnitPerBlock default 1;
    property    LastBlockSize: TLastBlockSize read FLastBlockSize write SetLastBlockSize default bsFull;

    property    Color: TColor read FColor write SetColor default clBtnFace;
    property    DefaultBlockColor: TColor read FDefaultBlockColor write SetDefaultBlockColor default clGray;
    property    DefaultBorderColor: TColor read FDefaultBorderColor write SetDefaultBorderColor default clBlack;

    property    AfterBlockPaint: TPaintBlock read FAfterBlockPaint write FAfterBlockPaint default nil;

    property    Align;
  end;

procedure Register;

implementation

{$R DriveMap.dcr}

uses
  SysUtils;

procedure Register;
begin
  RegisterComponents('Misha', [TDriveProgressBar, TDriveMap]);
end;

constructor TDriveProgressBar.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBitMap:= TBitMap.Create;

  FHorCount:= 10;
  FVertCount:= 10;
  FBlockSpace:= 1;
  FBlockBoderWidth:= 1;
  FMin:= 0;
  FMax:= 1000;
  FPos:= FMin;
  FMinUnitPerBlock:= 1;
  FUnitPerBlock:= FMinUnitPerBlock;

  FColor:= clbtnFace;
  FBlankBlockColor:= clGray;
  FPassedBlockColor:= clGreen;
  FCurrentBlockColor:= clYellow;
  FBlankBorderColor:= clBlack;
  FPassedBorderColor:= clBlack;
  FCurrentBorderColor:= clBlack;
  FLastBlockSize:= bsFull;

  FAfterBlockPaint:= nil;

  Width:= 200;
  Height:= 200;

  Recalculate;
end;

destructor TDriveProgressBar.Destroy;
begin
  FBitMap.Free;
  inherited Destroy;
end;

procedure TDriveProgressBar.Paint;
var
  X, Y, i, j, BlockWidth, BlockHeight: word;
  CurBlock: cardinal;
  Complete: boolean;
  BlockRect: TRect;
  Range: TRange;
begin
  inherited Paint;

  if Parent <> nil then
    begin
      if FBitMap.Width <> Width then FBitMap.Width:= Width;
      if FBitMap.Height <> Height then FBitMap.Height:= Height;

      FBitMap.Canvas.Pen.Color:= FColor;
      FBitMap.Canvas.Pen.Width:= FBlockBoderWidth;
      FBitMap.Canvas.Pen.Style:= psSolid;
      FBitMap.Canvas.Brush.Color:= FColor;
      FBitMap.Canvas.Brush.Style:= bsSolid;
      FBitMap.Canvas.FillRect(FBitMap.Canvas.ClipRect);

      BlockWidth:= trunc((Width-(FHorCount+1)*FBlockSpace)/FHorCount);
      BlockHeight:= trunc((Height-(FVertCount+1)*FBlockSpace)/FVertCount);
      CurBlock:= 0;
      Complete:= false;
      j:= trunc((Height-(BlockHeight+FBlockSpace)*FVertCount)/2);
      Y:= 1;
      while (Y <= FVertCount) and (not Complete) do
        begin
          i:= trunc((Width-(BlockWidth+FBlockSpace)*FHorCount)/2);
          X:= 1;
          while (X <= FHorCount) and (not Complete) do
            begin
              if (CurBlock+1)*FUnitPerBlock > FMax-FMin then
                case FLastBlockSize of
                  bsFull: BlockRect:= Rect(i, j, i+BlockWidth, j+BlockHeight);
                  bsHalf: BlockRect:= Rect(i, j, i+Max32(BlockWidth div 2, FBlockBoderWidth*2+1), j+BlockHeight);
                  bsProportional: BlockRect:= Rect(i, j, i+Max32(trunc(BlockWidth*(FMax-FMin-CurBlock*FUnitPerBlock)/FUnitPerBlock), FBlockBoderWidth*2+1), j+BlockHeight);
                end
              else
                BlockRect:= Rect(i, j, i+BlockWidth, j+BlockHeight);
                
              if (FPos > FMin) and ((FPos-FMin >= (CurBlock+1)*FUnitPerBlock) or ((FPos = FMax) and (CurBlock*FUnitPerBlock < FMax-FMin))) then
                begin
                  FBitMap.Canvas.Pen.Color:= FPassedBorderColor;
                  FBitMap.Canvas.Brush.Color:= FPassedBlockColor;
                  FBitMap.Canvas.Rectangle(BlockRect);
                end
              else
                if (FPos > FMin) and (FPos-FMin > CurBlock*FUnitPerBlock) and (FPos-FMin < (CurBlock+1)*FUnitPerBlock) then
                  begin
                    FBitMap.Canvas.Pen.Color:= FCurrentBorderColor;
                    FBitMap.Canvas.Brush.Color:= FCurrentBlockColor;
                    FBitMap.Canvas.Rectangle(BlockRect);
                  end
                else
                  if CurBlock*FUnitPerBlock < FMax-FMin then
                    begin
                      FBitMap.Canvas.Pen.Color:= FBlankBorderColor;
                      FBitMap.Canvas.Brush.Color:= FBlankBlockColor;
                      FBitMap.Canvas.Rectangle(BlockRect);
                    end
                  else
                    Complete:= true;

              if (not Complete) and (Assigned(FAfterBlockPaint)) then
                begin
                  Range.BlockFrom:= FMin+CurBlock*FUnitPerBlock;
                  Range.BlockTo:= Min64(FMin+(CurBlock+1)*FUnitPerBlock-1, FMax);
                  FAfterBlockPaint(Self, FBitMap.Canvas, BlockRect, Range);
                end;

              inc(i, BlockWidth+FBlockSpace);
              inc(CurBlock);
              inc(X);
            end;

          inc(j, BlockHeight+FBlockSpace);
          inc(Y);
        end;

      Canvas.CopyRect(FBitMap.Canvas.ClipRect, FBitMap.Canvas, FBitMap.Canvas.ClipRect);
    end;
end;

procedure TDriveProgressBar.Recalculate;
begin
  FUnitPerBlock:= (FMax-FMin) div (FHorCount*FVertCount);
  if FUnitPerBlock mod FMinUnitPerBlock > 0 then
    Inc(FUnitPerBlock, FMinUnitPerBlock-(FUnitPerBlock mod FMinUnitPerBlock));
  while (FMax-FMin)/FUnitPerBlock > FHorCount*FVertCount do inc(FUnitPerBlock, FMinUnitPerBlock);
end;

function TDriveProgressBar.Min64(const Arg1, Arg2: int64): int64;
begin
  if Arg1 < Arg2 then
    Result:= Arg1
  else
    Result:= Arg2;
end;

function TDriveProgressBar.Max32(const Arg1, Arg2: integer): integer;
begin
  if Arg1 > Arg2 then
    Result:= Arg1
  else
    Result:= Arg2;
end;

procedure TDriveProgressBar.SetHorCount(const Value: word);
begin
  if Value <> FHorCount then
    begin
      FHorCount:= Value;
      Recalculate;
      Paint;
    end;
end;

procedure TDriveProgressBar.SetVertCount(const Value: word);
begin
  if Value <> FVertCount then
    begin
      FVertCount:= Value;
      Recalculate;
      Paint;
    end;
end;

procedure TDriveProgressBar.SetMin(const Value: int64);
begin
  if Value <> FMin then
    if Value < FMax then
      begin
        FMin:= Value;
        if FPos < FMin then FPos:= FMin;
        Recalculate;
        Paint;
      end;
end;

procedure TDriveProgressBar.SetMax(const Value: int64);
begin
  if Value <> FMax then
    if Value > FMin then
      begin
        FMax:= Value;
        if FPos > FMax then FPos:= FMax;
        Recalculate;
        Paint;
      end;
end;

procedure TDriveProgressBar.SetPos(const Value: int64);
begin
  if Value <> FPos then
    if (Value >= FMin) and (Value <= FMax) then
      begin
        FPos:= Value;
        Paint;
      end
    else
      raise Exception.Create('Item index out of bounds ('+inttostr(Value)+')');
end;

procedure TDriveProgressBar.SetLastBlockSize(const Value: TLastBlockSize);
begin
  if Value <> FLastBlockSize then
    begin
      FLastBlockSize:= Value;
      Paint;
    end;
end;

procedure TDriveProgressBar.SetColor(const Value: TColor);
begin
  if Value <> FColor then
    begin
      FColor:= Value;
      Paint;
    end;
end;

procedure TDriveProgressBar.SetBlankBlockColor(const Value: TColor);
begin
  if Value <> FBlankBlockColor then
    begin
      FBlankBlockColor:= Value;
      Paint;
    end;
end;

procedure TDriveProgressBar.SetPassedBlockColor(const Value: TColor);
begin
  if Value <> FPassedBlockColor then
    begin
      FPassedBlockColor:= Value;
      Paint;
    end;
end;

procedure TDriveProgressBar.SetCurrentBlockColor(const Value: TColor);
begin
  if Value <> FCurrentBlockColor then
    begin
      FCurrentBlockColor:= Value;
      Paint;
    end;
end;

procedure TDriveProgressBar.SetBlankBorderColor(const Value: TColor);
begin
  if Value <> FBlankBorderColor then
    begin
      FBlankBorderColor:= Value;
      Paint;
    end;
end;

procedure TDriveProgressBar.SetPassedBorderColor(const Value: TColor);
begin
  if Value <> FPassedBorderColor then
    begin
      FPassedBorderColor:= Value;
      Paint;
    end;
end;

procedure TDriveProgressBar.SetCurrentBorderColor(const Value: TColor);
begin
  if Value <> FCurrentBorderColor then
    begin
      FCurrentBorderColor:= Value;
      Paint;
    end;
end;

procedure TDriveProgressBar.Reset;
begin
  if FPos <> FMin then SetPos(FMin);
end;

procedure TDriveProgressBar.SetMinUnitPerBlock(const Value: int64);
begin
  if Value <> FMinUnitPerBlock then
    begin
      FMinUnitPerBlock:= Value;
      Recalculate;
      Paint;
    end;
end;

////////////////////////////////////////////////////////////////////////////////

constructor TBlock.Create;
begin
  inherited Create;
  FDefault:= true;
  FColor:= clGray;
  FBorderColor:= clBlack;
  FChanged:= nil;
end;

destructor TBlock.Destroy;
begin
  inherited Destroy;
end;

procedure TBlock.SetColor(const Value: TColor);
begin
  if Value <> FColor then
    begin
      FColor:= Value;
      FDefault:= false;
      if Assigned(FChanged) then FChanged(Self);
    end;
end;

procedure TBlock.SetBorderColor(const Value: TColor);
begin
  if Value <> FBorderColor then
    begin
      FBorderColor:= Value;
      FDefault:= false;
      if Assigned(FChanged) then FChanged(Self);
    end;
end;

//////////////////////////////////////

constructor TBlocks.Create;
begin
  inherited Create;
  FLockUpdate:= false;
  FList:= TList.Create;
  FChanged:= nil;
end;

destructor TBlocks.Destroy;
begin
  Clear;
  FList.Free;
  inherited Destroy;
end;

function TBlocks.GetCount: integer;
begin
  Result:= FList.Count;
end;

function TBlocks.GetItem(const Index: integer): TBlock;
begin
  Result:= TBlock(FList[Index]);
end;

function TBlocks.Add(const Color, BorderColor: TColor): integer;
var
  Block: TBlock;
begin
  Block:= TBlock.Create;
  Block.Color:= Color;
  Block.BorderColor:= BorderColor;
  Block.OnChanged:= OnBlocksChanged;
  Block.Default:= true;
  Result:= FList.Add(Block);
end;

procedure TBlocks.Truncate(const NewCount: integer);
var
  i: integer;
begin
  for i:= NewCount to FList.Count-1 do TBlock(FList[i]).Free;
  FList.Count:= NewCount;
end;

procedure TBlocks.Clear;
begin
  Truncate(0);
end;

procedure TBlocks.OnBlocksChanged(Sender: TObject);
begin
  if Assigned(FChanged) and (not FLockUpdate) then FChanged(Self);
end;

procedure TBlocks.ReInit(const Color, BorderColor: TColor);
var
  i: integer;
begin
  FLockUpdate:= true;
  for i:= 0 to FList.Count-1 do
    if TBlock(FList[i]).Default then
      begin
        TBlock(FList[i]).Color:= Color;
        TBlock(FList[i]).BorderColor:= BorderColor;
        TBlock(FList[i]).Default:= true;
      end;
  FLockUpdate:= false;
end;

//////////////////////////////////////

constructor TDriveMap.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBlocks:= TBlocks.Create;
  FBlocks.OnChanged:= OnBlocksChanged;

  FNilBlock:= TBlock.Create;
  FNilBlock.Color:= FDefaultBlockColor;
  FNilBlock.BorderColor:= FDefaultBorderColor;
  FNilBlock.Default:= true;  
  FNilBlock.OnChanged:= OnNilBlockChanged;

  FBitMap:= TBitMap.Create;

  FHorCount:= 10;
  FVertCount:= 10;
  FBlockSpace:= 1;
  FBlockBoderWidth:= 1;
  FMin:= 0;
  FMax:= 1000;
  FMinUnitPerBlock:= 1;
  FUnitPerBlock:= FMinUnitPerBlock;

  FColor:= clbtnFace;
  FDefaultBlockColor:= clGray;
  FDefaultBorderColor:= clBlack;
  FLastBlockSize:= bsFull;

  FAfterBlockPaint:= nil;
  Width:= 200;
  Height:= 200;

  Recalculate;
end;

destructor TDriveMap.Destroy;
begin
  FNilBlock.Free;
  FBitMap.Free;
  FBlocks.Free;
  inherited Destroy;
end;

procedure TDriveMap.Paint;
var
  X, Y, i, j, BlockWidth, BlockHeight: word;
  CurBlock: cardinal;
  Complete: boolean;
  BlockRect: TRect;
  Range: TRange;
begin
  inherited Paint;

  if Parent <> nil then
    begin
      if FBitMap.Width <> Width then FBitMap.Width:= Width;
      if FBitMap.Height <> Height then FBitMap.Height:= Height;

      FBitMap.Canvas.Pen.Color:= FColor;
      FBitMap.Canvas.Pen.Width:= FBlockBoderWidth;
      FBitMap.Canvas.Pen.Style:= psSolid;
      FBitMap.Canvas.Brush.Color:= FColor;
      FBitMap.Canvas.Brush.Style:= bsSolid;
      FBitMap.Canvas.FillRect(FBitMap.Canvas.ClipRect);

      BlockWidth:= trunc((Width-(FHorCount+1)*FBlockSpace)/FHorCount);
      BlockHeight:= trunc((Height-(FVertCount+1)*FBlockSpace)/FVertCount);
      CurBlock:= 0;
      Complete:= false;
      j:= trunc((Height-(BlockHeight+FBlockSpace)*FVertCount)/2);
      Y:= 1;
      while (Y <= FVertCount) and (not Complete) do
        begin
          i:= trunc((Width-(BlockWidth+FBlockSpace)*FHorCount)/2);
          X:= 1;
          while (X <= FHorCount) and (not Complete) do
            begin
              if (CurBlock+1)*FUnitPerBlock > FMax-FMin then
                case FLastBlockSize of
                  bsFull: BlockRect:= Rect(i, j, i+BlockWidth, j+BlockHeight);
                  bsHalf: BlockRect:= Rect(i, j, i+Max32(BlockWidth div 2, FBlockBoderWidth*2+1), j+BlockHeight);
                  bsProportional: BlockRect:= Rect(i, j, i+Max32(trunc(BlockWidth*(FMax-FMin-CurBlock*FUnitPerBlock)/FUnitPerBlock), FBlockBoderWidth*2+1), j+BlockHeight);
                end
              else
                BlockRect:= Rect(i, j, i+BlockWidth, j+BlockHeight);

              if CurBlock*FUnitPerBlock < FMax-FMin then
                begin
                  FBitMap.Canvas.Pen.Color:= FBlocks[CurBlock].BorderColor;
                  FBitMap.Canvas.Brush.Color:= FBlocks[CurBlock].Color;
                  FBitMap.Canvas.Rectangle(BlockRect);
                end
              else
                Complete:= true;

              if (not Complete) and (Assigned(FAfterBlockPaint)) then
                begin
                  Range.BlockFrom:= FMin+CurBlock*FUnitPerBlock;
                  Range.BlockTo:= Min64(FMin+(CurBlock+1)*FUnitPerBlock-1, FMax);
                  FAfterBlockPaint(Self, FBitMap.Canvas, BlockRect, Range);
                end;

              inc(i, BlockWidth+FBlockSpace);
              inc(CurBlock);
              inc(X);
            end;

          inc(j, BlockHeight+FBlockSpace);
          inc(Y);
        end;

      Canvas.CopyRect(FBitMap.Canvas.ClipRect, FBitMap.Canvas, FBitMap.Canvas.ClipRect);
    end;
end;

procedure TDriveMap.Recalculate;
var
  i: int64;
begin
  FUnitPerBlock:= (FMax-FMin) div (FHorCount*FVertCount);
  if FUnitPerBlock mod FMinUnitPerBlock > 0 then
    Inc(FUnitPerBlock, FMinUnitPerBlock-(FUnitPerBlock mod FMinUnitPerBlock));
  while (FMax-FMin)/FUnitPerBlock > FHorCount*FVertCount do inc(FUnitPerBlock, FMinUnitPerBlock);

  FBlocks.Clear;
  i:= FMin;
  while i < FMax do
    begin
      FBlocks.Add(FDefaultBlockColor, FDefaultBorderColor);
      inc(i, FUnitPerBlock);
    end;
end;

function TDriveMap.Min64(const Arg1, Arg2: int64): int64;
begin
  if Arg1 < Arg2 then
    Result:= Arg1
  else
    Result:= Arg2;
end;

function TDriveMap.Max32(const Arg1, Arg2: integer): integer;
begin
  if Arg1 > Arg2 then
    Result:= Arg1
  else
    Result:= Arg2;
end;

function TDriveMap.GetBlock(const Position: int64): TBlock;
begin
  if (Position >= FMin) and (Position <= FMax) then
    if Position = FMin then
      Result:= FNilBlock
    else
      Result:= FBlocks[GetBlockIndex(Position-1)]
  else
    raise Exception.Create('Item index out of bounds ('+inttostr(Position)+')');    
end;

procedure TDriveMap.OnNilBlockChanged(Sender: TObject);
begin
  { nothing to do }
end;

procedure TDriveMap.SetHorCount(const Value: word);
begin
  if Value <> FHorCount then
    begin
      FHorCount:= Value;
      Recalculate;
      Paint;
    end;
end;

procedure TDriveMap.SetVertCount(const Value: word);
begin
  if Value <> FVertCount then
    begin
      FVertCount:= Value;
      Recalculate;
      Paint;
    end;
end;

procedure TDriveMap.SetMin(const Value: int64);
begin
  if Value <> FMin then
    if Value < FMax then
      begin
        FMin:= Value;
        Recalculate;
        Paint;
      end;
end;

procedure TDriveMap.SetMax(const Value: int64);
begin
  if Value <> FMax then
    if Value > FMin then
      begin
        FMax:= Value;
        Recalculate;
        Paint;
      end;
end;

procedure TDriveMap.SetColor(const Value: TColor);
begin
  if Value <> FColor then
    begin
      FColor:= Value;
      Paint;
    end;
end;

procedure TDriveMap.SetDefaultBlockColor(const Value: TColor);
begin
  if Value <> FDefaultBlockColor then
    begin
      FDefaultBlockColor:= Value;
      FBlocks.ReInit(FDefaultBlockColor, FDefaultBorderColor);
      FNilBlock.Color:= FDefaultBlockColor;
      FNilBlock.Default:= true;
      Paint;
    end;
end;

procedure TDriveMap.SetDefaultBorderColor(const Value: TColor);
begin
  if Value <> FDefaultBorderColor then
    begin
      FDefaultBorderColor:= Value;
      FBlocks.ReInit(FDefaultBlockColor, FDefaultBorderColor);
      FNilBlock.BorderColor:= FDefaultBorderColor;
      FNilBlock.Default:= true;
      Paint;
    end;
end;

procedure TDriveMap.Reset;
var
  i: int64;
begin
  FBlocks.Clear;
  i:= FMin;
  while i < FMax do
    begin
      FBlocks.Add(FDefaultBlockColor, FDefaultBorderColor);
      inc(i, FUnitPerBlock);
    end;
  FNilBlock.Color:= FDefaultBlockColor;
  FNilBlock.BorderColor:= FDefaultBorderColor;
  FNilBlock.Default:= true;  
  Paint;
end;

function TDriveMap.GetBlockIndex(const Position: int64): integer;
begin
  Result:= (Position-FMin) div FUnitPerBlock;
end;

procedure TDriveMap.OnBlocksChanged(Sender: TObject);
begin
  Paint;
end;

procedure TDriveMap.SetMinUnitPerBlock(const Value: int64);
begin
  if Value <> FMinUnitPerBlock then
    begin
      FMinUnitPerBlock:= Value;
      Recalculate;
      Paint;
    end;
end;

procedure TDriveMap.SetLastBlockSize(const Value: TLastBlockSize);
begin
  if Value <> FLastBlockSize then
    begin
      FLastBlockSize:= Value;
      Paint;
    end;
end;

end.

