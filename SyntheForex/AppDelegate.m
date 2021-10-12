//
//  AppDelegate.m
//  SyntheForex
//
//  Created by 佐山 隆裕 on 11/12/25.
//  Copyright (c) 2011年 tanuki-project. All rights reserved.
//

#import     "AppDelegate.h"
#include    "build.h"

AppDelegate     *syntheTickerDelegate;

bool            autoStartupSpeech = NO;
bool            skipSpeechUnchanged = NO;
bool            sortSubPanel = NO;
bool            showRelativeDate = NO;
bool            showSubPanel = NO;
bool            lockSubPanel = YES;
bool            willTerminate = NO;
bool            repeat = YES;
NSString		*speechVoice = nil;
NSString		*speechVoiceLocaleIdentifier = nil;
NSString        *serverSelection = nil;
double          digitThreshold = DEFAULT_DIGIT_THRESHOLD;
double          alarmThreshold = DEFAULT_ALARM_THRESHOLD;
long            formatDisplay = CURRANCY_FORMAT_DOT;
long            formatSpeech = CURRANCY_FORMAT_DOT;

NSString* const autoStartupSpeechKey =      @"Auto Startup Speech";
NSString* const skipSpeechUnchangedKey =    @"Skip Speech Unchanged";
NSString* const sortSubPanelKey =           @"Sort Sub Panel Items";
NSString* const showRelativeDateKey =       @"Show Relative Date";
NSString* const showSubPanelKey =           @"Show Sub Panel";
NSString* const lockSubPanelKey =           @"Lock Sub Panel";
NSString* const currancyRatesListKey =      @"Currancy Rates List";
NSString* const speechIntervalKey =         @"Speech Interval";
NSString* const speechVoiceKey =            @"Speech Voice";
NSString* const speechSpeedKey =            @"Speech Speed";
NSString* const speechVolumeKey =           @"Speech Volume";
NSString* const speechRepeatKey =           @"Speech Repeat";
NSString* const serverSelectionKey =        @"Server Selection";
NSString* const digitThresholdKey =         @"Digit Threshold";
NSString* const alarmThresholdKey =         @"Alarm Threshold";
NSString* const formatSpeechKey =           @"Format Speech";
NSString* const formatDisplayKey =          @"Format Display";

@implementation AppDelegate

//@synthesize window = _window;
@synthesize mainWindow;
@synthesize currencyRates;
@synthesize updating;
@synthesize playing;
@synthesize iPanel;
@synthesize webConnection;
@synthesize volumeSlider;
@synthesize tableView;
@synthesize dateFormatter;

- (id)init
{
    self = [super init];
    if (self) {
        playIndex = 0;
        playing = NO;
        suspending = NO;
        updating = NO;
        speechSynth = [[NSSpeechSynthesizer alloc] initWithVoice:nil];
        [speechSynth setDelegate:self];
        voiceList = [[NSSpeechSynthesizer availableVoices] retain];
        webConnection = [[webAccess alloc] init];
        currencyRates = [[NSMutableArray alloc] init];
        [self loadCurrencyRates];
        intervalTimer = nil;
        iPanel = [[infoPanel alloc] init];
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(actionTerminate:)
                   name: NSApplicationWillTerminateNotification
                 object:syntheTickerDelegate];
        /*
         [nc addObserver:self selector:@selector(actionSleep:)
         name: NSWorkspaceWillSleepNotification
         object:syntheTickerDelegate];
         */
    }
    return self;
}

- (void)dealloc
{
    if (speechSynth) {
        [speechSynth release];
    }
    if (webConnection) {
        [webConnection release];
    }
    if (iPanel != nil) {
        [iPanel stopSpeech:self];
        [iPanel release];
    }
    [super dealloc];
}

+ (void)initialize {
    NSLog(@"initialize");
    NSString* lang = NSLocalizedString(@"LANG",@"English");
    NSMutableDictionary	*defaultValues = [NSMutableDictionary dictionary];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:autoStartupSpeechKey];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:skipSpeechUnchangedKey];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:sortSubPanelKey];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:showRelativeDateKey];
    [defaultValues setObject:[NSNumber numberWithBool:NO] forKey:showSubPanelKey];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:lockSubPanelKey];
    [defaultValues setObject:[NSNumber numberWithDouble:DEFAULT_DIGIT_THRESHOLD] forKey:digitThresholdKey];
    [defaultValues setObject:[NSNumber numberWithDouble:DEFAULT_ALARM_THRESHOLD] forKey:alarmThresholdKey];
    [defaultValues setObject:[NSNumber numberWithDouble:DEFAULT_SPEECH_SPEED] forKey:speechSpeedKey];
    [defaultValues setObject:[NSNumber numberWithDouble:DEFAULT_SPEECH_VOLUME] forKey:speechVolumeKey];
    [defaultValues setObject:[NSNumber numberWithInt:DEFAULT_SPEECH_INTERVAL] forKey:speechIntervalKey];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:speechRepeatKey];
    if ([lang isEqualToString:@"German"] || [lang isEqualToString:@"French"] ||
        [lang isEqualToString:@"Italian"] || [lang isEqualToString:@"Spanish"] ||
        [lang isEqualToString:@"Portuguese"]) {
        [defaultValues setObject:[NSNumber numberWithInt:CURRANCY_FORMAT_COMMA] forKey:formatSpeechKey];
        [defaultValues setObject:[NSNumber numberWithInt:CURRANCY_FORMAT_COMMA] forKey:formatDisplayKey];
    } else {
        [defaultValues setObject:[NSNumber numberWithInt:CURRANCY_FORMAT_DOT] forKey:formatSpeechKey];
        [defaultValues setObject:[NSNumber numberWithInt:CURRANCY_FORMAT_DOT] forKey:formatDisplayKey];
    }    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}

/*
 - (void)actionClose:(NSNotification *)notification {
 NSLog(@"actionClose");
 }
 */

- (void)actionTerminate:(NSNotification *)notification {
    NSLog(@"actionTerminate: %@", [notification object]);
    willTerminate = YES;
}

- (void)actionSleep:(NSNotification *)notification {
    NSLog(@"actionSleep: %@", [notification object]);
    [self stopSpeech];
    [iPanel stopSpeech:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    NSLog(@"applicationDidFinishLaunching");
    syntheTickerDelegate = self;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self setCurrencyList];
    int cnt = 0;
    for (CurrencyRate *item in currencyRates) {
        cnt++;
        [item setIndex:cnt];
        [self startObservingCurrencyRate:item];
        [iPanel setItem:[item targetCode]:[item againstCode]:[item doubleRate]:[item prevClose]];
    }
    [arrayController rearrangeObjects];
    [tableView reloadData];
    [tableView deselectAll:self];
    autoStartupSpeech = [defaults boolForKey:autoStartupSpeechKey];
    skipSpeechUnchanged = [defaults boolForKey:skipSpeechUnchangedKey];
    showRelativeDate = [defaults boolForKey:showRelativeDateKey];
    sortSubPanel = [defaults boolForKey:sortSubPanelKey];
    showSubPanel = [defaults boolForKey:showSubPanelKey];
    lockSubPanel = [defaults boolForKey:lockSubPanelKey];
    serverSelection = [defaults objectForKey:serverSelectionKey];
    NSLog(@"serverSelection = %@", serverSelection);
    [webConnection setServerSelection:serverSelection];
    digitThreshold = [defaults doubleForKey:digitThresholdKey];
    alarmThreshold = [defaults doubleForKey:alarmThresholdKey];
    formatSpeech = [defaults integerForKey:formatSpeechKey];
    formatDisplay = [defaults integerForKey:formatDisplayKey];
    double speechSpeed = [defaults doubleForKey:speechSpeedKey];
    if (speechSpeed >= [voiceSlider minValue] && speechSpeed <= [voiceSlider maxValue]) {
        [voiceSlider setDoubleValue:speechSpeed];
    }
    double speechVolume = [defaults doubleForKey:speechVolumeKey];
    if (speechSpeed >= [volumeSlider minValue] && speechVolume <= [volumeSlider maxValue]) {
        [volumeSlider setDoubleValue:speechVolume];
        if (speechVolume == 0) {
            NSImage *img = [NSImage imageNamed:@"SoundOff.tiff"];
            if (img) {
                [imageSound setImage:img];
            }
        }
    }
    long interval = [defaults integerForKey:speechIntervalKey];
    if (interval > 0) {
        [intervalStepper setIntegerValue:interval];
    }
    NSString* strInterval = [[[NSString alloc] initWithFormat:@"%d min ", [intervalStepper intValue]] autorelease];
    [intervalTextField setStringValue:strInterval];
    repeat = [defaults boolForKey:speechRepeatKey];
    if (repeat == NO) {
        [intervalTextField setEnabled:NO];
        [intervalStepper setEnabled:NO];
        [buttonRepeat setTitle:@"Once"];
        [buttonRepeat setState:YES];
    } else {
        [intervalTextField setEnabled:YES];
        [intervalStepper setEnabled:YES];
        [buttonRepeat setTitle:@"Repeat"];
        [buttonRepeat setState:NO];
    }
    [self localizeView];
    
    if (autoStartupSpeech) {
        NSLog(@"autoStartup: YES: %d",autoStartupSpeech);
    } else {
        NSLog(@"autoStartup: NO: %d",autoStartupSpeech);
    }
    if (skipSpeechUnchanged) {
        NSLog(@"skipSpeechUnchanged: YES: %d",skipSpeechUnchanged);
    } else {
        NSLog(@"skipSpeechUnchanged: NO: %d",skipSpeechUnchanged);
    }
    NSLog(@"digitThreshold: %f",digitThreshold);
    NSLog(@"alarmThreshold: %f",alarmThreshold);
    NSLog(@"speechSpeed: %f",speechSpeed);
    NSLog(@"speechInterval: %lu", interval);
    
    NSString* voice = [defaults objectForKey:speechVoiceKey];
    if (voice) {
        [speechSynth setVoice:voice];
    }
    speechVoice = [speechSynth voice];
    speechVoiceLocaleIdentifier = [self voiceLocaleIdentifier:speechVoice];
    for (NSString* voice in voiceList) {
        NSDictionary* dict = [NSSpeechSynthesizer attributesForVoice:voice];
        NSString* voiceName = [dict objectForKey:NSVoiceName];
        if (voiceName) {
            [voiceComboBox addItemWithObjectValue:voiceName];
            if ([[speechSynth voice] isEqualToString:voice] == YES) {
                speechVoice = voice;
                speechVoiceLocaleIdentifier = [self voiceLocaleIdentifier:voice];
                //[voiceComboBox setTitleWithMnemonic:voiceName];
                [voiceComboBox selectItemWithObjectValue:voiceName];
            }
        }
    }
    if (autoStartupSpeech == YES) {
        usleep(500000);
        [self playButton:self];
    }
    [self buildVoiceMenu];
    [self buildServerMenu];
    [tableView setDoubleAction:@selector(showWebSite:)];
    [iPanel sortItems];
    if (showSubPanel == YES) {
        [iPanel showWindow:self];
        [iPanel rearrangePanel];
        [[iPanel infoPanel] setFloatingPanel:lockSubPanel];
        NSImage *img;
        if (lockSubPanel == YES) {
            img = [NSImage imageNamed:@"NSLockLockedTemplate"];
        } else {
            img = [NSImage imageNamed:@"NSLockUnlockedTemplate"];
        }
        if (img) {
            [[iPanel lockButton] setImage:img];
        }
        NSLog(@"isFloating :%d",[[iPanel infoPanel] isFloatingPanel]);
        [iPanel rearrangePanel];
    }
    [[syntheTickerDelegate dateFormatter] setDoesRelativeDateFormatting:showRelativeDate];
}

- (void)applicationWillBecomeActive:(NSNotification *)aNotification
{
    NSLog(@"applicationWillBecomeActive");
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
    NSLog(@"applicationDidBecomeActive");
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication*)sender
{
    NSLog(@"applicationShouldOpenUntitledFile");
    [self showWindow:self];
    return NO;
}

- (void)menuWillOpen:(NSMenu *)menu
{
    NSLog(@"menuWillOpen");
}

- (BOOL)validateMenuItem:(NSMenuItem *)item {
    NSLog(@"validateMenuItem: %@", item);
    SEL action = [item action];
    if (action == @selector(playStart:)) {
        if (playing == YES) {
            return NO;
        }
    } else if (action == @selector(playStop:)) {
        if (playing == NO) {
            return NO;
        }
    } else if (action == @selector(showWindow:)) {
        if ([mainWindow viewsNeedDisplay] == NO) {
            return NO;
        }
    } else if (action == @selector(startButton:)) {
        long row = [tableView selectedRow];
        if (row == -1) {
            return NO;
        }
        CurrencyRate *item = [currencyRates objectAtIndex:row];    
        if ([[item targetCode] isEqualToString:@"---"] == YES ||
            [[item targetCode] length] != 3) {
            return NO;
        }
        if ([[item againstCode] isEqualToString:@"---"] == YES ||
            [[item againstCode] length] != 3) {
            return NO;
        }
        if ([[item targetCode] isEqualToString:[item againstCode]] == YES) {
            return NO;
        }
    } else if (action == @selector(selectTargetMenu:)) {
        [self setTargetMenu];
        long row = [tableView selectedRow];
        if (row == -1) {
            return NO;
        }
    } else if (action == @selector(selectAgainstMenu:)) {
        [self setAgainstMenu];
        long row = [tableView selectedRow];
        if (row == -1) {
            return NO;
        }
    } else if (action == @selector(readPanel:)) {
        if ([iPanel speeching] == YES) {
            return NO;
        }
    }
    return YES;
}

- (void)buildVoiceMenu
{
    static bool bFirst = YES;
    if (bFirst == NO) {
        return;
    }
    for (int i = 0; i < [voiceList count]; i++) {
        NSString *voiceItem;
        NSString *voiceId = [self voiceLocaleIdentifier:[voiceList objectAtIndex:i]];
        if (voiceId && [voiceId isEqualToString:@"en_US"] == NO) {
            voiceItem = [[NSString alloc] initWithFormat:@"%@ (%@)",[self voiceName:i],voiceId];
        } else {
            voiceItem = [[NSString alloc] initWithFormat:@"%@",[self voiceName:i]];
        }
        NSLog(@"voiceItem: %@",voiceItem);
        NSMenuItem* subMenu = [[NSMenuItem alloc] initWithTitle:voiceItem action:@selector(selectVoiceMenu:) keyEquivalent:@""];
        [[menuVoice submenu] insertItem:subMenu atIndex:i];
        NSString* voice = [voiceList objectAtIndex:i];
        if (voice && [voice isEqualToString:speechVoice] == YES) {
            [subMenu setState:YES];
        }
        [voiceItem release];
        [subMenu release];
    }
    bFirst = NO;
}

- (void)setVoiceMenu
{
    NSDictionary* dict = [NSSpeechSynthesizer attributesForVoice:speechVoice];
    NSString* voice = [dict objectForKey:NSVoiceName];
    for (NSMenuItem* subMenu in [[menuVoice submenu] itemArray]) {
        if ([[subMenu title] isEqualToString:voice] == YES ||
            [[subMenu title] hasPrefix:[[[NSString alloc] initWithFormat:@"%@ ",voice] autorelease]] == YES) {
            [subMenu setState:YES];
        } else {
            [subMenu setState:NO];
        }
    }
}

- (void)setTargetMenu
{
    long row = [tableView selectedRow];
    if (row == -1) {
        for (NSMenuItem* subMenu in [[menuTarget submenu] itemArray]) {
            [subMenu setState:NO];
        }
        return;
    }
    CurrencyRate *item = [currencyRates objectAtIndex:row];
    if (item == nil) {
        return;
    }
    for (NSMenuItem* subMenu in [[menuTarget submenu] itemArray]) {
        if ([[subMenu title] isEqualToString:[item targetCode]] == YES) {
            [subMenu setState:YES];
        } else {
            [subMenu setState:NO];
        }
    }
}

- (void)setAgainstMenu
{
    long row = [tableView selectedRow];
    if (row == -1) {
        for (NSMenuItem* subMenu in [[menuAgainst submenu] itemArray]) {
            [subMenu setState:NO];
        }
        return;
    }
    CurrencyRate *item = [currencyRates objectAtIndex:row];
    if (item == nil) {
        return;
    }
    for (NSMenuItem* subMenu in [[menuAgainst submenu] itemArray]) {
        if ([[subMenu title] isEqualToString:[item againstCode]] == YES) {
            [subMenu setState:YES];
        } else {
            [subMenu setState:NO];
        }
    }
}

- (void)buildServerMenu
{
    static bool bFirst = YES;
    if (bFirst == NO) {
        return;
    }
    NSMenuItem* subMenu;
    subMenu = [[NSMenuItem alloc] initWithTitle:SERVER_NAME_GOOGLE action:@selector(selectServerMenu:) keyEquivalent:@""];
    [[menuServer submenu] insertItem:subMenu atIndex:0];
    [subMenu release];
    //subMenu = [[NSMenuItem alloc] initWithTitle:SERVER_NAME_YAHOO_AU action:@selector(selectServerMenu:) keyEquivalent:@""];
    //[[menuServer submenu] insertItem:subMenu atIndex:1];
    //[subMenu release];
    //subMenu = [[NSMenuItem alloc] initWithTitle:SERVER_NAME_YAHOO_BR action:@selector(selectServerMenu:) keyEquivalent:@""];
    //[[menuServer submenu] insertItem:subMenu atIndex:2];
    //[subMenu release];
    //subMenu = [[NSMenuItem alloc] initWithTitle:SERVER_NAME_YAHOO_DE action:@selector(selectServerMenu:) keyEquivalent:@""];
    //[[menuServer submenu] insertItem:subMenu atIndex:3];
    //[subMenu release];
    //subMenu = [[NSMenuItem alloc] initWithTitle:SERVER_NAME_YAHOO_ES action:@selector(selectServerMenu:) keyEquivalent:@""];
    //[[menuServer submenu] insertItem:subMenu atIndex:4];
    //[subMenu release];
    //subMenu = [[NSMenuItem alloc] initWithTitle:SERVER_NAME_YAHOO_FR action:@selector(selectServerMenu:) keyEquivalent:@""];
    //[[menuServer submenu] insertItem:subMenu atIndex:5];
    //[subMenu release];
    //subMenu = [[NSMenuItem alloc] initWithTitle:SERVER_NAME_YAHOO_IT action:@selector(selectServerMenu:) keyEquivalent:@""];
    //[[menuServer submenu] insertItem:subMenu atIndex:6];
    //[subMenu release];
    subMenu = [[NSMenuItem alloc] initWithTitle:SERVER_NAME_YAHOO_JP action:@selector(selectServerMenu:) keyEquivalent:@""];
    [[menuServer submenu] insertItem:subMenu atIndex:1];
    [subMenu release];
    //subMenu = [[NSMenuItem alloc] initWithTitle:SERVER_NAME_YAHOO_SG action:@selector(selectServerMenu:) keyEquivalent:@""];
    //[[menuServer submenu] insertItem:subMenu atIndex:8];
    //[subMenu release];
    //subMenu = [[NSMenuItem alloc] initWithTitle:SERVER_NAME_YAHOO_UK action:@selector(selectServerMenu:) keyEquivalent:@""];
    //[[menuServer submenu] insertItem:subMenu atIndex:9];
    //[subMenu release];
    //subMenu = [[NSMenuItem alloc] initWithTitle:SERVER_NAME_YAHOO_US action:@selector(selectServerMenu:) keyEquivalent:@""];
    //[[menuServer submenu] insertItem:subMenu atIndex:10];
    //[subMenu release];
    subMenu = [[NSMenuItem alloc] initWithTitle:SERVER_NAME_EXCHANGE_RATES action:@selector(selectServerMenu:) keyEquivalent:@""];
    [[menuServer submenu] insertItem:subMenu atIndex:2];
    [subMenu release];
    [self setServerMenu];
    bFirst = NO;
}

- (void)setServerMenu
{
    NSLog(@"setServerMenu: %@",serverSelection);
    for (NSMenuItem* subMenu in [[menuServer submenu] itemArray]) {
        if ([[subMenu title] isEqualToString:serverSelection] == YES) {
            [subMenu setState:YES];
        } else {
            [subMenu setState:NO];
        }
    }
}

- (void)refreshPanel
{
    [iPanel initData];
    for (CurrencyRate* item in currencyRates) {
        [iPanel setItem:[item targetCode]:[item againstCode]:[item doubleRate]:[item prevClose]];
        [iPanel rearrangePanel];
    }
}

- (void)startSpeech:(NSString*)text
{
    [self stopSpeech];
    [speechSynth setVoice:speechVoice];
    [speechSynth setRate:[voiceSlider doubleValue]];
    [speechSynth setVolume:[volumeSlider doubleValue]];
    NSLog(@"startSpeech: rate=%f, volume=%f", [speechSynth rate], [speechSynth volume]);
    [speechSynth startSpeakingString:text];
}

- (void)stopSpeech
{
    if ([speechSynth isSpeaking]) {
        [speechSynth stopSpeaking];
    }
}

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender
        didFinishSpeaking:(BOOL)complete
{
    NSLog(@"didFinishSpeaking: complete = %d", complete);
    if (playing == NO) {
        return;
    }
    if ([speechSynth isSpeaking] == YES) {
        return;
    }
    if ([webConnection cnnecting] == YES) {
        NSLog(@"didFinishSpeaking: connecting = %d", [webConnection cnnecting]);
        return;
    }
    playIndex++;
    int index = [self getNextIndex:playIndex];
    if (index == -1) {
        if (updating == YES) {
            [self playButton:self];
            NSLog(@"updating is finised");
            updating = NO;
            [tableView deselectAll:self];
            [tableView scrollRowToVisible:0];
            [[iPanel infoTableView] deselectAll:self];
            return;
        }
        if (repeat == NO) {
            [self playButton:self];
            [tableView deselectAll:self];
            [tableView scrollRowToVisible:0];
            [[iPanel infoTableView] deselectAll:self];
            return;
        }
        suspending = YES;
        [tableView deselectAll:self];
        [tableView scrollRowToVisible:0];
        [[iPanel infoTableView] deselectAll:self];
        return;
    }
    playIndex = index;
    CurrencyRate* item = [currencyRates objectAtIndex:playIndex];
    if (item == nil) {
        [self playButton:self];
        return;
    }
    NSString *code = [[NSString alloc] initWithFormat: @"%@%@", [item targetCode], [item againstCode]];
    [webConnection setTargetItem: item];
    [self enableRequest:NO];
    NSIndexSet* ixset = [NSIndexSet indexSetWithIndex:playIndex];
    [tableView selectRowIndexes:ixset byExtendingSelection:NO];
    [tableView scrollRowToVisible:index];
    [webConnection setRetrying:NO];
    [webConnection fetchPrice:code];
    [code release];
}

- (NSString*)voiceName:(int)index
{
    NSString* voice = [voiceList objectAtIndex:index];
    NSDictionary* dict = [NSSpeechSynthesizer attributesForVoice:voice];
    return [dict objectForKey:NSVoiceName];
}

- (NSString*)voiceLocaleIdentifier:(NSString*)voice
{
    NSDictionary* dict = [NSSpeechSynthesizer attributesForVoice:voice];
    return [dict objectForKey:NSVoiceLocaleIdentifier];
}

- (IBAction)startButton:(id)sender {
    long row = [tableView selectedRow];
    if (row == -1) {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
                                         defaultButton:NSLocalizedString(@"OK",@"Ok")
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"ITEM_NOTSELECTED", @"Pair of currency isn't selected.")];
        [alert beginSheetModalForWindow:[syntheTickerDelegate mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
        return;
    }
    CurrencyRate *item = [currencyRates objectAtIndex:row];    
    if ([[item targetCode] isEqualToString:@"---"] == YES || [[item targetCode] length] != 3 ||
        [[item againstCode] isEqualToString:@"---"] == YES || [[item againstCode] length] != 3 ||
        [[item targetCode] isEqualToString:[item againstCode]] == YES) {
        NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
                                         defaultButton:NSLocalizedString(@"OK",@"Ok")
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:NSLocalizedString(@"CURRENCY_NOTSELECTED", @"Currancy code isn't selected crorrectly.")];
        [alert beginSheetModalForWindow:[syntheTickerDelegate mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
        return;
    }
    if (playing == YES) {
        [self playButton:self];
    }
    NSString *code = [[NSString alloc] initWithFormat: @"%@%@", [item targetCode], [item againstCode]];
    [webConnection setTargetItem: item];
    [self enableRequest:NO];
    [webConnection setRetrying:NO];
    [webConnection fetchPrice:code];
    [code release];
}

- (IBAction)playButton:(id)sender {
    if (playing == YES) {
        NSImage *template = [NSImage imageNamed:@"NSGoRightTemplate"];
        if (template == nil) {
            NSBeep();
            return;
        }
        [playButton setImage:template];
        [playLable setStringValue:@"Start"];
        [speechSynth stopSpeaking];
        if (intervalTimer) {
            [intervalTimer invalidate];
            [intervalTimer release];
            intervalTimer = nil;
        }
        updating = NO;
        playing = NO;
        [tableView deselectAll:self];
        [[iPanel infoTableView] deselectAll:self];
    } else {
        if ([webConnection cnnecting] == YES) {
            NSBeep();
            return;
        }
        playIndex = [self getNextIndex:0];
        if (playIndex == -1) {
            NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
                                             defaultButton:NSLocalizedString(@"OK",@"Ok")
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:NSLocalizedString(@"ITEM_NOTSELECTED", @"pair of currency isn't selected")];
            [alert beginSheetModalForWindow:[syntheTickerDelegate mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
            return;
        }
        CurrencyRate* item = [currencyRates objectAtIndex:playIndex];
        if (item == nil) {
            NSBeep();
            return;
        }
        NSImage *template = [NSImage imageNamed:@"NSStopProgressTemplate"];
        if (template == nil) {
            NSBeep();
            return;
        }
        intervalTimer = [[NSTimer scheduledTimerWithTimeInterval:60
                                                          target:self
                                                        selector:@selector(checkPlayTimer:)
                                                        userInfo:nil
                                                         repeats:YES] retain];
        if (intervalTimer == nil) {
            NSBeep();
            return;
        }
        [speechSynth stopSpeaking];
        [playButton setImage:template];
        [playLable setStringValue:@"Stop"];
        [iPanel stopSpeech:self];
        NSLog(@"start play :%d", playIndex);
        NSString *code = [[NSString alloc] initWithFormat: @"%@%@", [item targetCode], [item againstCode]];
        [webConnection setTargetItem: item];
        [self enableRequest:NO];
        NSIndexSet* ixset = [NSIndexSet indexSetWithIndex:playIndex];
        [tableView selectRowIndexes:ixset byExtendingSelection:NO];
        [webConnection setRetrying:NO];
        [webConnection fetchPrice:code];
        [code release];
        countDown = [intervalStepper intValue];
        playing = YES;
    }
}

- (IBAction)playStart:(id)sender
{
    NSSound *sound = [NSSound soundNamed:@"Tink"];
    [sound play];
    if (playing == NO) {
        updating = NO;
        [self playButton:self];
    }
}

- (IBAction)playStop:(id)sender
{
    NSSound *sound = [NSSound soundNamed:@"Tink"];
    [sound play];
    if (playing == YES) {
        [self playButton:self];
    }
}

- (IBAction)updateStart:(id)sender
{
    NSSound *sound = [NSSound soundNamed:@"Submarine"];
    [sound play];
    if (playing == YES) {
        // play stop
        [self playButton:self];
    }
    updating = YES;
    [self playButton:self];
}

- (IBAction)startVerify:(id)sender
{
    NSSound *sound = [NSSound soundNamed:@"Submarine"];
    [sound play];
    [self startButton:self];
}

- (void)checkPlayTimer:(NSTimer*) timer {
    NSLog(@"checkPlayTimer");
    if (countDown > 0) {
        countDown--;
    }
    if (playing == NO) {
        return;
    }
    if (countDown <= 0 && suspending == YES) {
        playIndex= [self getNextIndex:0];
        if (playIndex == -1) {
            return;
        }
        CurrencyRate* item = [currencyRates objectAtIndex:playIndex];
        if (item == nil) {
            return;
        }
        NSSound *sound = [NSSound soundNamed:@"Tink"];
        [sound play];
        usleep(300000);
        NSString *code = [[NSString alloc] initWithFormat: @"%@%@", [item targetCode], [item againstCode]];
        [webConnection setTargetItem: item];
        [self enableRequest:NO];
        NSIndexSet* ixset = [NSIndexSet indexSetWithIndex:playIndex];
        [tableView selectRowIndexes:ixset byExtendingSelection:NO];
        [webConnection setRetrying:NO];
        [webConnection fetchPrice:code];
        [code release];
        suspending = NO;
        countDown = [intervalStepper intValue];
    }
}

- (void)enableRequest:(bool)available
{
    [startButton setEnabled:available];
    [playButton setEnabled:available];
    [updateButton setEnabled:available];
    [[iPanel refreshButton] setEnabled:available];
}

- (int)getNextIndex:(int)index
{
    if (index >= [currencyRates count]) {
        return -1;
    }
    for (int i = index; i < [currencyRates count]; i++) {
        CurrencyRate* item = [currencyRates objectAtIndex:i];
        if ([[item targetCode] isEqualToString:@"---"] == YES ||
            [[item targetCode] length] != 3) {
            continue;
        }
        if ([[item againstCode] isEqualToString:@"---"] == YES ||
            [[item againstCode] length] != 3) {
            continue;
        }
        if ([[item targetCode] isEqualToString:[item againstCode]] == YES) {
            continue;
        }
        if ([item enable] == YES) {
            return i;
        }
    }
    return -1;
}

- (IBAction)showWebSite:(id)sender
{
    NSLog(@"showWebSite");
    NSString *urlString = nil;
    long row = [tableView selectedRow];
    if (row == -1) {
        if (serverSelection) {
            if ([serverSelection isEqualToString:SERVER_NAME_YAHOO_US] == YES) {
                urlString = FORMAT_YAHOO_US_HOME;        
            } else if ([serverSelection isEqualToString:SERVER_NAME_YAHOO_JP] == YES) {
                urlString = FORMAT_YAHOO_JP_HOME;
            } else if ([serverSelection isEqualToString:SERVER_NAME_YAHOO_UK] == YES) {
                urlString = FORMAT_YAHOO_UK_HOME;
            } else if ([serverSelection isEqualToString:SERVER_NAME_YAHOO_DE] == YES) {
                urlString = FORMAT_YAHOO_DE_HOME;
            } else if ([serverSelection isEqualToString:SERVER_NAME_YAHOO_FR] == YES) {
                urlString = FORMAT_YAHOO_FR_HOME;
            } else if ([serverSelection isEqualToString:SERVER_NAME_YAHOO_IT] == YES) {
                urlString = FORMAT_YAHOO_IT_HOME;
            } else if ([serverSelection isEqualToString:SERVER_NAME_YAHOO_ES] == YES) {
                urlString = FORMAT_YAHOO_ES_HOME;
            } else if ([serverSelection isEqualToString:SERVER_NAME_YAHOO_BR] == YES) {
                urlString = FORMAT_YAHOO_BR_HOME;
            } else if ([serverSelection isEqualToString:SERVER_NAME_YAHOO_SG] == YES) {
                urlString = FORMAT_YAHOO_SG_HOME;
            } else if ([serverSelection isEqualToString:SERVER_NAME_YAHOO_AU] == YES) {
                urlString = FORMAT_YAHOO_AU_HOME;
            } else if ([serverSelection isEqualToString:SERVER_NAME_GOOGLE] == YES) {
                urlString = FORMAT_GOOGLE_HOME;
            } else if ([serverSelection isEqualToString:SERVER_NAME_EXCHANGE_RATES] == YES) {
                urlString = FORMAT_EXCHANGE_RATES_HOME;
            }
        } else {
            urlString = FORMAT_YAHOO_US_HOME;        
        }
        NSURL* url = [NSURL URLWithString:urlString];
        NSWorkspace *workspace = [[[NSWorkspace alloc] init] autorelease];
        [workspace openURL:url];
        [urlString release];
        return;
    }
    CurrencyRate *item = [currencyRates objectAtIndex:row];    
    if ([[item targetCode] isEqualToString:@"---"] == YES ||
        [[item targetCode] length] != 3) {
        NSBeep();
        return;
    }
    if ([[item againstCode] isEqualToString:@"---"] == YES ||
        [[item againstCode] length] != 3) {
        NSBeep();
        return;
    }
    if ([[item targetCode] isEqualToString:[item againstCode]] == YES) {
        NSBeep();
        return;
    }
    NSString *code = [[NSString alloc] initWithFormat: @"%@%@", [item targetCode], [item againstCode]];
    if (serverSelection) {
        if ([serverSelection isEqualToString:SERVER_NAME_YAHOO_US] == YES) {
            urlString = [[NSString alloc] initWithFormat:FORMAT_YAHOO_US_FX,code];        
        } else if ([serverSelection isEqualToString:SERVER_NAME_YAHOO_JP] == YES) {
            urlString = [[NSString alloc] initWithFormat:FORMAT_YAHOO_JP_FX,code];
        } else if ([serverSelection isEqualToString:SERVER_NAME_YAHOO_UK] == YES) {
            urlString = [[NSString alloc] initWithFormat:FORMAT_YAHOO_UK_FX,code];
        } else if ([serverSelection isEqualToString:SERVER_NAME_YAHOO_DE] == YES) {
            urlString = [[NSString alloc] initWithFormat:FORMAT_YAHOO_DE_FX,code];
        } else if ([serverSelection isEqualToString:SERVER_NAME_YAHOO_FR] == YES) {
            urlString = [[NSString alloc] initWithFormat:FORMAT_YAHOO_FR_FX,code];
        } else if ([serverSelection isEqualToString:SERVER_NAME_YAHOO_IT] == YES) {
            urlString = [[NSString alloc] initWithFormat:FORMAT_YAHOO_IT_FX,code];
        } else if ([serverSelection isEqualToString:SERVER_NAME_YAHOO_ES] == YES) {
            urlString = [[NSString alloc] initWithFormat:FORMAT_YAHOO_ES_FX,code];
        } else if ([serverSelection isEqualToString:SERVER_NAME_YAHOO_BR] == YES) {
            urlString = [[NSString alloc] initWithFormat:FORMAT_YAHOO_BR_FX,code];
        } else if ([serverSelection isEqualToString:SERVER_NAME_YAHOO_SG] == YES) {
            urlString = [[NSString alloc] initWithFormat:FORMAT_YAHOO_SG_FX,code];
        } else if ([serverSelection isEqualToString:SERVER_NAME_YAHOO_AU] == YES) {
            urlString = [[NSString alloc] initWithFormat:FORMAT_YAHOO_AU_FX,code];
        } else if ([serverSelection isEqualToString:SERVER_NAME_GOOGLE] == YES) {
            urlString = [[NSString alloc] initWithFormat:FORMAT_GOOGLE_FINANCE,code];
        } else if ([serverSelection isEqualToString:SERVER_NAME_EXCHANGE_RATES] == YES) {
            urlString = [[NSString alloc] initWithFormat:FORMAT_EXCHANGE_RATES,[code substringToIndex:3],[code substringFromIndex:3]];
        }
    }
    if (urlString == nil) {
        urlString = [[NSString alloc] initWithFormat:FORMAT_YAHOO_US_FX,code];        
    }
    [code release];
    NSURL* url = [NSURL URLWithString:urlString];
    NSWorkspace *workspace = [[[NSWorkspace alloc] init] autorelease];
    [workspace openURL:url];
    [urlString release];
}

- (IBAction)showWindow:(id)sender {
    NSLog(@"showWindow");
    [mainWindow makeKeyAndOrderFront:nil];
}

- (IBAction)seletcVoice:(id)sender {
    NSLog(@"selectVoice: %@", [voiceComboBox stringValue]);
    for (NSString* voice in voiceList) {
        NSDictionary* dict = [NSSpeechSynthesizer attributesForVoice:voice];
        NSString* voiceName = [dict objectForKey:NSVoiceName];
        if (voiceName && [voiceName isEqualToString:[voiceComboBox stringValue]]) {
            speechVoice = voice;
            speechVoiceLocaleIdentifier = [self voiceLocaleIdentifier:voice];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:voice forKey:speechVoiceKey ];
            NSLog(@"selectVoice: %@ %@", speechVoice, speechVoiceLocaleIdentifier);
        }
    }
    [self setVoiceMenu];
}

- (IBAction)changeVoiceSlider:(id)sender {
    NSLog(@"changeVoiceSlider: %f", [sender doubleValue]);
    [speechSynth setRate:[voiceSlider doubleValue]]; 
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setDouble:[voiceSlider doubleValue] forKey:speechSpeedKey];
}

- (IBAction)changeVolumeSlider:(id)sender {
    NSLog(@"changeVoiceSlider: %f", [sender doubleValue]);
    [speechSynth setVolume:[volumeSlider doubleValue]];
    NSImage *img;
    if ([volumeSlider doubleValue] == 0) {
        img = [NSImage imageNamed:@"SoundOff.tiff"];
    } else {
        img = [NSImage imageNamed:@"SoundOn.tiff"];
    }
    if (img) {
        [imageSound setImage:img];
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setDouble:[volumeSlider doubleValue] forKey:speechVolumeKey];
}

- (bool)volumeMuted
{
    if ([volumeSlider doubleValue] == 0) {
        return YES;
    }
    return NO;
}

- (IBAction)changeInterval:(id)sender {
    NSLog(@"changeInterval: %d", [sender intValue]);
    NSString* strInterval = [[[NSString alloc] initWithFormat:@"%d min ", [intervalStepper intValue]] autorelease];
    [intervalTextField setStringValue:strInterval];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:[intervalStepper intValue] forKey:speechIntervalKey];
    if (countDown > [intervalStepper intValue]) {
        countDown = [intervalStepper intValue];
    }
}

- (IBAction)selectVoiceMenu:(id)sender
{
    NSLog(@"selectVoiceMenu: %@", [sender title]);
    NSInteger num = [[menuVoice submenu] numberOfItems];
    for (int i = 0; i < num; i++) {
        NSMenuItem* item = [[menuVoice submenu] itemAtIndex:i];
        if ([[sender title] isEqualToString:[item title]] == YES) {
            speechVoice = [voiceList objectAtIndex:i];
            speechVoiceLocaleIdentifier = [self voiceLocaleIdentifier:speechVoice];
            if (speechVoice) {
                [item setState:YES];
                [voiceComboBox setStringValue:[self voiceName:i]];
            }
        } else {
            [item setState:NO];
        }
    }
    if (speechVoice) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject: speechVoice forKey:speechVoiceKey];
    }
}

- (IBAction)selectServerMenu:(id)sender
{
    NSLog(@"selectServerMenu: %@", [sender title]);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[sender title] forKey:serverSelectionKey];
    serverSelection = [defaults objectForKey:serverSelectionKey];
    [webConnection setServerSelection:serverSelection];
    NSLog(@"serverSelection = %@", serverSelection);
    if (preferenceContriller) {
        [[preferenceContriller serverComboBox] setStringValue:serverSelection];
    }
    [self setServerMenu];
}

- (IBAction)selectTargetMenu:(id)sender
{
    NSLog(@"selectTargetMenu: %@", [sender title]);
    long row = [tableView selectedRow];
    if (row == -1) {
        return;
    }
    CurrencyRate *item = [currencyRates objectAtIndex:row];
    if ([[item targetCode] isEqualToString:[sender title]] == YES) {
        return;
    }
    [item setTargetCode:[sender title]];
}

- (IBAction)selectAgainstMenu:(id)sender
{
    NSLog(@"selectAgainstMenu: %@", [sender title]);
    long row = [tableView selectedRow];
    if (row == -1) {
        return;
    }
    CurrencyRate *item = [currencyRates objectAtIndex:row];
    if ([[item againstCode] isEqualToString:[sender title]] == YES) {
        return;
    }
    [item setAgainstCode:[sender title]];
}

- (IBAction)showPanel:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:showSubPanelKey];
    showSubPanel = YES;
    [iPanel showWindow:sender];
    [iPanel rearrangePanel];
    [[iPanel infoPanel] setFloatingPanel:lockSubPanel];
    NSLog(@"isFloating :%d",[[iPanel infoPanel] isFloatingPanel]);
}

- (IBAction)readPanel:(id)sender {
    [iPanel startSpeech:self];
}

- (IBAction)copyPanel:(id)sender {
    NSMutableString*    clip = [[NSMutableString alloc] init];
    [clip setString:@""];
    NSString* line;
    for (infoItem* item in [iPanel items]) {
        NSString    *strPrice = [[NSString alloc] initWithFormat:@"%0.4f",[item price]];
        NSString    *strClose = [[NSString alloc] initWithFormat:@"%0.4f",[item prevClose]];
        NSString    *strDiffer = [[NSString alloc] initWithFormat:@"%0.4f",fabs([item differ])];
        NSString    *strRaise = [[NSString alloc] initWithFormat:@"%0.2f",fabs([item raise])*100];
        if (formatDisplay == CURRANCY_FORMAT_COMMA) {
            strPrice = [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","];
            strClose = [strClose stringByReplacingOccurrencesOfString:@"." withString:@","];
            strDiffer = [strDiffer stringByReplacingOccurrencesOfString:@"." withString:@","];
            strRaise = [strRaise stringByReplacingOccurrencesOfString:@"." withString:@","];
        }
        if ([item differ] >= 0) {
            line = [NSString stringWithFormat:@"%ld\t%@\t%@\t%@\t+%@\t+%@%@\r\n",
                    [item index], [item name], strClose, strPrice, strDiffer, strRaise, @"%"];
        } else {
            line = [NSString stringWithFormat:@"%ld\t%@\t%@\t%@\t-%@\t-%@%@\r\n",
                    [item index], [item name], strClose, strPrice, strDiffer, strRaise, @"%"];
        }
        NSLog(@"%@",line);
        [clip appendString:line];
    }
    NSPasteboard* pb = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    [pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
    [pb setString:clip forType:NSStringPboardType];
    [clip release];
}

- (IBAction)setRepeat:(id)sender {
    NSLog(@"setRepeat");
    if (repeat == YES) {
        repeat = NO;
        [intervalTextField setEnabled:NO];
        [intervalStepper setEnabled:NO];
        [buttonRepeat setTitle:@"Once"];
    } else {
        repeat = YES;
        [intervalTextField setEnabled:YES];
        [intervalStepper setEnabled:YES];
        [buttonRepeat setTitle:@"Repeat"];
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:repeat forKey:speechRepeatKey];
}

- (IBAction)showPreferencePanel:(id)sender
{
    NSLog(@"showPreferencePanel");
    if (preferenceContriller) {
        [preferenceContriller release];
    }
    preferenceContriller = [[PreferenceController alloc] init];
    [preferenceContriller showWindow:self];
}

#pragma mark Currency List

- (void)initCurrencyRates
{
    if (currencyRates == nil) {
        currencyRates = [[NSMutableArray alloc] init];
    } else {
        [currencyRates removeAllObjects];
    }
    for (int i = 0; i < NUMBER_OF_RATES; i++) {
        CurrencyRate *rate = [[CurrencyRate alloc] init];
        if (rate) {
            switch (i) {
                case 0:
                    [rate setTargetCode:@"USD"];
                    [rate setAgainstCode:@"JPY"];
                    [rate setEnable:YES];
                    break;
                case 1:
                    [rate setTargetCode:@"EUR"];
                    [rate setAgainstCode:@"JPY"];
                    [rate setEnable:YES];
                    break;
                case 2:
                    [rate setTargetCode:@"EUR"];
                    [rate setAgainstCode:@"USD"];
                    [rate setEnable:YES];
                    break;
                default:
                    [rate setTargetCode:@"---"];
                    [rate setAgainstCode:@"---"];
                    [rate setEnable:NO];
                    break;                    
            }
            if (formatDisplay == CURRANCY_FORMAT_DOT) {
                [rate setStrRate:@"0.00"];
                [rate setStrDiffer:@"0.00"];
            } else {
                [rate setStrRate:@"0,00"];
                [rate setStrDiffer:@"0,00"];
            }
            [rate setDoubleRate:0];
            [rate setLastRate:0];
            [rate setDiffer:0];
            [currencyRates addObject:rate];
            [rate release];
        }
    }
}

- (void)saveCurrencyRates
{
    NSLog(@"saveCurrancyRates");
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *ratesAsData = [NSKeyedArchiver archivedDataWithRootObject:currencyRates];
    [defaults setObject:ratesAsData forKey:currancyRatesListKey];	
}

- (void)loadCurrencyRates
{
    NSLog(@"loadCurrancyRates");
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    formatSpeech = [defaults integerForKey:formatSpeechKey];
    formatDisplay = [defaults integerForKey:formatDisplayKey];
    NSData *ratesAsData = [defaults objectForKey:currancyRatesListKey];
    if (ratesAsData == nil) {
        [self initCurrencyRates];
        return;
    }
    currencyRates = [NSKeyedUnarchiver unarchiveObjectWithData:ratesAsData];
    if (currencyRates == nil) {
        [self initCurrencyRates];
    }
    long num = NUMBER_OF_RATES - [currencyRates count];
    if (num > 0) {
        for (int i = 0; i < num; i++) {
            CurrencyRate *rate = [[CurrencyRate alloc] init];
            if (rate) {
                [rate setTargetCode:@"---"];
                [rate setAgainstCode:@"---"];
                [rate setStrRate:@"0"];
                [rate setStrDiffer:@""];
                [rate setDoubleRate:0];
                [rate setLastRate:0];
                [rate setDiffer:0];
                [currencyRates addObject:rate];
                [rate release];
            }
        }
    }
    return;
}

- (void)setCurrencyList
{
    Currency *ent;
    if (currencyList == nil) {
        currencyList = [[NSMutableArray alloc] init];
    }
    if (currencyList == nil) {
        return;
    }
    
    [comboBoxTargetCode removeAllItems];
    [comboBoxAgainstCode removeAllItems];
    
    ent = [[Currency alloc] init];
    
    if (ent) {
        [ent setCode:CURRENCY_AE];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_AE];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_AE];
        [ent setSymble:@"د.إ"];
        [ent addLang:@"ja_JP":@"UAE ディルハム"];
        [ent addLang:@"en_US":@"UAE Dirham"];
        [ent addLang:@"de_DE":@"VAE Dirham"];
        [ent addLang:@"fr_FR":@"Dirham Émirats arabes unis"];
        [ent addLang:@"it_IT":@"Emirati Arabi Uniti Dirham"];
        [ent addLang:@"es_ES":@"Dirham de Emiratos Arabes Unidos"];
        [ent addLang:@"pt_PT":@"Dirham EAU"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_AR];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_AR];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_AR];
        [ent setSymble:@"$"];
        [ent addLang:@"ja_JP":@"アルゼンチン ペソ"];
        [ent addLang:@"en_US":@"Argentine Peso"];
        [ent addLang:@"de_DE":@"Argentinischer Peso"];
        [ent addLang:@"fr_FR":@"Argentine Peso"];
        [ent addLang:@"it_IT":@"Argentina Peso"];
        [ent addLang:@"es_ES":@"Peso argentino"];
        [ent addLang:@"pt_PT":@"Peso argentino"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_AU];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_AU];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_AU];
        [ent setSymble:@"$"];
        [ent addLang:@"ja_JP":@"オーストラリア ドル"];
        [ent addLang:@"en_US":@"Australian Dollar"];
        [ent addLang:@"de_DE":@"Australischer Dollar"];
        [ent addLang:@"fr_FR":@"Dollar Australien"];
        [ent addLang:@"it_IT":@"Australia Dollaro austr"];
        [ent addLang:@"es_ES":@"Dólar australiano"];
        [ent addLang:@"pt_PT":@"Dólar australiano"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_BH];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_BH];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_BH];
        [ent setSymble:@"$"];
        [ent addLang:@"ja_JP":@"バーレーン ディナール"];
        [ent addLang:@"en_US":@"Bahraini Dinar"];
        [ent addLang:@"de_DE":@"Bahrain Dinar"];
        [ent addLang:@"fr_FR":@"Dinar de Bahreïn"];
        [ent addLang:@"it_IT":@"Bahrain Dinaro"];
        [ent addLang:@"es_ES":@"Dinar de Bahréin"];
        [ent addLang:@"pt_PT":@"Dinar de Bahrein"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_BR];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_BR];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_BR];
        [ent setSymble:@"R$"];
        [ent addLang:@"ja_JP":@"ブラジル レアル"];
        [ent addLang:@"en_US":@"Brazilian Real"];
        [ent addLang:@"de_DE":@"Brasilianischer Real"];
        [ent addLang:@"fr_FR":@"Real Brésilien"];
        [ent addLang:@"it_IT":@"Brasile Real"];
        [ent addLang:@"es_ES":@"Real brasileño"];
        [ent addLang:@"pt_PT":@"Real brasileiro"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_CA];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_CA];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_CA];
        [ent setSymble:@"$"];
        [ent addLang:@"ja_JP":@"カナダ ドル"];
        [ent addLang:@"en_US":@"Canadian Dollar"];
        [ent addLang:@"de_DE":@"Kanadischer Dollar"];
        [ent addLang:@"fr_FR":@"Dollar Canadien"];
        [ent addLang:@"it_IT":@"Canada Dollaro canad"];
        [ent addLang:@"es_ES":@"Dólar canadiense"];
        [ent addLang:@"pt_PT":@"Dólar canadense"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_CH];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_CH];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_CH];
        [ent setSymble:@"Fr"];
        [ent addLang:@"ja_JP":@"スイス フラン"];
        [ent addLang:@"en_US":@"Swiss Franc"];
        [ent addLang:@"de_DE":@"Schweizer Franken"];
        [ent addLang:@"fr_FR":@"Franc Suisse"];
        [ent addLang:@"it_IT":@"Svizzera Franco"];
        [ent addLang:@"es_ES":@"Franco suizo"];
        [ent addLang:@"pt_PT":@"Franco suíço"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_CL];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_CL];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_CL];
        [ent setSymble:@"$"];
        [ent addLang:@"ja_JP":@"チリ ペソ"];
        [ent addLang:@"en_US":@"Chilean Peso"];
        [ent addLang:@"de_DE":@"Chilenischer Peso"];
        [ent addLang:@"fr_FR":@"Peso Chilien"];
        [ent addLang:@"it_IT":@"Cile Peso cileno"];
        [ent addLang:@"es_ES":@"Peso chileno"];
        [ent addLang:@"pt_PT":@"Peso chileno"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_CN];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_CN];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_CN];
        [ent setSymble:@"Ұ"];
        [ent addLang:@"ja_JP":@"ジンミンゲン"];
        [ent addLang:@"en_US":@"Chinese Yuan"];
        [ent addLang:@"de_DE":@"Chinesischer Renminbi"];
        [ent addLang:@"fr_FR":@"Yuan Chinois"];
        [ent addLang:@"it_IT":@"Cina Yuan"];
        [ent addLang:@"es_ES":@"Yuan chino"];
        [ent addLang:@"pt_PT":@"Iuan chinês"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_CO];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_CO];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_CO];
        [ent setSymble:@"$"];
        [ent addLang:@"ja_JP":@"コロンビア ペソ"];
        [ent addLang:@"en_US":@"Colombian Peso"];
        [ent addLang:@"de_DE":@"Kolumbianischer Peso"];
        [ent addLang:@"fr_FR":@"Peso Colombien"];
        [ent addLang:@"it_IT":@"Colombia  Peso col"];
        [ent addLang:@"es_ES":@"Peso colombiano"];
        [ent addLang:@"pt_PT":@"Peso colombiano"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_CZ];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_CZ];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_CZ];
        [ent setSymble:@"Kč"];
        [ent addLang:@"ja_JP":@"チェコ コルナ"];
        [ent addLang:@"en_US":@"Czech Koruna"];
        [ent addLang:@"de_DE":@"Tschechische Krone"];
        [ent addLang:@"fr_FR":@"Couronne Tchèque"];
        [ent addLang:@"it_IT":@"Rep Ceca Corona"];
        [ent addLang:@"es_ES":@"Corona checa"];
        [ent addLang:@"pt_PT":@"Coroa tcheca"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_DK];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_DK];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_DK];
        [ent setSymble:@"Kr"];
        [ent addLang:@"ja_JP":@"デンマーク クローネ"];
        [ent addLang:@"en_US":@"Danish Krone"];
        [ent addLang:@"de_DE":@"Dänische Krone"];
        [ent addLang:@"fr_FR":@"Couronne Danoise"];
        [ent addLang:@"it_IT":@"Danimarca Corona dan"];
        [ent addLang:@"es_ES":@"Corona danesa"];
        [ent addLang:@"pt_PT":@"Coroa dinamarquesa"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_EG];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_EG];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_EG];
        [ent setSymble:@"ج.م"];
        [ent addLang:@"ja_JP":@"エジプト ポンド"];
        [ent addLang:@"en_US":@"Egyptian Pound"];
        [ent addLang:@"de_DE":@"Ägyptisches Pfund"];
        [ent addLang:@"fr_FR":@"Egyptian Pound"];
        [ent addLang:@"it_IT":@"Egitto Sterlina egiziana"];
        [ent addLang:@"es_ES":@"Libra egipcia"];
        [ent addLang:@"pt_PT":@"Libra egípcia"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_EU];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_EU];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_EU];
        [currencyList addObject:ent];
        [ent setSymble:@"€"];
        [ent addLang:@"ja_JP":@"ユーロ"];
        [ent addLang:@"en_US":@"Euro"];
        [ent addLang:@"de_DE":@"Euro"];
        [ent addLang:@"fr_FR":@"Euro"];
        [ent addLang:@"it_IT":@"Euro"];
        [ent addLang:@"es_ES":@"Euro"];
        [ent addLang:@"pt_PT":@"Euro"];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_UK];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_UK];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_UK];
        [ent setSymble:@"£"];
        [ent addLang:@"ja_JP":@"イギリス ポンド"];
        [ent addLang:@"en_US":@"British Pound"];
        [ent addLang:@"de_DE":@"Britisches Pfund"];
        [ent addLang:@"fr_FR":@"Livre Sterling"];
        [ent addLang:@"it_IT":@"Regno Unito Sterlina"];
        [ent addLang:@"es_ES":@"Libra esterlina"];
        [ent addLang:@"pt_PT":@"Libra britânica"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_HK];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_HK];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_HK];
        [ent setSymble:@"$"];
        [ent addLang:@"ja_JP":@"香港 ドル"];
        [ent addLang:@"en_US":@"Hong Kong Dollar"];
        [ent addLang:@"de_DE":@"HongKong Dollar"];
        [ent addLang:@"fr_FR":@"Dollar HongKongais"];
        [ent addLang:@"it_IT":@"Hong Kong Dollaro di Hong Kong"];
        [ent addLang:@"es_ES":@"Dólar de Hong Kong"];
        [ent addLang:@"pt_PT":@"Dólar de Hong Kong"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_HU];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_HU];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_HU];
        [ent setSymble:@"Ft"];
        [ent addLang:@"ja_JP":@"ハンガリー フォリント"];
        [ent addLang:@"en_US":@"Hungarian Forint"];
        [ent addLang:@"de_DE":@"Ungarische Forint"];
        [ent addLang:@"fr_FR":@"Forint Hongrois"];
        [ent addLang:@"it_IT":@"Ungheria  Forino ungh"];
        [ent addLang:@"es_ES":@"Florín húngaro"];
        [ent addLang:@"pt_PT":@"Forint húngaro"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_ID];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_ID];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_ID];
        [ent setSymble:@"Rp"];
        [ent addLang:@"ja_JP":@"インドネシア ルピア"];
        [ent addLang:@"en_US":@"Indonesian Rupiah"];
        [ent addLang:@"de_DE":@"Indonesische Rupie"];
        [ent addLang:@"fr_FR":@"Roupie Indonésienne"];
        [ent addLang:@"it_IT":@"Indonesia Rupia"];
        [ent addLang:@"es_ES":@"Rupia indonesia"];
        [ent addLang:@"pt_PT":@"Rúpia da Indonésia"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_IL];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_IL];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_IL];
        [ent setSymble:@"₪"];
        [ent addLang:@"ja_JP":@"イスラエル シェケル"];
        [ent addLang:@"en_US":@"Israeli Shekel"];
        [ent addLang:@"de_DE":@"Israelischer Schekel"];
        [ent addLang:@"fr_FR":@"Shekel Israelien"];
        [ent addLang:@"it_IT":@"Israele Shekel"];
        [ent addLang:@"es_ES":@"Shekel israelí"];
        [ent addLang:@"pt_PT":@"Shekel israelense"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_IN];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_IN];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_IN];
        [ent setSymble:@"₨"];
        [ent addLang:@"ja_JP":@"インド ルピー"];
        [ent addLang:@"en_US":@"Indian Rupee"];
        [ent addLang:@"de_DE":@"Indische Rupie"];
        [ent addLang:@"fr_FR":@"Roupie Indienne"];
        [ent addLang:@"it_IT":@"India Rupia"];
        [ent addLang:@"es_ES":@"Rupia india"];
        [ent addLang:@"pt_PT":@"Rúpia indiana"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_JP];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_JP];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_JP];
        [ent setSymble:@"¥"];
        [ent addLang:@"ja_JP":@"円"];
        [ent addLang:@"en_US":@"Japanese Yen"];
        [ent addLang:@"de_DE":@"Japanischer Yen"];
        [ent addLang:@"fr_FR":@"Yen Japonais"];
        [ent addLang:@"it_IT":@"Giappone Yen"];
        [ent addLang:@"es_ES":@"Yen japonés"];
        [ent addLang:@"pt_PT":@"Iene japonês"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_KR];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_KR];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_KR];
        [ent setSymble:@"₩"];
        [ent addLang:@"ja_JP":@"韓国 ウォン"];
        [ent addLang:@"en_US":@"South Korean Won"];
        [ent addLang:@"de_DE":@"Südkoreanische Won"];
        [ent addLang:@"fr_FR":@"Won Sudcoréen"];
        [ent addLang:@"it_IT":@"Won sudcoreano"];
        [ent addLang:@"es_ES":@"Won surcoreano"];
        [ent addLang:@"pt_PT":@"Won Sulcoreano"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_MX];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_MX];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_MX];
        [ent setSymble:@"$"];
        [ent addLang:@"ja_JP":@"メキシコ ペソ"];
        [ent addLang:@"en_US":@"Mexican Peso"];
        [ent addLang:@"de_DE":@"Mexikanischer Peso"];
        [ent addLang:@"fr_FR":@"Peso Mexicain"];
        [ent addLang:@"it_IT":@"Messico Peso"];
        [ent addLang:@"es_ES":@"Peso mexicano"];
        [ent addLang:@"pt_PT":@"Peso mexicano "];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_MY];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_MY];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_MY];
        [ent setSymble:@"RM"];
        [ent addLang:@"ja_JP":@"マレーシア リンギット"];
        [ent addLang:@"en_US":@"Malaysian Ringgit"];
        [ent addLang:@"de_DE":@"Malaysischer Ringgit"];
        [ent addLang:@"fr_FR":@"Malaysian Ringgit"];
        [ent addLang:@"it_IT":@"Malesia Ringgit"];
        [ent addLang:@"es_ES":@"Ringgit malayo"];
        [ent addLang:@"pt_PT":@"Ringgit malaio"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_NO];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_NO];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_NO];
        [ent setSymble:@"kr"];
        [ent addLang:@"ja_JP":@"ノルウェイ クローネ"];
        [ent addLang:@"en_US":@"Norwegian Krone"];
        [ent addLang:@"de_DE":@"Norwegische Krone"];
        [ent addLang:@"fr_FR":@"Couronne Norvégienne"];
        [ent addLang:@"it_IT":@"Norvegia Corona"];
        [ent addLang:@"es_ES":@"Corona noruega"];
        [ent addLang:@"pt_PT":@"Coroa norueguesa"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_NZ];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_NZ];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_NZ];
        [ent setSymble:@"$"];
        [ent addLang:@"ja_JP":@"ニュージーランド ドル"];
        [ent addLang:@"en_US":@"New Zealand Dollar"];
        [ent addLang:@"de_DE":@"Neuseeländischer Dollar"];
        [ent addLang:@"fr_FR":@"Dollar NéoZélandais"];
        [ent addLang:@"it_IT":@"Nuova Zelanda Dollaro neozeland"];
        [ent addLang:@"es_ES":@"Dólar neozelandés"];
        [ent addLang:@"pt_PT":@"Dólar da Nova Zelândia"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_PE];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_PE];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_PE];
        [ent setSymble:@"S/."];
        [ent addLang:@"ja_JP":@"ペルー ソル"];
        [ent addLang:@"en_US":@"Peruvian Nuevo Sol"];
        [ent addLang:@"de_DE":@"Peruanischer Sol"];
        [ent addLang:@"fr_FR":@"Sol Péruvien"];
        [ent addLang:@"it_IT":@"Perù  Nuevo Sol"];
        [ent addLang:@"es_ES":@"Nuevo Sol peruano"];
        [ent addLang:@"pt_PT":@"Novo Sol peruano"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_PH];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_PH];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_PH];
        [ent setSymble:@"₱"];
        [ent addLang:@"ja_JP":@"フィリピン ペソ"];
        [ent addLang:@"en_US":@"Philippine Peso"];
        [ent addLang:@"de_DE":@"Philippinischer Peso"];
        [ent addLang:@"fr_FR":@"Peso Philippin"];
        [ent addLang:@"it_IT":@"Filippine Peso"];
        [ent addLang:@"es_ES":@"Peso filipino"];
        [ent addLang:@"pt_PT":@"Peso das Filipinas"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_PL];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_PL];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_PL];
        [ent setSymble:@"zł"];
        [ent addLang:@"ja_JP":@"ポーランド ズウォティ"];
        [ent addLang:@"en_US":@"Polish Zloty"];
        [ent addLang:@"de_DE":@"Polnischer Zloty"];
        [ent addLang:@"fr_FR":@"Zloty Polonais"];
        [ent addLang:@"it_IT":@"Polonia Zloty"];
        [ent addLang:@"es_ES":@"Zloty polaco"];
        [ent addLang:@"pt_PT":@"Zloty da Polônia"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_QA];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_QA];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_QA];
        [ent setSymble:@"ر.ق"];
        [ent addLang:@"ja_JP":@"カタール リヤル"];
        [ent addLang:@"en_US":@"Qatar Rial"];
        [ent addLang:@"de_DE":@"Katar Rial"];
        [ent addLang:@"fr_FR":@"Riyal du Qatar"];
        [ent addLang:@"it_IT":@"Qatar Rial"];
        [ent addLang:@"es_ES":@"Riyal Qatarí"];
        [ent addLang:@"pt_PT":@"Rial do Catar"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_RU];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_RU];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_RU];
        [ent setSymble:@"руб"];
        [ent addLang:@"ja_JP":@"ロシア ルーブル"];
        [ent addLang:@"en_US":@"Russian Rouble"];
        [ent addLang:@"de_DE":@"Russischer Rubel"];
        [ent addLang:@"fr_FR":@"Rouble Russe"];
        [ent addLang:@"it_IT":@"Russia Rublo"];
        [ent addLang:@"es_ES":@"Rublo ruso"];
        [ent addLang:@"pt_PT":@"Rublo russo"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_SA];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_SA];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_SA];
        [ent setSymble:@"ر.س"];
        [ent addLang:@"ja_JP":@"サウジアラビア レアル"];
        [ent addLang:@"en_US":@"Saudi Arabian Riyal"];
        [ent addLang:@"de_DE":@"Saudiarabischer Rial"];
        [ent addLang:@"fr_FR":@"Riyal Saoudien"];
        [ent addLang:@"it_IT":@"Arabia Saudita Riyal"];
        [ent addLang:@"es_ES":@"Riyal saudí"];
        [ent addLang:@"pt_PT":@"Rial da Arábia Saudita"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_SE];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_SE];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_SE];
        [ent setSymble:@"kr"];
        [ent addLang:@"ja_JP":@"スウェーデン クローネ"];
        [ent addLang:@"en_US":@"Swedish Krona"];
        [ent addLang:@"de_DE":@"Schwedische Krone"];
        [ent addLang:@"fr_FR":@"Couronne Suédoise"];
        [ent addLang:@"it_IT":@"Svezia Corona"];
        [ent addLang:@"es_ES":@"Corona sueca"];
        [ent addLang:@"pt_PT":@"Coroa sueca"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_SG];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_SG];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_SG];
        [ent setSymble:@"S$"];
        [ent addLang:@"ja_JP":@"シンガポール ドル"];
        [ent addLang:@"en_US":@"Singapore Dollar"];
        [ent addLang:@"de_DE":@"Singapur Dollar"];
        [ent addLang:@"fr_FR":@"Dollar de Singapour"];
        [ent addLang:@"it_IT":@"Singapore Dollaro"];
        [ent addLang:@"es_ES":@"Dólar de Singapur"];
        [ent addLang:@"pt_PT":@"Dólar de Cingapura"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_TH];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_TH];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_TH];
        [ent setSymble:@"฿"];
        [ent addLang:@"ja_JP":@"タイ バーツ"];
        [ent addLang:@"en_US":@"Thai Baht"];
        [ent addLang:@"de_DE":@"Thailändischer Baht"];
        [ent addLang:@"fr_FR":@"Baht Thaïlandais"];
        [ent addLang:@"it_IT":@"Tailandia Baht"];
        [ent addLang:@"es_ES":@"Baht tailandés"];
        [ent addLang:@"pt_PT":@"Baht tailandês"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_TR];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_TR];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_TR];
        [ent setSymble:@"TL"];
        [ent addLang:@"ja_JP":@"トルコ リラ"];
        [ent addLang:@"en_US":@"Turkish Lira"];
        [ent addLang:@"de_DE":@"Türkische Lira"];
        [ent addLang:@"fr_FR":@"Lire Turque"];
        [ent addLang:@"it_IT":@"Turchia Lira"];
        [ent addLang:@"es_ES":@"Lira turca"];
        [ent addLang:@"pt_PT":@"Lira turca"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_TW];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_TW];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_TW];
        [ent setSymble:@"$"];
        [ent addLang:@"ja_JP":@"台湾 ドル"];
        [ent addLang:@"en_US":@"Taiwan Dollar"];
        [ent addLang:@"de_DE":@"Taiwanesischer Dollar"];
        [ent addLang:@"fr_FR":@"Taiwan Dollar"];
        [ent addLang:@"it_IT":@"Taiwan Dollaro taiwanese"];
        [ent addLang:@"es_ES":@"Dólar taiwanés"];
        [ent addLang:@"pt_PT":@"Dólar de Taiwan"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_US];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_US];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_US];
        [ent setSymble:@"$"];
        [ent addLang:@"ja_JP":@"米ドル"];
        [ent addLang:@"en_US":@"United States Doller"];
        [ent addLang:@"de_DE":@"US Dollar"];
        [ent addLang:@"fr_FR":@"Dollar américain"];
        [ent addLang:@"it_IT":@"USA Dollaro"];
        [ent addLang:@"es_ES":@"Dólar estadounidense"];
        [ent addLang:@"pt_PT":@"Dólar americano"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_VN];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_VN];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_VN];
        [ent setSymble:@"₫"];
        [ent addLang:@"ja_JP":@"ベトナム ドン"];
        [ent addLang:@"en_US":@"Vietnam Dong"];
        [ent addLang:@"de_DE":@"Vietnamesischer Dong"];
        [ent addLang:@"fr_FR":@"Vietnam Dong"];
        [ent addLang:@"it_IT":@"Vietnam Dong"];
        [ent addLang:@"es_ES":@"Dong de Vietnam"];
        [ent addLang:@"pt_PT":@"Dong vietnamita"];
        [currencyList addObject:ent];
        [ent release];
    }    
    
    ent = [[Currency alloc] init];
    if (ent) {
        [ent setCode:CURRENCY_ZA];
        [comboBoxAgainstCode addItemWithObjectValue:CURRENCY_ZA];
        [comboBoxTargetCode addItemWithObjectValue:CURRENCY_ZA];
        [ent setSymble:@"R"];
        [ent addLang:@"ja_JP":@"南アフリカ ランド"];
        [ent addLang:@"en_US":@"South African Rand"];
        [ent addLang:@"de_DE":@"Südafrikanischer Rand"];
        [ent addLang:@"fr_FR":@"Rand SudAfricain"];
        [ent addLang:@"it_IT":@"Sudafrica Rand"];
        [ent addLang:@"es_ES":@"Rand sudafricano"];
        [ent addLang:@"pt_PT":@"Rande SulAfricano"];
        [currencyList addObject:ent];
        [ent release];
    }
    
    [comboBoxAgainstCode addItemWithObjectValue:@"---"];
    [comboBoxTargetCode addItemWithObjectValue:@"---"];
    
    NSMenuItem* subMenu;
    for (Currency *item in currencyList) {
        //NSlog(@" %@ %@ ", [item targetCode],[item againstCode]);
        subMenu = [[NSMenuItem alloc] initWithTitle:[item code] action:@selector(selectTargetMenu:) keyEquivalent:@""];
        [[menuTarget submenu] addItem:subMenu];
        [subMenu release];
        subMenu = [[NSMenuItem alloc] initWithTitle:[item code] action:@selector(selectAgainstMenu:) keyEquivalent:@""];
        [[menuAgainst submenu] addItem:subMenu];
        [subMenu release];
    }
    subMenu = [[NSMenuItem alloc] initWithTitle:@"---" action:@selector(selectTargetMenu:) keyEquivalent:@""];
    [[menuTarget submenu] addItem:subMenu];
    [subMenu release];
    subMenu = [[NSMenuItem alloc] initWithTitle:@"---" action:@selector(selectAgainstMenu:) keyEquivalent:@""];
    [[menuAgainst submenu] addItem:subMenu];
    [subMenu release];
}

- (NSString*)getCurrencyName:(NSString*)lang :(NSString*)code
{
    for (Currency* currency in currencyList) {
        if ([code isEqualToString:[currency code]]) {
            return [currency getLocalName:lang];
        }
        
    }
    return @"";
}

- (NSString*)getCurrencySymble:(NSString*)code
{
    for (Currency* currency in currencyList) {
        if ([code isEqualToString:[currency code]]) {
            return [currency symble];
        }
        
    }
    return @"";
}

- (void)startObservingCurrencyRate:(CurrencyRate*)item
{
    // NSLog(@"startObservingCurrencyRate: %@", item);
    [item addObserver:self
           forKeyPath:@"targetCode"
              options:NSKeyValueObservingOptionOld
              context:NULL];
    [item addObserver:self
           forKeyPath:@"againstCode"
              options:NSKeyValueObservingOptionOld
              context:NULL];
    [item addObserver:self
           forKeyPath:@"enable"
              options:NSKeyValueObservingOptionOld
              context:NULL];
}

- (void)stopObservingCurrenctRate:(CurrencyRate*)item
{
    // NSLog(@"stopObservingCurrencyRate: %@", item);
    [item removeObserver:self forKeyPath:@"targetCode"];
    [item removeObserver:self forKeyPath:@"againstCode"];
    [item removeObserver:self forKeyPath:@"enable"];
}

- (void)changeKeyPath:(NSString*)keyPath
             obObject:(id)obj
              toValue:(id)newValue
{
    NSLog(@"changeKeyPath: %@", keyPath);
}

- (void)observeValueForKeyPath:(NSString*)keyPath
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    NSLog(@"observeValueForKeyPath: %@", keyPath);
    if ([keyPath isEqualToString:@"targetCode"] == YES ||
        [keyPath isEqualToString:@"againstCode"] == YES) {
        CurrencyRate* item = object;
        NSString* symble = nil;
        NSLog(@"%d: %@/%@",item.index,item.targetCode,item.againstCode);
        if ([keyPath isEqualToString:@"targetCode"] == YES) {
            if ([item targetCode] == nil || [[item targetCode] isEqualToString:@""] == YES) {
                [item setTargetCode:@"---"];
            }
            if ([[item targetCode] isEqualToString:@"---"] == NO) {
                symble = [self getCurrencySymble:[item targetCode]];
                if (symble == nil || [symble isEqualToString:@""] == YES) {
                    [item setTargetCode:@"---"];
                }
            }
        }
        if ([keyPath isEqualToString:@"againstCode"] == YES) {
            if ([item againstCode] == nil || [[item againstCode] isEqualToString:@""] == YES) {
                [item setAgainstCode:@"---"];
            }
            if ([[item againstCode] isEqualToString:@"---"] == NO) {
                symble = [self getCurrencySymble:[item againstCode]];
                if (symble == nil || [symble isEqualToString:@""]) {
                    [item setAgainstCode:@"---"];
                }
            }
        }
        if (symble && [symble isEqualToString:@""]) {
            NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
                                             defaultButton:NSLocalizedString(@"OK",@"Ok")
                                           alternateButton:nil
                                               otherButton:nil
                                 informativeTextWithFormat:NSLocalizedString(@"ITEM_NOTSUPPORT", @"Specified code is not supported.")];
            [alert beginSheetModalForWindow:[syntheTickerDelegate mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
        }
        if (formatDisplay == CURRANCY_FORMAT_DOT) {
            [item setStrRate:@"0.00"];
            [item setStrDiffer:@"0.00"];
        } else {
            [item setStrRate:@"0,00"];
            [item setStrDiffer:@"0,00"];
        }
        [item setDoubleRate:0];
        [item setLastRate:0];
        [item setPrevClose:0];
        [item setPrevCloseUpdated:NO];
        if ([[item targetCode] isEqualToString:@"---"] == YES ||
            [[item againstCode] isEqualToString:@"---"] == YES) {
            [item setEnable:NO];
        }
        [self saveCurrencyRates];
        [self refreshPanel];
    } else if ([keyPath isEqualToString:@"enable"] == YES) {
        [self saveCurrencyRates];
    }
}

#pragma mark Localizer

- (void) localizeView
{
    // NSTableColumn *column = nil;
    NSString* lang = NSLocalizedString(@"LANG",@"English");
    NSLog(@"localizeView: %@", lang);
    if ([lang isEqualToString:@"Japanese"]) {
        NSLog(@"LANG: %@", lang);
        //[mainWindow setTitle:@"しんせふぉれっくす"];
        [menuAbout setTitle:@"しんせふぉれっくす について"];
        [menuPreference setTitle:@"環境設定..."];
        [menuHide setTitle:@"しんせふぉれっくす を隠す"];
        [menuHideOthers setTitle:@"ほかを隠す"];
        [menuShowAll setTitle:@"すべてを表示"];
        [menuQuit setTitle:@"しんせふぉれっくす を終了"];
        [menuControls setTitle:@"コントロール"];
        [menuShowWindow setTitle:@"ウィンドウを表示"];
        [menuShowPanel setTitle:@"サブパネルを表示"];
        [menuStartSpeaking setTitle:@"スピーチを開始"];
        [menuStopSpeaking setTitle:@"スピーチを停止"];
        [menuReadPanel setTitle:@"サブパネルを読み上げ"];
        [menuCopyPanel setTitle:@"サブパネルをコピー"];
        [menuUpdate setTitle:@"すべての為替レートを更新"];
        [menuShowWebSite setTitle:@"ウェブサイトを表示"];
        [menuVerify setTitle:@"通貨ペアを検証"];
        [menuVoice setTitle:@"音声"];
        [menuServer setTitle:@"サーバー"];
        [menuTarget setTitle:@"通貨コード 左 ⚑"];
        [menuAgainst setTitle:@"通貨コード 右 ⚐"];
    } else if ([lang isEqualToString:@"German"]) {
        NSLog(@"LANG: %@", lang);
        [menuAbout setTitle:@"Über SyntheForex"];
        [menuPreference setTitle:@"Einstellungen..."];
        [menuHide setTitle:@"SyntheForex ausblenden"];
        [menuHideOthers setTitle:@"Andere ausblenden"];
        [menuShowAll setTitle:@"Alle einblenden"];
        [menuQuit setTitle:@"SyntheForex beenden"];
        [menuControls setTitle:@"Steuerung"];
        [menuShowWindow setTitle:@"Einblenden Fenster"];
        [menuShowPanel setTitle:@"Einblenden Sub-Panel"];
        [menuStartSpeaking setTitle:@"Sprachausgabe starten"];
        [menuStopSpeaking setTitle:@"Sprachausgabe stoppen"];
        [menuReadPanel setTitle:@"Lesen Sub-Panel"];
        [menuCopyPanel setTitle:@"Kopieren Sub-Panel"];
        [menuUpdate setTitle:@"Update Alle Wechselkurse"];
        [menuShowWebSite setTitle:@"Siehe Website"];
        [menuVerify setTitle:@"Überprüfen Sie Paar von Währungen"];
        [menuVoice setTitle:@"Stimme"];
        [menuServer setTitle:@"Server"];
        [menuTarget setTitle:@"Währung links ⚑"];
        [menuAgainst setTitle:@"Währung rechts ⚐"];
    } else if ([lang isEqualToString:@"French"]) {
        NSLog(@"LANG: %@", lang);
        [menuAbout setTitle:@"À propos de SyntheForex"];
        [menuPreference setTitle:@"Préférences..."];
        [menuHide setTitle:@"Masquer SyntheForex"];
        [menuHideOthers setTitle:@"Masquer les Autres"];
        [menuShowAll setTitle:@"Tout afficher"];
        [menuQuit setTitle:@"Quitter SyntheForex"];
        [menuControls setTitle:@"Contrôle"];
        [menuShowWindow setTitle:@"Voir vitrine"];
        [menuShowPanel setTitle:@"Voir Sous-Panneau"];
        [menuStartSpeaking setTitle:@"Commencer la lecture"];
        [menuStopSpeaking setTitle:@"Arrêter la lecture"];
        [menuReadPanel setTitle:@"lire Sous-Panneau"];
        [menuCopyPanel setTitle:@"Copier Sous-Panneau"];
        [menuUpdate setTitle:@"Mise à jour Tous les Change"];
        [menuShowWebSite setTitle:@"Voir Website"];
        [menuVerify setTitle:@"Vérifiez paire de devises"];
        [menuVoice setTitle:@"Voix"];
        [menuServer setTitle:@"Serveur"];
        [menuTarget setTitle:@"Devises gauche ⚑"];
        [menuAgainst setTitle:@"Devises droite ⚐"];
    } else if ([lang isEqualToString:@"Italian"]) {
        NSLog(@"LANG: %@", lang);
        [menuAbout setTitle:@"Informazioni su SyntheForex"];
        [menuPreference setTitle:@"Preferenza..."];
        [menuHide setTitle:@"Nascondi SyntheForex"];
        [menuHideOthers setTitle:@"Nascondi altre"];
        [menuShowAll setTitle:@"Mostra tutte"];
        [menuQuit setTitle:@"Esci da SyntheForex"];
        [menuControls setTitle:@"Controlli"];
        [menuShowWindow setTitle:@"Mostra Finestra"];
        [menuShowPanel setTitle:@"Mostra Pannello Sub"];
        [menuStartSpeaking setTitle:@"Inizia riproduzione"];
        [menuStopSpeaking setTitle:@"Interrompi riproduzione"];
        [menuReadPanel setTitle:@"Lettura Pannello Sub"];
        [menuCopyPanel setTitle:@"Copia Pannello Sub"];
        [menuUpdate setTitle:@"Aggiorna tutti i Tassi di Cambio"];
        [menuShowWebSite setTitle:@"Mostra sito Web"];
        [menuVerify setTitle:@"Verificare coppia di valute"];
        [menuVoice setTitle:@"Voce"];
        [menuServer setTitle:@"Server"];
        [menuTarget setTitle:@"Valuta sinistra ⚑"];
        [menuAgainst setTitle:@"Valuta destra ⚐"];
    } else if ([lang isEqualToString:@"Spanish"]) {
        NSLog(@"LANG: %@", lang);
        [menuAbout setTitle:@"Acerca de SyntheForex"];
        [menuPreference setTitle:@"Preferencias..."];
        [menuHide setTitle:@"Ocultar SyntheForex"];
        [menuHideOthers setTitle:@"Ocultar otros"];
        [menuShowAll setTitle:@"Mostrar todo"];
        [menuQuit setTitle:@"Salir de SyntheForex"];
        [menuControls setTitle:@"Controles"];
        [menuShowWindow setTitle:@"Mostrar Ventana"];
        [menuShowPanel setTitle:@"Mostrar Subpanel"];
        [menuStartSpeaking setTitle:@"Iniciar locución"];
        [menuStopSpeaking setTitle:@"Detener locución"];
        [menuReadPanel setTitle:@"Leer Subpanel"];
        [menuCopyPanel setTitle:@"Copiar Subpanel"];
        [menuUpdate setTitle:@"Actualización de todos los Tipos de Cambio"];
        [menuShowWebSite setTitle:@"Mostrar Sitio Web"];
        [menuVerify setTitle:@"Verifique Par de Monedas"];
        [menuVoice setTitle:@"Voz"];
        [menuServer setTitle:@"Servidor"];
        [menuTarget setTitle:@"Moneda izquierda ⚑"];
        [menuAgainst setTitle:@"Moneda derecho ⚐"];
    } else if ([lang isEqualToString:@"Portuguese"]) {
        NSLog(@"LANG: %@", lang);
        [menuAbout setTitle:@"Sobre o SyntheForex"];
        [menuPreference setTitle:@"Preferências..."];
        [menuHide setTitle:@"Ocultar SyntheForex"];
        [menuHideOthers setTitle:@"Ocultar outros"];
        [menuShowAll setTitle:@"Mostrar Tudo"];
        [menuQuit setTitle:@"Encerrar SyntheForex"];
        [menuControls setTitle:@"Controles"];
        [menuShowWindow setTitle:@"Mostrar Janela"];
        [menuShowPanel setTitle:@"Mostrar Sub Painel"];
        [menuStartSpeaking setTitle:@"Começar a Falar"];
        [menuStopSpeaking setTitle:@"Parar de Falar"];
        [menuReadPanel setTitle:@"Leia Sub Painel"];
        [menuCopyPanel setTitle:@"Copiar Sub Painel"];
        [menuUpdate setTitle:@"Atualizar todas as Taxas de Câmbio"];
        [menuShowWebSite setTitle:@"Mostrar Web Site"];
        [menuVerify setTitle:@"Verifique Par de Moedas"];
        [menuVoice setTitle:@"Voz"];
        [menuServer setTitle:@"Servidor"];
        [menuTarget setTitle:@"Moeda esquerda ⚑"];
        [menuAgainst setTitle:@"Moeda direito ⚐"];
    }
    /* in English
     [menuAbout setTitle:@"About SyntheForex"];
     [menuPreference setTitle:@"Preferences..."];
     [menuHide setTitle:@"Hide SyntheForex"];
     [menuHideOthers setTitle:@"Hide Others"];
     [menuShowAll setTitle:@"Show All"];
     [menuQuit setTitle:@"Quit SyntheForex"];
     [menuControls setTitle:@"Controls"];
     [menuShowWindow setTitle:@"Show Window"];
     [menuStartSpeaking setTitle:@"Start Speaking"];
     [menuStopSpeaking setTitle:@"Stop Speaking"];
     [menuUpdate setTitle:@"Update All Exchange Rates"];
     [menuShowWebSite setTitle:@"Show Web Site"];
     [menuVerify setTitle:@"Verify Pair of Currencies"];
     [menuVoice setTitle:@"Select Voice"];
     [menuServer setTitle:@"Select Server"];
     [menuTarget setTitle:@"Select Currency To"];
     [menuAgainst setTitle:@Select Currency From""];
     */
}

@end
