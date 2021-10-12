//
//  AppDelegate.h
//  SyntheForex
//
//  Created by 佐山 隆裕 on 11/12/25.
//  Copyright (c) 2011年 tanuki-project. All rights reserved.
//

#import     <Cocoa/Cocoa.h>

#include    "PreferenceController.h"
#include    "webAccess.h"
#include    "infoPanel.h"

#define NUMBER_OF_RATES             12
#define DEFAULT_SPEECH_SPEED        180
#define DEFAULT_SPEECH_VOLUME       1.0
#define DEFAULT_SPEECH_INTERVAL     5

@interface AppDelegate : NSObject <NSApplicationDelegate,NSSpeechSynthesizerDelegate> {
    int                         playIndex;
    bool                        playing;
    bool                        suspending;
    bool                        updating;
    int                         countDown;
    NSTimer*                    intervalTimer;
    NSSpeechSynthesizer         *speechSynth;
    NSArray                     *voiceList;
    webAccess                   *webConnection;
    NSMutableArray              *currencyList;
    NSMutableArray              *currencyRates;
    PreferenceController        *preferenceContriller;
    infoPanel                   *iPanel;
    IBOutlet NSWindow           *mainWindow;
    IBOutlet NSTableView        *tableView;
    IBOutlet NSArrayController *arrayController;
    IBOutlet NSDateFormatter    *dateFormatter;
    IBOutlet NSButton           *startButton;
    IBOutlet NSButton           *playButton;
    IBOutlet NSButton           *webButton;
    IBOutlet NSButton           *updateButton;
    IBOutlet NSButton           *buttonRepeat;
    IBOutlet NSTextField        *playLable;
    IBOutlet NSComboBox         *voiceComboBox;
    IBOutlet NSSlider           *voiceSlider;
    IBOutlet NSSlider           *volumeSlider;
    IBOutlet NSStepper          *intervalStepper;
    IBOutlet NSTextField        *intervalTextField;
    IBOutlet NSMenuItem         *menuAbout;
    IBOutlet NSMenuItem         *menuPreference;
    IBOutlet NSMenuItem         *menuHide;
    IBOutlet NSMenuItem         *menuHideOthers;
    IBOutlet NSMenuItem         *menuShowAll;
    IBOutlet NSMenuItem         *menuQuit;
    IBOutlet NSMenu             *menuControls;
    IBOutlet NSMenuItem         *menuStartSpeaking;
    IBOutlet NSMenuItem         *menuStopSpeaking;
    IBOutlet NSMenuItem         *menuUpdate;
    IBOutlet NSMenuItem         *menuShowWebSite;
    IBOutlet NSMenuItem         *menuVerify;
    IBOutlet NSMenuItem         *menuShowWindow;
    IBOutlet NSMenuItem         *menuShowPanel;
    IBOutlet NSMenuItem         *menuReadPanel;
    IBOutlet NSMenuItem         *menuCopyPanel;
    IBOutlet NSComboBoxCell     *comboBoxTargetCode;
    IBOutlet NSComboBoxCell     *comboBoxAgainstCode;
    IBOutlet NSImageView        *imageSound;
    IBOutlet NSMenuItem         *menuVoice;
    IBOutlet NSMenuItem         *menuServer;
    IBOutlet NSMenuItem         *menuTarget;
    IBOutlet NSMenuItem         *menuAgainst;
}

- (void)initCurrencyRates;
- (void)saveCurrencyRates;
- (void)loadCurrencyRates;
- (void)setCurrencyList;
- (void)startObservingCurrencyRate:(CurrencyRate*)item;
- (void)stopObservingCurrenctRate:(CurrencyRate*)item;
- (void)changeKeyPath:(NSString*)keyPath obObject:(id)obj toValue:(id)newValue;
- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
- (void)startSpeech:(NSString*)text;
- (void)stopSpeech;
- (NSString*)getCurrencyName:(NSString*)lang :(NSString*)code;
- (NSString*)getCurrencySymble:(NSString*)code;
- (void)enableRequest:(bool) available;
- (int)getNextIndex:(int)index;
- (bool)volumeMuted;
- (NSString*)voiceName:(int)index;
- (NSString*)voiceLocaleIdentifier:(NSString*)voice;
- (void)localizeView;
- (void)buildVoiceMenu;
- (void)buildServerMenu;
- (void)setVoiceMenu;
- (void)setServerMenu;
- (void)setTargetMenu;
- (void)setAgainstMenu;
- (void)refreshPanel;
- (void)actionTerminate:(NSNotification *)notification;
- (void)actionSleep:(NSNotification *)notification;

- (IBAction)startButton:(id)sender;
- (IBAction)playButton:(id)sender;
- (IBAction)playStart:(id)sender;
- (IBAction)playStop:(id)sender;
- (IBAction)updateStart:(id)sender;
- (IBAction)startVerify:(id)sender;
- (IBAction)showWebSite:(id)sender;
- (IBAction)showWindow:(id)sender;
- (IBAction)showPanel:(id)sender;
- (IBAction)seletcVoice:(id)sender;
- (IBAction)changeVoiceSlider:(id)sender;
- (IBAction)changeVolumeSlider:(id)sender;
- (IBAction)changeInterval:(id)sender;
- (IBAction)showPreferencePanel:(id)sender;
- (IBAction)selectVoiceMenu:(id)sender;
- (IBAction)selectServerMenu:(id)sender;
- (IBAction)selectTargetMenu:(id)sender;
- (IBAction)selectAgainstMenu:(id)sender;
- (IBAction)readPanel:(id)sender;
- (IBAction)copyPanel:(id)sender;
- (IBAction)setRepeat:(id)sender;

//@property (assign) IBOutlet     NSWindow        *window;
@property (readwrite,retain)	NSMutableArray  *currencyRates;
@property (readwrite)           bool            updating;
@property (readwrite)           bool            playing;
@property (readwrite,assign)    NSWindow        *mainWindow;
@property (readwrite,assign)	infoPanel*		iPanel;
@property (readwrite,assign)	webAccess*      webConnection;;
@property (readwrite,assign)    NSSlider        *volumeSlider;
@property (readwrite,assign)    NSTableView     *tableView;
@property (readwrite,assign)    NSDateFormatter *dateFormatter;
@end
