//
//  infoPanel.m
//  RadioDow
//
//  Created by Takahiro Sayama on 12/03/20.
//  Copyright 2012 tanuki-project. All rights reserved.
//

#include    "AppDelegate.h"
#include	"infoPanel.h"
#include    "Currency.h"
#include    "build.h"

extern AppDelegate  *syntheTickerDelegate;

extern bool         sortSubPanel;
extern bool         showSubPanel;
extern bool         lockSubPanel;
extern NSString     *showSubPanelKey;
extern NSString     *lockSubPanelKey;
extern NSString		*speechVoice;
extern NSString		*speechVoiceLocaleIdentifier;
extern NSString     *speechSpeedKey;
extern long         formatDisplay;
extern bool         willTerminate;
extern long         formatSpeech;
NSPanel             *subPanel;

@implementation infoItem

- (id)init
{
    self = [super init];
    index = 0;
    name = nil;
    price = 0;
    prevClose = 0;
    differ = 0;
    raise = 0;
    return self;
}

- (void)dealloc
{
    if (name) {
        [name release];
    }
    if (codeTo) {
        [codeTo release];
    }
    if (codeFrom) {
        [codeFrom release];
    }
    [super dealloc];
}

@synthesize		index;
@synthesize		name;
@synthesize		codeTo;
@synthesize		codeFrom;
@synthesize		price;
@synthesize		prevClose;
@synthesize		differ;
@synthesize		raise;

@end


@implementation infoPanel

+ (void)initialize
{
    NSLog(@"initialize infoPanel");
}

- (id)init
{
    NSLog(@"init infoPanel");
    self = [super initWithWindowNibName:@"infoPanel"];
    if (self == nil) {
        return nil;
    }
    items = [[NSMutableArray alloc] init];
    priceList = [[NSMutableString alloc] init];
    [priceList setString:@"\r\n"];
    title = [[NSString alloc] init];
    speechText = nil;
    speeching = NO;
    speechSynth = [[NSSpeechSynthesizer alloc] initWithVoice:nil];
    [speechSynth setDelegate:self];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(actionClose:)
               name:NSWindowWillCloseNotification
             object:infoPanel];
    subPanel = infoPanel;
    return self;
}

- (void)dealloc
{
    if (items) {
        [items removeAllObjects];
        [items release];
    }
    if (title) {
        [title release];
    }
    if (priceList) {
        [priceList release];
    }
    if (speechText) {
        [speechText release];
    }
    [speechSynth release];
    [super dealloc];
}

/*
 - (void)close
 {
 NSLog(@"Close: infoPanel");
 if (speeching) {
 [self stopSpeech:self];
 }
 [super close];
 }
 */

- (void)windowDidLoad
{
    NSLog(@"Nib file is loaded");
    [self localizeView];
    [self setDisplayFormatter];
}

- (void)rearrangePanel
{
    [infoTableView reloadData];
    [itemController rearrangeObjects];
    [infoTableView deselectAll:self];
}

- (void)setPanelTitle:(double)price :(double)prevClose
{
    if (price == 0 || prevClose == 0) {
        [self setTitle:@"Top Charts : Dow Jones Industrial Average"];
    } else {
        double diff = price - prevClose;
        double ratio = round(10000*price/prevClose - 10000)/100;
        NSString* panelTitle = [NSString stringWithFormat:@"Top Charts : Dow Jones Industrial Average : $%0.2f (%0.2f,%0.2f%@)", price, diff, ratio, @"\%"];
        NSLog(@"%@", panelTitle);
        [self setTitle:panelTitle];
    }
}

- (void)actionClose:(NSNotification *)notification {
    NSLog(@"actionClose: %@", [[notification object] title]);
    if (willTerminate == YES) {
        return;
    }
    if ([[[notification object] title ] isEqualToString: @"Change from Previous Close"] == YES) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:NO forKey:showSubPanelKey];
        showSubPanel = NO;
    }
}

- (void)setItem:(NSString*)codeTo :(NSString*)codeFrom :(double)price :(double)prevClose
{
    // NSString    *currencyPair;
    double diff = price - prevClose;
    double raise;
    if ([codeTo isEqualToString:@"---"] == YES ||
        [codeFrom isEqualToString:@"---"] == YES) {
        return;
    }
    if (price == 0 || prevClose == 0) {
        raise = 0;
        diff = 0;
    } else {
        raise = price/prevClose - 1;
    }
    if (items == nil) {
        items = [[NSMutableArray alloc] init];
    } else {
        for (infoItem* item in items) {
            if ([codeTo isEqualToString:[item codeTo]] == YES &&
                [codeFrom isEqualToString:[item codeFrom]] == YES) {
                if ([item index] > 0 && [item index] <= [items count]) {
                    NSIndexSet* ixset = [NSIndexSet indexSetWithIndex:[item index] - 1];
                    [infoTableView selectRowIndexes:ixset byExtendingSelection:NO];
                }
                [item setPrice:price];
                [item setPrevClose:prevClose];
                [item setDiffer:diff];
                [item setRaise:raise];
                return;
            }
        }
    }
    infoItem* item = [[infoItem alloc] init];
    if (item) {
        [item setName:[[[NSString alloc] initWithFormat:@"%@/%@",codeTo,codeFrom] autorelease]];
        [item setCodeTo:[codeTo retain]];
        [item setCodeFrom:[codeFrom retain]];
        [item setPrice:price];
        [item setPrevClose:prevClose];
        [item setDiffer:diff];
        [item setRaise:raise];
        [items addObject:item];
        [item setIndex:[items count]];
        [item release];
    }
}

- (void)sortItems
{
    if (sortSubPanel == NO) {
        [infoTableView reloadData];
        [itemController rearrangeObjects];
        return;
    }
    NSSortDescriptor	*descriptor;
    NSMutableArray		*sortDescriptors = [[NSMutableArray alloc] init];
    descriptor = [[NSSortDescriptor alloc] initWithKey:@"raise" ascending:NO selector:@selector(compare:)];
    [sortDescriptors addObject:descriptor];
    [items sortUsingDescriptors:sortDescriptors];
    [descriptor release];
    [sortDescriptors release];
    int index = 0;
    for (infoItem* item in items) {
        index++;
        [item setIndex:index];
    }
    [infoTableView reloadData];
    [itemController rearrangeObjects];
}

- (void)initData {
#if 1
    [items removeAllObjects];
#else
    NSSortDescriptor	*descriptor;
    NSMutableArray		*sortDescriptors = [[NSMutableArray alloc] init];
    for (infoItem* item in items) {
        [item setPrice:0];
        [item setPrevClose:0];
        [item setDiffer:0];
        [item setRaise:0];
    }
    descriptor = [[NSSortDescriptor alloc] initWithKey:@"code" ascending:YES selector:@selector(compare:)];
    [sortDescriptors addObject:descriptor];
    [items sortUsingDescriptors:sortDescriptors];
    [descriptor release];
    [sortDescriptors release];
#endif
}

- (void)tableView:(NSTableView*)tableView sortDescriptorsDidChange:(NSArray*)oldDescriptors
{
    NSLog(@"sortDescriptorsDidChange");
    NSArray* new = [tableView sortDescriptors];
    [items sortUsingDescriptors:new];
    [tableView reloadData];
}

#pragma mark Speech

- (IBAction)controlSpeech:(id)sender {
    if (speeching == NO) {
        [self startSpeech:sender];
    } else {
        [self stopSpeech:sender];
    }
}									

- (IBAction)startSpeech:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    double speechSpeed = [defaults doubleForKey:speechSpeedKey];
    NSLog(@"startSpeech: %@ %f", [speechSynth voice], speechSpeed);
    [syntheTickerDelegate playStop:self];
    [speechSynth setRate:speechSpeed];
    speechIndex = 1;
    speeching = YES;
    if ([self speechItem] == -1) {
        speechIndex = 0;
        speeching = NO;
        return;
    }
    NSImage *template = [NSImage imageNamed:@"NSStopProgressFreestandingTemplate"];
    if (template) {
        [speechButton setImage:template];
    }
}

- (IBAction)stopSpeech:(id)sender
{
    NSLog(@"stopSpeech");
    if (speeching == YES) {
        [speechSynth stopSpeaking];
        speeching = NO;
        speechIndex = 0;
        NSImage *template = [NSImage imageNamed:@"NSGoRightTemplate"];
        if (template) {
            [speechButton setImage:template];
        }
    }
}

- (IBAction)updatePrice:(id)sender {
    [syntheTickerDelegate updateStart:self];
}

- (IBAction)lockPanel:(id)sender {
    NSImage *img;
    if (lockSubPanel == YES) {
        lockSubPanel = NO;
        img = [NSImage imageNamed:@"NSLockUnlockedTemplate"];
    } else {
        lockSubPanel = YES;
        img = [NSImage imageNamed:@"NSLockLockedTemplate"];
    }
    if (img) {
        [lockButton setImage:img];
    }
    [[self infoPanel] setFloatingPanel:lockSubPanel];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:lockSubPanel forKey:lockSubPanelKey];
}

- (void)speechSynthesizer:(NSSpeechSynthesizer*)sender
        didFinishSpeaking:(BOOL)complete
{
    NSLog(@"didFinishSpeaking:infoPanel");
    if (speeching && speechIndex > 0 && speechIndex < [items count]) {
        speechIndex++;
        if ([self speechItem] == 0) {
            return;
        }
    }
    NSImage *template = [NSImage imageNamed:@"NSGoRightTemplate"];
    if (template) {
        [speechButton setImage:template];
    }
    if (speechText) {
        [speechText release];
    }
    speechText = nil;
    speeching = NO;
    // reset selected row
    NSIndexSet* ixset = [NSIndexSet indexSetWithIndex:0];
    [infoTableView selectRowIndexes:ixset byExtendingSelection:NO];
    [infoTableView scrollRowToVisible:0];
    [infoTableView deselectAll:self];
    [[syntheTickerDelegate tableView] selectRowIndexes:ixset byExtendingSelection:NO];
    [[syntheTickerDelegate tableView] scrollRowToVisible:0];
    [[syntheTickerDelegate tableView] deselectAll:self];
}

- (int)speechItem {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    double speechSpeed = [defaults doubleForKey:speechSpeedKey];
    NSString* lang = speechVoiceLocaleIdentifier;
    NSLog(@"speechItem: %@ %f", [speechSynth voice], speechSpeed);
    
    if (speechText != nil) {
        [speechText release];
        speechText = nil;
    }
    for (infoItem* item in items) {
        if ([item index] != speechIndex) {
            continue;
        }
        NSString    *nameTo = [self getCurrencyName:lang:[item codeTo]];
        NSString    *nameFrom = [self getCurrencyName:lang:[item codeFrom]];
        NSString    *strPrice = [[[NSString alloc] initWithFormat:@"%0.4f",[item price]] autorelease];
        NSString    *strDiffer = [[[NSString alloc] initWithFormat:@"%0.4f",fabs([item differ])] autorelease];
        NSString    *strRaise = [[[NSString alloc] initWithFormat:@"%0.2f",fabs([item raise])*100] autorelease];
        if (formatSpeech == CURRANCY_FORMAT_COMMA) {
            NSString    *str;
            str = strPrice;
            strPrice = [str stringByReplacingOccurrencesOfString:@"." withString:@","];
            str = strDiffer;
            strDiffer = [str stringByReplacingOccurrencesOfString:@"." withString:@","];
            str = strRaise;
            strRaise = [str stringByReplacingOccurrencesOfString:@"." withString:@","];
        }
        
        if ([lang isEqualToString:LANG_JA_JP] == YES) {
            if ([item differ] == 0) {
                speechText = [[NSString alloc] initWithFormat:@"1 %@ , %@ %@ , 変わらず .",
                              nameTo, strPrice, nameFrom];
            } else if ([item differ] > 0) {
                speechText = [[NSString alloc] initWithFormat:@"1 %@ , %@ %@ , プラス %@ %@ , プラス %@パーセント .",
                              nameTo, strPrice, nameFrom, strDiffer, nameFrom, strRaise];
            } else {
                speechText = [[NSString alloc] initWithFormat:@"1 %@ , %@ %@ , マイナス %@ %@ , マイナス %@パーセント .",
                              nameTo, strPrice, nameFrom, strDiffer, nameFrom, strRaise];
            }
        } else if ([lang isEqualToString:LANG_DE_DE] == YES) {
            if ([item differ] == 0) {
                speechText = [[NSString alloc] initWithFormat: @"1 %@ , %@ %@ , unverändert .",
                              nameTo, strPrice, nameFrom];
            } else if ([item differ] > 0) {
                speechText = [[NSString alloc] initWithFormat: @"1 %@ , %@ %@ , +%@ %@ , +%@%@ .",
                              nameTo, strPrice, nameFrom, strDiffer, nameFrom, strRaise, @"%"];
            } else {
                speechText = [[NSString alloc] initWithFormat: @"1 %@ , %@ %@ , -%@ %@ , -%@%@ .",
                              nameTo, strPrice, nameFrom, strDiffer, nameFrom, strRaise, @"%"];
            }
        } else if ([lang isEqualToString:LANG_IT_IT] == YES) {
            if ([item differ] == 0) {
                speechText = [[NSString alloc] initWithFormat: @"1 %@ , %@ %@ , immutato .",
                              nameTo, strPrice, nameFrom];
            } else if ([item differ] > 0) {
                speechText = [[NSString alloc] initWithFormat: @"1 %@ , %@ %@ , +%@ %@ , +%@%@ .",
                              nameTo, strPrice, nameFrom, strDiffer, nameFrom, strRaise, @"%"];
            } else {
                speechText = [[NSString alloc] initWithFormat: @"1 %@ , %@ %@ , -%@ %@ , -%@%@ .",
                              nameTo, strPrice, nameFrom, strDiffer, nameFrom, strRaise, @"%"];
            }
        } else if ([lang isEqualToString:LANG_FR_FR] == YES ||
                   [lang isEqualToString:LANG_FR_CA] == YES) {
            if ([item differ] == 0) {
                speechText = [[NSString alloc] initWithFormat: @"1 %@ , %@ %@ , inchangée .",
                              nameTo, strPrice, nameFrom];
            } else if ([item differ] > 0) {
                speechText = [[NSString alloc] initWithFormat: @"1 %@ , %@ %@ , +%@ %@ , +%@%@ .",
                              nameTo, strPrice, nameFrom, strDiffer, nameFrom, strRaise, @"%"];
            } else {
                speechText = [[NSString alloc] initWithFormat: @"1 %@ , %@ %@ , -%@ %@ , -%@%@ .",
                              nameTo, strPrice, nameFrom, strDiffer, nameFrom, strRaise, @"%"];
            }
            
        } else if ([lang isEqualToString:LANG_ES_ES] == YES ||
                   [lang isEqualToString:LANG_ES_MX] == YES) {
            if ([item differ] == 0) {
                speechText = [[NSString alloc] initWithFormat: @"1 %@ , %@ %@ , sin cambios .",
                              nameTo, strPrice, nameFrom];
            } else if ([item differ] > 0) {
                speechText = [[NSString alloc] initWithFormat: @"1 %@ , %@ %@ , +%@ %@ , +%@%@ .",
                              nameTo, strPrice, nameFrom, strDiffer, nameFrom, strRaise, @"%"];
            } else {
                speechText = [[NSString alloc] initWithFormat: @"1 %@ , %@ %@ , -%@ %@ , -%@%@ .",
                              nameTo, strPrice, nameFrom, strDiffer, nameFrom, strRaise, @"%"];
            }
        } else if ([lang isEqualToString:LANG_PT_PT] == YES ||
                   [lang isEqualToString:LANG_PT_BR] == YES) {
            if ([item differ] == 0) {
                speechText = [[NSString alloc] initWithFormat: @"1 %@ , %@ %@ , inalterado .",
                              nameTo, strPrice, nameFrom];
            } else if ([item differ] > 0) {
                speechText = [[NSString alloc] initWithFormat: @"1 %@ , %@ %@ , +%@ %@ , +%@%@ .",
                              nameTo, strPrice, nameFrom, strDiffer, nameFrom, strRaise, @"%"];
            } else {
                speechText = [[NSString alloc] initWithFormat: @"1 %@ , %@ %@ , -%@ %@ , -%@%@ .",
                              nameTo, strPrice, nameFrom, strDiffer, nameFrom, strRaise, @"%"];
            }
        } else {
            if ([item differ] == 0) {
                speechText = [[NSString alloc] initWithFormat: @"1 %@ , %@ %@ , unchanged .",
                              nameTo, strPrice, nameFrom];
            } else if ([item differ] > 0) {
                speechText = [[NSString alloc] initWithFormat: @"1 %@ , %@ %@ , +%@ %@ , +%@%@ .",
                              nameTo, strPrice, nameFrom, strDiffer, nameFrom, strRaise, @"%"];
            } else {
                speechText = [[NSString alloc] initWithFormat: @"1 %@ , %@ %@ , -%@ %@ , -%@%@ .",
                              nameTo, strPrice, nameFrom, strDiffer, nameFrom, strRaise, @"%"];
            }
        }
        NSLog(@"%@", speechText);
        long row = [items indexOfObject:item];
        NSIndexSet* ixset = [NSIndexSet indexSetWithIndex:row];
        [infoTableView selectRowIndexes:ixset byExtendingSelection:NO];
        [infoTableView scrollRowToVisible:row];
        for (CurrencyRate* rate in [syntheTickerDelegate currencyRates]) {
            if ([[rate targetCode] isEqualToString:[item codeTo]] == YES &&
                [[rate againstCode] isEqualToString:[item codeFrom]] == YES) {
                if ([rate index] > 0) {
                    ixset = [NSIndexSet indexSetWithIndex:[rate index]-1];
                    [[syntheTickerDelegate tableView] selectRowIndexes:ixset byExtendingSelection:NO];
                    [[syntheTickerDelegate tableView] scrollRowToVisible:[rate index]-1];
                }
                break;
            }
        }
        /*
         */
#if 0
        for (Currency* currency in [syntheTickerDelegate currencyRates]) {
            NSString*   text;
            if ([[item codeFrom] isEqualToString:[currency code]] == NO) {
                continue;
            }
            if (isJp == YES) {
                if ([item differ] == 0) {
                    text = [[NSString alloc] initWithFormat:@"%0.2fドル, 変わらず .", [item price]];
                } else if ([item differ] > 0) {
                    text = [[NSString alloc] initWithFormat:@"%0.2fドル, プラス %0.2fドル, プラス %0.2fパーセント .", [item price], [item differ], [item raise]*100];
                } else {
                    text = [[NSString alloc] initWithFormat:@"%0.2fドル, マイナス %0.2fドル, マイナス %0.2fパーセント .", [item price], fabs([item differ]), fabs([item raise])*100];
                }
                speechText = [[NSString stringWithFormat:@"%d位, %@ %@", [item index], [company getLocalName:LANG_JA_JP], text] retain];
            } else {
                if ([item differ] == 0) {
                    text = [[NSString alloc] initWithFormat:@"%0.2f, unchanged .", [item price]];
                } else if ([item differ] > 0) {
                    text = [[NSString alloc] initWithFormat:@"$%0.2f, plus $%0.2f, +%0.2f%@ .", [item price], [item differ], [item raise]*100, @"%"];
                } else {
                    text = [[NSString alloc] initWithFormat:@"$%0.2f, minus $%0.2f, -%0.2f%@ .", [item price], fabs([item differ]), fabs([item raise])*100, @"%"];
                }
                speechText = [[NSString stringWithFormat:@"Number %d, %@ %@", [item index], [company getLocalName:LANG_EN_US], text] retain];
            }
            [text release];
            // Select row of current item
            long row = [items indexOfObject:item];
            NSIndexSet* ixset = [NSIndexSet indexSetWithIndex:row];
            [infoTableView selectRowIndexes:ixset byExtendingSelection:NO];
            [infoTableView scrollRowToVisible:row];
            ixset = [NSIndexSet indexSetWithIndex:[company index]];
            [[syntheTickerDelegate tableView] selectRowIndexes:ixset byExtendingSelection:NO];
            [[syntheTickerDelegate tableView] scrollRowToVisible:[company index]];
            break;
        }
#endif
        if (speechText == nil) {
            return -1;
        }
        NSLog(@"Speech:\n%@", speechText);
        [speechSynth setVoice:speechVoice];
        [speechSynth setRate:speechSpeed];
        [speechSynth setVolume:[[syntheTickerDelegate volumeSlider] doubleValue]];
        [speechSynth startSpeakingString:speechText];
        return 0;
    }
    return -1;
}

- (NSString*)getCurrencyName:(NSString*)lang :(NSString*)code
{
    return [syntheTickerDelegate getCurrencyName:lang:code];
}

- (void)setFontColor:(NSColor*)color
{
    NSTableColumn *column = nil;
    NSLog(@"setFontColor");
    
    // set font color of tableView
    column = [infoTableView  tableColumnWithIdentifier:@"index"];
    [(id)[column dataCell] setTextColor:color];
    column = [infoTableView  tableColumnWithIdentifier:@"code"];
    [(id)[column dataCell] setTextColor:color];
    column = [infoTableView  tableColumnWithIdentifier:@"prev"];
    [(id)[column dataCell] setTextColor:color];
    column = [infoTableView  tableColumnWithIdentifier:@"price"];
    [(id)[column dataCell] setTextColor:color];
    column = [infoTableView  tableColumnWithIdentifier:@"differ"];
    [(id)[column dataCell] setTextColor:color];
    column = [infoTableView  tableColumnWithIdentifier:@"raise"];
    [(id)[column dataCell] setTextColor:color];
    [infoTableView reloadData];
}

- (void)setDisplayFormatter
{
    NSLog(@"setDisplayFormatter");
    NSString* dSep;
    NSString* gSep;
    if (formatDisplay == CURRANCY_FORMAT_DOT) {
        dSep = @".";
        gSep = @",";
    } else {
        dSep = @",";
        gSep = @".";
    }
    [prevCloseFormatter setDecimalSeparator:dSep];
    [prevCloseFormatter setGroupingSeparator:gSep];
    [latestFormatter setDecimalSeparator:dSep];
    [latestFormatter setGroupingSeparator:gSep];
    [changeFormatter setDecimalSeparator:dSep];
    [changeFormatter setGroupingSeparator:gSep];
    [ratioFormatter setDecimalSeparator:dSep];
    [ratioFormatter setGroupingSeparator:gSep];
}

#pragma mark Localize

- (void) localizeView
{
    NSLog(@"localizeView");
    //NSTableColumn *column = nil;
    NSString* lang = NSLocalizedString(@"LANG",@"English");
    NSLog(@"localizeView: %@", lang);
    if ([lang isEqualToString:@"Japanese"]) {
        /*
         column = [infoTableView  tableColumnWithIdentifier:@"code"];
         [[column headerCell] setStringValue:@"コード"];
         column = [infoTableView  tableColumnWithIdentifier:@"prev"];
         [[column headerCell] setStringValue:@"前日終値"];
         column = [infoTableView  tableColumnWithIdentifier:@"price"];
         [[column headerCell] setStringValue:@"価格"];
         column = [infoTableView  tableColumnWithIdentifier:@"differ"];
         [[column headerCell] setStringValue:@"値幅"];
         column = [infoTableView  tableColumnWithIdentifier:@"raise"];
         [[column headerCell] setStringValue:@"騰落率"];
         */
    }
}

@synthesize		speeching;
@synthesize		items;
@synthesize		title;
@synthesize		priceList;
@synthesize		infoPanel;
@synthesize		infoView;
@synthesize		infoTableView;
@synthesize		infoScrollView;
@synthesize		infoField;
@synthesize     refreshButton;
@synthesize     lockButton;

@end
