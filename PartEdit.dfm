object fPartEdit: TfPartEdit
  Left = 337
  Top = 508
  BorderStyle = bsDialog
  Caption = 'New partition'
  ClientHeight = 111
  ClientWidth = 314
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lblCapSystemID: TLabel
    Left = 4
    Top = 4
    Width = 53
    Height = 13
    Caption = 'System ID:'
  end
  object cbSystemID: TComboBox
    Left = 80
    Top = 1
    Width = 126
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    ItemIndex = 0
    TabOrder = 0
    Text = 'FAT16'
    OnDropDown = cbSystemIDDropDown
    Items.Strings = (
      'FAT16'
      'FAT32'
      'FAT32 (LBA)'
      'FAT16 (LBA)')
  end
  object cbActivate: TCheckBox
    Left = 212
    Top = 4
    Width = 97
    Height = 17
    Hint = 'Make this partition bootable'
    BiDiMode = bdLeftToRight
    Caption = 'Active'
    ParentBiDiMode = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 1
  end
  object gbSize: TGroupBox
    Left = 0
    Top = 24
    Width = 313
    Height = 57
    Caption = ' Size '
    TabOrder = 2
    object lblState: TLabel
      Left = 2
      Top = 42
      Width = 309
      Height = 13
      Align = alBottom
      Alignment = taCenter
      AutoSize = False
    end
    object tbSize: TTrackBar
      Left = 2
      Top = 15
      Width = 309
      Height = 22
      Align = alTop
      TabOrder = 0
      ThumbLength = 10
      OnChange = tbSizeChange
    end
  end
  object btnCancel: TButton
    Left = 236
    Top = 84
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
  end
  object btnOk: TButton
    Left = 156
    Top = 84
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 4
  end
end
