//
//  PreferenceController.h
//  SyntheForex
//
//  Created by 佐山 隆裕 on 11/12/31.
//  Copyright (c) 2011年 tanuki-project. All rights reserved.
//

#ifndef SyntheForex_preference_h
#define SyntheForex_preference_h

#import     <Foundation/Foundation.h>

@interface PreferenceController : NSWindowController {
    IBOutlet NSComboBox             *serverComboBox;
    IBOutlet NSSegmentedControl     *digitSegmentControl;
    IBOutlet NSSegmentedControl     *alarmSegmentControl;
    IBOutlet NSButton               *checkAutoStartup;
    IBOutlet NSButton               *checkSkipSpeech;
    IBOutlet NSButton               *checkSortSubPanel;
    IBOutlet NSButton               *checkRelativeDate;
    IBOutlet NSTextField            *labelFourDigit;
    IBOutlet NSTextField            *labelAlarm;
    IBOutlet NSTextField            *labelSelectServer;
    IBOutlet NSTextField            *labelNote;
    IBOutlet NSTextFieldCell        *labelNoteTag;
    IBOutlet NSMatrix               *radioFormatSpeech;
    IBOutlet NSMatrix               *radioFormatDisplay;
    IBOutlet NSTextField            *labelFormatSpeech;
    IBOutlet NSTextField            *labelFormatDisplay;
    IBOutlet NSPanel                *preferenceWindow;
}

- (void)localizeView;

- (IBAction)selectServer:(id)sender;
- (IBAction)selectDigitSegment:(id)sender;
- (IBAction)setAutoStartup:(id)sender;
- (IBAction)setSkipUnchanged:(id)sender;
- (IBAction)setSortSubPanel:(id)sender;
- (IBAction)setShowRelativeDate:(id)sender;
- (IBAction)selectFormatSpeech:(id)sender;
- (IBAction)selectFormatDisplay:(id)sender;
- (IBAction)selectAlarmSegment:(id)sender;

@property (readwrite,assign)    NSComboBox      *serverComboBox;

@end

#endif
