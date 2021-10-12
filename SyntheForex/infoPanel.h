//
//  infoPanel.h
//  RadioDow
//
//  Created by Takahiro Sayama on 12/03/20.
//  Copyright 2012 tanuki-project. All rights reserved.
//

#ifndef InfoPanel_common_h
#define InfoPanel_common_h

#import		<Cocoa/Cocoa.h>

@interface infoItem : NSObject {
    long            index;
    NSString*		codeTo;
    NSString*		codeFrom;
    NSString*		name;
    double          prevClose;
    double          price;
    double          differ;
    double			raise;
}

- (id) init;

@property	(readwrite)			long            index;
@property	(readwrite,copy)	NSString*		name;
@property	(readwrite,copy)	NSString*		codeTo;
@property	(readwrite,copy)	NSString*		codeFrom;
@property	(readwrite)         double          price;
@property	(readwrite)         double          prevClose;
@property	(readwrite)			double			differ;
@property	(readwrite)			double			raise;
@end


@interface infoPanel : NSWindowController <NSSpeechSynthesizerDelegate> {
    NSMutableArray				*items;
    NSMutableString				*priceList;
    NSString					*title;
    BOOL						speeching;
    NSString					*speechText;
    NSSpeechSynthesizer			*speechSynth;
    int                         speechIndex;
    IBOutlet NSPanel			*infoPanel;
    IBOutlet NSTextView			*infoView;
    IBOutlet NSTextField		*infoField;
    IBOutlet NSTableView		*infoTableView;
    IBOutlet NSScrollView		*infoScrollView;
    IBOutlet NSArrayController	*itemController;
    IBOutlet NSButton			*speechButton;
    IBOutlet NSButton           *refreshButton;
    IBOutlet NSButton           *lockButton;
    IBOutlet NSNumberFormatter  *prevCloseFormatter;
    IBOutlet NSNumberFormatter  *latestFormatter;
    IBOutlet NSNumberFormatter  *changeFormatter;
    IBOutlet NSNumberFormatter  *ratioFormatter;
}

- (IBAction)controlSpeech:(id)sender;
- (IBAction)startSpeech:(id)sender;
- (IBAction)stopSpeech:(id)sender;
- (IBAction)updatePrice:(id)sender;
- (IBAction)lockPanel:(id)sender;
- (int)speechItem;
- (NSString*)getCurrencyName:(NSString*)lang :(NSString*)code;
- (void)setPanelTitle:(double)price :(double)prevClose;
- (void)setItem:(NSString*)codeTo :(NSString*)codeFrom :(double)price :(double)prevClose;
- (void)rearrangePanel;
- (void)sortItems;
- (void)initData;
- (void)tableView:(NSTableView*)tableView sortDescriptorsDidChange:(NSArray*)oldDescriptors;
- (void)setFontColor:(NSColor*)color;
- (void)setDisplayFormatter;
- (void)localizeView;

@property	(readwrite)			BOOL				speeching;
@property	(readwrite,retain)	NSMutableArray*		items;
@property	(readwrite,copy)	NSMutableString*	priceList;
@property	(readwrite,copy)	NSString*			title;
@property	(readwrite,retain)	NSPanel*			infoPanel;
@property	(readwrite,retain)	NSTextView*			infoView;
@property	(readwrite,retain)	NSTableView*		infoTableView;
@property	(readwrite,retain)	NSScrollView*		infoScrollView;
@property	(readwrite,retain)	NSTextField*		infoField;
@property	(readwrite,retain)	NSButton*           refreshButton;
@property	(readwrite,retain)	NSButton*           lockButton;

@end

#endif
