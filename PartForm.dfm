object fPartitions: TfPartitions
  Left = 189
  Top = 114
  BorderStyle = bsDialog
  Caption = 'Partitions'
  ClientHeight = 170
  ClientWidth = 553
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object gbPartTable: TGroupBox
    Left = 0
    Top = 0
    Width = 553
    Height = 137
    Align = alTop
    Caption = ' Partition table '
    TabOrder = 0
    object lvPartTable: TListView
      Left = 2
      Top = 15
      Width = 549
      Height = 90
      Align = alTop
      Columns = <
        item
          Caption = 'No.'
          Width = 30
        end
        item
          Alignment = taCenter
          Caption = 'Status'
          Width = 65
        end
        item
          Caption = 'SystemID'
          Width = 80
        end
        item
          Caption = 'StartCyl'
          Width = 60
        end
        item
          Caption = 'StartHead'
          Width = 60
        end
        item
          Caption = 'StartSect'
          Width = 60
        end
        item
          Caption = 'Sectors'
          Width = 70
        end
        item
          Alignment = taRightJustify
          Caption = 'Size'
          Width = 100
        end>
      ColumnClick = False
      HideSelection = False
      ReadOnly = True
      RowSelect = True
      ParentShowHint = False
      ShowHint = False
      TabOrder = 0
      ViewStyle = vsReport
      OnSelectItem = lvPartTableSelectItem
    end
    object btnNew: TButton
      Left = 4
      Top = 108
      Width = 75
      Height = 25
      Hint = 'Initialize selected empty partition table entry'
      Caption = 'New...'
      Enabled = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
      OnClick = btnNewClick
    end
    object btnUp: TButton
      Left = 514
      Top = 108
      Width = 35
      Height = 25
      Hint = 'Move selected partition table entry up'
      Caption = 'Up'
      Enabled = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
      OnClick = btnUpClick
    end
    object btnDn: TButton
      Left = 478
      Top = 108
      Width = 35
      Height = 25
      Hint = 'Move selected partition table entry down'
      Caption = 'Dn'
      Enabled = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
      OnClick = btnDnClick
    end
    object btnDelete: TButton
      Left = 80
      Top = 108
      Width = 75
      Height = 25
      Hint = 'Free selected partition table entry'
      Caption = 'Delete'
      Enabled = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 4
      OnClick = btnDeleteClick
    end
    object btnActivate: TButton
      Left = 156
      Top = 108
      Width = 75
      Height = 25
      Hint = 
        'Make selected partition table entry bootable and deactivate curr' +
        'ent bootable record if any'
      Caption = 'Activate'
      Enabled = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 5
      OnClick = btnActivateClick
    end
    object cbShowAll: TCheckBox
      Left = 356
      Top = 112
      Width = 118
      Height = 17
      Hint = 'Show corrupted partition table entries in the partition table'
      Caption = 'Show corrupted'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 6
      OnClick = cbShowAllClick
    end
    object btnSave: TButton
      Left = 240
      Top = 108
      Width = 55
      Height = 25
      Hint = 'Save entire MBR (including partition table) to the file'
      Caption = 'Save...'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 7
      OnClick = btnSaveClick
    end
    object btnLoad: TButton
      Left = 296
      Top = 108
      Width = 55
      Height = 25
      Hint = 
        'Write entire MBR (including partition table) from previosly save' +
        'd MBR-file or full image file to the current device'
      Caption = 'Load...'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 8
      OnClick = btnLoadClick
    end
  end
  object btnCancel: TButton
    Left = 476
    Top = 143
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
  end
  object btnOk: TButton
    Left = 396
    Top = 143
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 2
  end
  object mmHint: TMemo
    Left = 0
    Top = 140
    Width = 390
    Height = 30
    BorderStyle = bsNone
    Color = clBtnFace
    Ctl3D = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clRed
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentCtl3D = False
    ParentFont = False
    ReadOnly = True
    TabOrder = 3
  end
  object sdPartTable: TSaveDialog
    DefaultExt = 'MBR'
    Filter = 'MBR Images (*.mbr)|*.mbr|All files|*.*'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofNoChangeDir, ofEnableSizing]
    Title = 'Save partition table'
    Left = 12
    Top = 140
  end
  object odPartTable: TOpenDialog
    DefaultExt = 'MBR'
    Filter = 
      'MBR Images (*.mbr)|*.mbr|Full images (*.img)|*.img|Compressed im' +
      'ages (*.zim)|*.zim|All files|*.*'
    Options = [ofHideReadOnly, ofNoChangeDir, ofEnableSizing]
    Title = 'Load partition table'
    Left = 44
    Top = 140
  end
end
