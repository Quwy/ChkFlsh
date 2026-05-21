object fMain: TfMain
  Left = 192
  Top = 107
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Check Flash 1.17.0'
  ClientHeight = 369
  ClientWidth = 524
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PrintScale = poNone
  Scaled = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Panel5: TPanel
    Left = 0
    Top = 0
    Width = 312
    Height = 369
    Align = alLeft
    BevelOuter = bvNone
    Caption = ' '
    TabOrder = 0
    object gbAccessType: TGroupBox
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 306
      Height = 77
      Align = alTop
      Caption = ' Access type '
      TabOrder = 0
      object rbTempFile: TRadioButton
        Left = 4
        Top = 16
        Width = 297
        Height = 17
        Hint = 
          'Write/read simple temporary file, absolutely safe and minimum fe' +
          'atures (index: 0)'
        Caption = 'Use temporary file'
        Checked = True
        ParentShowHint = False
        ShowHint = True
        TabOrder = 0
        TabStop = True
        OnClick = rbTempFileClick
      end
      object rbPhysical: TRadioButton
        Left = 4
        Top = 56
        Width = 297
        Height = 17
        Hint = 
          'Access as entire drive, unsafe for all partitions on selected de' +
          'vice and full features (index: 2)'
        Caption = 'As physical device (NT-based systems only)'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 1
        OnClick = rbPhysicalClick
      end
      object rbLogical: TRadioButton
        Left = 4
        Top = 36
        Width = 297
        Height = 17
        Hint = 
          'Access on partition-level, safe for all partitions, except selec' +
          'ted and medium features (index: 1)'
        Caption = 'As logical drive (NT-based systems only)'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 2
        OnClick = rbLogicalClick
      end
    end
    object gbInfo: TGroupBox
      AlignWithMargins = True
      Left = 3
      Top = 260
      Width = 306
      Height = 77
      Align = alTop
      Caption = ' Information '
      TabOrder = 1
      object lblCapCompletedCycles: TLabel
        Left = 3
        Top = 17
        Width = 87
        Height = 13
        Caption = 'Completed cycles:'
      end
      object lblCompletedCycles: TLabel
        Left = 96
        Top = 16
        Width = 45
        Height = 13
        Alignment = taRightJustify
        AutoSize = False
        Color = clBtnFace
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clNavy
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentColor = False
        ParentFont = False
      end
      object lblCapErrorsFound: TLabel
        Left = 161
        Top = 16
        Width = 64
        Height = 13
        Caption = 'Errors found:'
      end
      object lblErrorsFound: TLabel
        Left = 227
        Top = 16
        Width = 71
        Height = 13
        Alignment = taRightJustify
        AutoSize = False
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clNavy
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object lblCapReadSpeed: TLabel
        Left = 4
        Top = 36
        Width = 61
        Height = 13
        Caption = 'Read speed:'
      end
      object lblReadSpeed: TLabel
        Left = 70
        Top = 36
        Width = 71
        Height = 13
        Alignment = taRightJustify
        AutoSize = False
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clNavy
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object lblCapWriteSpeed: TLabel
        Left = 161
        Top = 36
        Width = 62
        Height = 13
        Caption = 'Write speed:'
      end
      object lblWriteSpeed: TLabel
        Left = 227
        Top = 37
        Width = 71
        Height = 13
        Alignment = taRightJustify
        AutoSize = False
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clNavy
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object lblCapElapsed: TLabel
        Left = 4
        Top = 56
        Width = 41
        Height = 13
        Caption = 'Elapsed:'
      end
      object lblElapsed: TLabel
        Left = 70
        Top = 56
        Width = 71
        Height = 13
        Alignment = taRightJustify
        AutoSize = False
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clNavy
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object lblCapRemain: TLabel
        Left = 161
        Top = 56
        Width = 61
        Height = 13
        Caption = 'Pass remain:'
      end
      object lblRemain: TLabel
        Left = 227
        Top = 56
        Width = 71
        Height = 13
        Alignment = taRightJustify
        AutoSize = False
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clNavy
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
    end
    object Panel1: TPanel
      AlignWithMargins = True
      Left = 3
      Top = 86
      Width = 306
      Height = 37
      Align = alTop
      BevelInner = bvRaised
      BevelOuter = bvLowered
      Caption = ' '
      TabOrder = 2
      object pcDeviceSelect: TPageControl
        Left = 2
        Top = 2
        Width = 272
        Height = 33
        ActivePage = tsDrive
        Align = alClient
        Style = tsButtons
        TabOrder = 0
        object tsDrive: TTabSheet
          Caption = 'Temporary file'
          TabVisible = False
          object lblCapDrive: TLabel
            AlignWithMargins = True
            Left = 3
            Top = 5
            Width = 29
            Height = 15
            Margins.Top = 5
            Align = alLeft
            Caption = 'Drive:'
            ExplicitHeight = 13
          end
          object cbDrive: TComboBox
            AlignWithMargins = True
            Left = 38
            Top = 0
            Width = 226
            Height = 23
            Margins.Top = 0
            Margins.Right = 0
            Margins.Bottom = 0
            Align = alClient
            Style = csDropDownList
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Courier New'
            Font.Style = []
            ItemHeight = 15
            ParentFont = False
            Sorted = True
            TabOrder = 0
            OnDropDown = cbDriveDropDown
          end
        end
        object tsDevice: TTabSheet
          Caption = 'Physical'
          ImageIndex = 1
          TabVisible = False
          ExplicitLeft = 0
          ExplicitTop = 0
          ExplicitWidth = 0
          ExplicitHeight = 0
          object lblCapDevice: TLabel
            AlignWithMargins = True
            Left = 3
            Top = 5
            Width = 36
            Height = 13
            Margins.Top = 5
            Margins.Right = 5
            Align = alLeft
            Caption = 'Device:'
          end
          object cbDevice: TComboBox
            Left = 44
            Top = 0
            Width = 220
            Height = 23
            Align = alClient
            Style = csDropDownList
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Courier New'
            Font.Style = []
            ItemHeight = 0
            ParentFont = False
            Sorted = True
            TabOrder = 0
            OnDropDown = cbDriveDropDown
          end
        end
      end
      object Panel10: TPanel
        Left = 274
        Top = 2
        Width = 30
        Height = 33
        Align = alRight
        BevelOuter = bvNone
        Caption = ' '
        TabOrder = 1
        object sbRedrives: TSpeedButton
          AlignWithMargins = True
          Left = 0
          Top = 6
          Width = 24
          Height = 22
          Hint = 'Refresh list'
          Margins.Left = 0
          Margins.Top = 6
          Margins.Right = 6
          Margins.Bottom = 5
          Align = alClient
          BiDiMode = bdLeftToRight
          Caption = '&'
          Glyph.Data = {
            32010000424D3201000000000000360000002800000009000000090000000100
            180000000000FC00000000000000000000000000000000000000FFFFFF019901
            FFFFFF71C57041AA3081BB5EFFFFFFFFFFFFFFFFFF00FFFFFF01990101990101
            990101990101990141AA2FFFFFFFFFFFFF00FFFFFF019901019901119E0ECFD6
            A3FFFFFF21A21AFFFFFFFFFFFF00FFFFFF019901019901019901019901FFFFFF
            FFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            FFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFF019901019901019901FFFFFFFFFF
            FF00FFFFFF119F10AFD8A0FFFFFFFFFFFF019901019901FFFFFFFFFFFF00FFFF
            FF71C570019901019901019901019901019901FFFFFFFFFFFF00FFFFFFFFFFFF
            71C570019901019901AFD8A0019901FFFFFFFFFFFF00}
          ParentShowHint = False
          ParentBiDiMode = False
          ShowHint = True
          OnClick = sbRedrivesClick
          ExplicitLeft = 8
          ExplicitTop = 8
          ExplicitWidth = 23
        end
      end
    end
    object Panel6: TPanel
      AlignWithMargins = True
      Left = 3
      Top = 343
      Width = 306
      Height = 25
      Align = alTop
      BevelInner = bvRaised
      BevelOuter = bvLowered
      Caption = ' '
      TabOrder = 3
      object pbMain: TProgressBar
        Left = 4
        Top = 4
        Width = 297
        Height = 16
        Step = 1
        TabOrder = 0
      end
    end
    object Panel2: TPanel
      Left = 0
      Top = 126
      Width = 312
      Height = 131
      Align = alTop
      BevelOuter = bvNone
      Caption = ' '
      TabOrder = 4
      object gbActionType: TGroupBox
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 163
        Height = 125
        Align = alClient
        Caption = ' Action type '
        TabOrder = 0
        object sbActionType: TScrollBox
          Left = 2
          Top = 15
          Width = 159
          Height = 108
          HorzScrollBar.Visible = False
          VertScrollBar.Position = 170
          VertScrollBar.Tracking = True
          Align = alClient
          BorderStyle = bsNone
          Ctl3D = True
          ParentCtl3D = False
          TabOrder = 0
          object lblCapPattern2: TLabel
            Left = 21
            Top = 89
            Width = 36
            Height = 13
            Caption = 'Pattern'
            Enabled = False
          end
          object rbReadTest: TRadioButton
            Left = 3
            Top = -167
            Width = 137
            Height = 17
            Hint = 
              'Read all data few times with verification of CRC given on the fi' +
              'rst pass (index: 0)'
            Caption = 'Read stability test'
            Enabled = False
            ParentShowHint = False
            ShowHint = True
            TabOrder = 0
            OnClick = rbReadTestClick
          end
          object rbWriteTest: TRadioButton
            Left = 3
            Top = -144
            Width = 137
            Height = 17
            Hint = 'Write test patterns and verification of read data (index: 1)'
            Caption = 'Write and read test'
            Checked = True
            ParentShowHint = False
            ShowHint = True
            TabOrder = 1
            TabStop = True
            OnClick = rbReadTestClick
          end
          object Panel11: TPanel
            Left = 15
            Top = -121
            Width = 125
            Height = 110
            BevelOuter = bvLowered
            Caption = ' '
            TabOrder = 2
            object lblCapPattern: TLabel
              Left = 22
              Top = 87
              Width = 36
              Height = 13
              Caption = 'Pattern'
              Enabled = False
            end
            object rbSmallPattern: TRadioButton
              Left = 4
              Top = 4
              Width = 117
              Height = 17
              Hint = 'Use two test patterns: 55h, AAh (index: 0)'
              Caption = 'Small pattern set'
              Checked = True
              ParentShowHint = False
              ShowHint = True
              TabOrder = 0
              TabStop = True
              OnClick = rbReadTestClick
            end
            object rbFullPattern: TRadioButton
              Left = 4
              Top = 24
              Width = 117
              Height = 17
              Hint = 
                'Use 18 patterns: 8 of "walking one", 8 of "walking zero", 55h, A' +
                'Ah (index: 1)'
              Caption = 'Full pattern set'
              ParentShowHint = False
              ShowHint = True
              TabOrder = 1
              OnClick = rbReadTestClick
            end
            object rbDelayedWrite: TRadioButton
              Left = 4
              Top = 44
              Width = 117
              Height = 17
              Hint = 'Only write pattern (index: 2)'
              Caption = 'Write pattern'
              ParentShowHint = False
              ShowHint = True
              TabOrder = 2
              OnClick = rbReadTestClick
            end
            object rbDelayedVerify: TRadioButton
              Left = 4
              Top = 64
              Width = 117
              Height = 17
              Hint = 'Only verify pattern (index: 3)'
              Caption = 'Verify pattern'
              ParentShowHint = False
              ShowHint = True
              TabOrder = 3
              OnClick = rbReadTestClick
            end
            object cbPattern: TComboBox
              Left = 79
              Top = 83
              Width = 42
              Height = 21
              Hint = 'Pattern for delayed write test'
              Style = csDropDownList
              Enabled = False
              ItemHeight = 13
              ParentShowHint = False
              ShowHint = True
              TabOrder = 4
              Items.Strings = (
                '55'
                'AA'
                '00'
                '01'
                '02'
                '04'
                '08'
                '10'
                '20'
                '40'
                '80'
                'FF'
                'FE'
                'FD'
                'FB'
                'F7'
                'EF'
                'DF'
                'BF'
                '7F')
            end
          end
          object rbPartEdit: TRadioButton
            Left = 3
            Top = -2
            Width = 137
            Height = 17
            Hint = 'Edit partition information of the selected device (index: 2)'
            Caption = 'Low level initialization'
            Enabled = False
            ParentShowHint = False
            ShowHint = True
            TabOrder = 3
            OnClick = rbReadTestClick
          end
          object rbSave: TRadioButton
            Left = 3
            Top = 21
            Width = 137
            Height = 17
            Hint = 
              'Save full binary image of selected partition or device to the fi' +
              'le (index: 3)'
            Caption = 'Save image'
            Enabled = False
            ParentShowHint = False
            ShowHint = True
            TabOrder = 4
            OnClick = rbReadTestClick
          end
          object rbLoad: TRadioButton
            Left = 3
            Top = 44
            Width = 137
            Height = 17
            Hint = 
              'Write previosly saved  binary image to the selected partition or' +
              ' device (index: 4)'
            Caption = 'Load image'
            Enabled = False
            ParentShowHint = False
            ShowHint = True
            TabOrder = 5
            OnClick = rbReadTestClick
          end
          object rbErase: TRadioButton
            Left = 3
            Top = 67
            Width = 137
            Height = 17
            Hint = 'Erase all drive surface (index: 5)'
            Caption = 'Full erase'
            Enabled = False
            ParentShowHint = False
            ShowHint = True
            TabOrder = 6
            OnClick = rbReadTestClick
          end
          object edPattern: TEdit
            Left = 68
            Top = 87
            Width = 72
            Height = 21
            Hint = 'Pattern for full erase (hex numbers only)'
            Enabled = False
            ParentShowHint = False
            ShowHint = True
            TabOrder = 7
            Text = 'FF'
            OnKeyPress = edPatternKeyPress
          end
        end
      end
      object gbTestLength: TGroupBox
        AlignWithMargins = True
        Left = 172
        Top = 3
        Width = 137
        Height = 125
        Align = alRight
        Caption = ' Test length '
        TabOrder = 1
        object lblCapCycles: TLabel
          Left = 87
          Top = 79
          Width = 29
          Height = 13
          Caption = 'cycles'
          Enabled = False
        end
        object rbContinous: TRadioButton
          Left = 4
          Top = 36
          Width = 129
          Height = 17
          Hint = 'Continous testing until manual canel (index: 1)'
          Caption = 'Burn it!'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 0
          OnClick = rbManualClick
        end
        object rbOnePass: TRadioButton
          Left = 4
          Top = 16
          Width = 129
          Height = 17
          Hint = 'Perform one cycle of selected test and stop (index: 0)'
          Caption = 'One full pass'
          Checked = True
          ParentShowHint = False
          ShowHint = True
          TabOrder = 1
          TabStop = True
          OnClick = rbManualClick
        end
        object rbManual: TRadioButton
          Left = 4
          Top = 56
          Width = 129
          Height = 17
          Hint = 'Manual cycles count (index: 2)'
          Caption = 'Manual'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 2
          OnClick = rbManualClick
        end
        object seCycles: TSpinEdit
          Left = 24
          Top = 76
          Width = 57
          Height = 22
          Hint = 'Manual cycles count'
          Enabled = False
          MaxLength = 4
          MaxValue = 9999
          MinValue = 1
          ParentShowHint = False
          ShowHint = True
          TabOrder = 3
          Value = 1
        end
        object rbTillError: TRadioButton
          Left = 4
          Top = 104
          Width = 129
          Height = 17
          Hint = 'Perform continous test until first error found (index: 3)'
          Caption = 'Until first error found'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 4
          OnClick = rbManualClick
        end
      end
    end
  end
  object Panel3: TPanel
    Left = 312
    Top = 0
    Width = 212
    Height = 369
    Align = alClient
    BevelOuter = bvNone
    Caption = ' '
    TabOrder = 1
    object pcMain: TPageControl
      Left = 0
      Top = 0
      Width = 212
      Height = 338
      ActivePage = tsDriveMap
      Align = alClient
      TabOrder = 0
      object tsDriveMap: TTabSheet
        Caption = 'Drive map'
        object Panel4: TPanel
          Left = 0
          Top = 0
          Width = 204
          Height = 295
          Align = alClient
          BevelOuter = bvLowered
          Caption = ' '
          TabOrder = 0
        end
        object Panel8: TPanel
          Left = 0
          Top = 295
          Width = 204
          Height = 15
          Align = alBottom
          BevelOuter = bvNone
          Caption = ' '
          TabOrder = 1
          object lblBlockWeight: TLabel
            AlignWithMargins = True
            Left = 0
            Top = 2
            Width = 186
            Height = 13
            Margins.Left = 0
            Margins.Top = 2
            Margins.Right = 0
            Margins.Bottom = 0
            Align = alClient
            AutoSize = False
            ExplicitLeft = -1
            ExplicitWidth = 172
            ExplicitHeight = 14
          end
          object lblStage: TLabel
            AlignWithMargins = True
            Left = 186
            Top = 2
            Width = 16
            Height = 13
            Margins.Left = 0
            Margins.Top = 2
            Margins.Right = 2
            Margins.Bottom = 0
            Align = alRight
            Alignment = taRightJustify
            Constraints.MinWidth = 16
            ExplicitLeft = 199
          end
        end
      end
      object tsLog: TTabSheet
        Caption = 'Log'
        ImageIndex = 1
        ExplicitLeft = 0
        ExplicitTop = 0
        ExplicitWidth = 0
        ExplicitHeight = 0
        object Panel12: TPanel
          Left = 0
          Top = 284
          Width = 204
          Height = 26
          Align = alBottom
          BevelOuter = bvNone
          TabOrder = 0
          object cbScrollLog: TCheckBox
            Left = 2
            Top = 6
            Width = 199
            Height = 17
            Hint = 'Limit log size by 64KB and scroll lines if exceeds'
            Caption = 'Scroll log'
            Checked = True
            ParentShowHint = False
            ShowHint = True
            State = cbChecked
            TabOrder = 0
          end
        end
        object reLog: TRichEdit
          Left = 0
          Top = 0
          Width = 204
          Height = 284
          Align = alClient
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Courier New'
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 1
          WordWrap = False
        end
      end
      object tsLegend: TTabSheet
        Caption = 'Legend'
        ImageIndex = 2
        ExplicitLeft = 0
        ExplicitTop = 0
        ExplicitWidth = 0
        ExplicitHeight = 0
        object Panel9: TPanel
          Left = 0
          Top = 0
          Width = 204
          Height = 310
          Align = alClient
          BevelOuter = bvLowered
          Caption = ' '
          TabOrder = 0
          object shUntouched: TShape
            Left = 8
            Top = 8
            Width = 13
            Height = 17
            Hint = 'Unprocessed block'
            Brush.Color = clGray
            ParentShowHint = False
            ShowHint = True
          end
          object lblCapUntouched: TLabel
            Left = 31
            Top = 10
            Width = 52
            Height = 13
            Hint = 'Unprocessed block'
            Caption = 'Untouched'
            ParentShowHint = False
            ShowHint = True
          end
          object shRead: TShape
            Left = 8
            Top = 31
            Width = 13
            Height = 17
            Hint = 'Block successfully read'
            Brush.Color = clBlue
            ParentShowHint = False
            ShowHint = True
          end
          object lblCapRead: TLabel
            Left = 31
            Top = 33
            Width = 25
            Height = 13
            Hint = 'Block successfully read'
            Caption = 'Read'
            ParentShowHint = False
            ShowHint = True
          end
          object shVerified: TShape
            Left = 8
            Top = 54
            Width = 13
            Height = 17
            Hint = 'Block successfully read and its content pass CRC check'
            Brush.Color = clGreen
            ParentShowHint = False
            ShowHint = True
          end
          object lblCapVerified: TLabel
            Left = 31
            Top = 56
            Width = 36
            Height = 13
            Hint = 'Block successfully read and its content pass CRC check'
            Caption = 'Verified'
            ParentShowHint = False
            ShowHint = True
          end
          object shWritten: TShape
            Left = 8
            Top = 77
            Width = 13
            Height = 17
            Hint = 'Block successfully written'
            Brush.Color = clPurple
            ParentShowHint = False
            ShowHint = True
          end
          object lblCapWritten: TLabel
            Left = 31
            Top = 79
            Width = 36
            Height = 13
            Hint = 'Block successfully written'
            Caption = 'Written'
            ParentShowHint = False
            ShowHint = True
          end
          object shError: TShape
            Left = 8
            Top = 100
            Width = 13
            Height = 17
            Hint = 'This mean what one or more sectors in the block cannot be read'
            Brush.Color = clRed
            ParentShowHint = False
            ShowHint = True
          end
          object lblCapError: TLabel
            Left = 31
            Top = 102
            Width = 92
            Height = 13
            Hint = 'This mean what one or more sectors in the block cannot be read'
            Caption = 'Physical drive error'
            ParentShowHint = False
            ShowHint = True
          end
          object shCRCError: TShape
            Left = 8
            Top = 123
            Width = 13
            Height = 17
            Hint = 'Block was successfully read, but its data CRC failed'
            Brush.Color = clYellow
            ParentShowHint = False
            ShowHint = True
          end
          object lblCapCRCFail: TLabel
            Left = 31
            Top = 125
            Width = 84
            Height = 13
            Hint = 'Block was successfully read, but its data CRC failed'
            Caption = 'Logical data error'
            ParentShowHint = False
            ShowHint = True
          end
          object lblCapDetails: TLabel
            AlignWithMargins = True
            Left = 93
            Top = 296
            Width = 107
            Height = 13
            Margins.Left = 0
            Margins.Top = 0
            Margins.Bottom = 0
            Align = alBottom
            Alignment = taRightJustify
            Caption = '* see hints for details.'
          end
        end
      end
    end
    object Panel7: TPanel
      Left = 0
      Top = 338
      Width = 212
      Height = 31
      Align = alBottom
      BevelOuter = bvNone
      Caption = ' '
      TabOrder = 1
      object btnStart: TButton
        Left = 4
        Top = 4
        Width = 97
        Height = 25
        Caption = 'Start!'
        Default = True
        TabOrder = 0
        OnClick = btnStartClick
      end
      object btnStop: TButton
        Left = 104
        Top = 4
        Width = 101
        Height = 25
        Cancel = True
        Caption = 'Stop'
        Enabled = False
        TabOrder = 1
        OnClick = btnStopClick
      end
    end
  end
  object odImage: TOpenDialog
    DefaultExt = 'IMG'
    Filter = 
      'Images (*.img)|*.img|Compressed images (*.zim)|*.zim|All files|*' +
      '.*'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofNoChangeDir, ofEnableSizing]
    Title = 'Restore full image'
    Left = 332
    Top = 184
  end
  object sdImage: TSaveDialog
    DefaultExt = 'IMG'
    Filter = 
      'Images (*.img)|*.img|Compressed images (*.zim)|*.zim|All files|*' +
      '.*'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofNoChangeDir, ofEnableSizing]
    Title = 'Save full image'
    Left = 332
    Top = 216
  end
  object tmrTimer: TTimer
    Enabled = False
    OnTimer = tmrTimerTimer
    Left = 332
    Top = 248
  end
end
