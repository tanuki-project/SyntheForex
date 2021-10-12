//
//  Currency.m
//  SyntheForex
//
//  Created by 佐山 隆裕 on 11/12/28.
//  Copyright (c) 2011年 tanuki-project. All rights reserved.
//

#import     "Currency.h"
#include    "build.h"

extern long         formatDisplay;
extern long         formatSpeech;

@implementation CurrencyName

- (id)init
{
    self = [super init];
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

@synthesize		lang;
@synthesize		name;

@end

@implementation Currency

- (id)init
{
    self = [super init];
    if (self) {
        code = nil;
        symble = nil;
        langs = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)addLang:(NSString*)lang :(NSString*)name
{
    CurrencyName *ent = [[CurrencyName alloc] init];
    if (ent == nil) {
        return;
    }
    [ent setLang:lang];
    [ent setName:name];
    [langs addObject:ent];
    [ent release];
}

- (NSString*)getLocalName:(NSString*)lang
{
    for (CurrencyName* name in langs) {
        if ([lang isEqualToString:[name lang]] == YES) {
            return [name name];
        }
    }
    if ([lang isEqualToString:LANG_EN_US] == NO) {
        for (CurrencyName* name in langs) {
            if ([[name lang] isEqualToString:LANG_EN_US] == YES) {
                return [name name];
            }
        }
    }
    return @"";
}

@synthesize		code;
@synthesize		symble;
@synthesize		langs;

@end

@implementation CurrencyRate

- (id)init
{
    self = [super init];
    if (self) {
        differ = 0;
        doubleRate = 0;
        if (formatDisplay == CURRANCY_FORMAT_DOT) {
            strRate = [[NSString alloc] initWithFormat:@"0.00"];
            strDiffer = [[NSString alloc] initWithFormat:@"0.00"];
        } else {
            strRate = [[NSString alloc] initWithFormat:@"0,00"];
            strDiffer = [[NSString alloc] initWithFormat:@"0,00"];
        }
        prevCloseUpdated = NO;
    }
    return self;
}

- (void)dealloc
{
    if (targetCode) {
        [targetCode release];
    }
    if (againstCode) {
        [againstCode release];
    }
    if (strRate) {
        [strRate release];
    }
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    // NSLog(@"encodeWithCoder @% @%", targetCode, againstCode);
    [coder encodeObject:targetCode  forKey:@"targetCode"];
    [coder encodeObject:againstCode forKey:@"againstCode"];
    [coder encodeObject:strRate     forKey:@"strRate"];
    [coder encodeObject:date        forKey:@"date"];
    [coder encodeDouble:doubleRate  forKey:@"doubleRate"];
    [coder encodeDouble:prevClose   forKey:@"prevClose"];
    [coder encodeBool  :enable      forKey:@"enable"];
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self == nil) {
        return self;
    }
    targetCode  = [[coder decodeObjectForKey:@"targetCode"]  retain];
    againstCode = [[coder decodeObjectForKey:@"againstCode"] retain];
    strRate     = [[coder decodeObjectForKey:@"strRate"]     retain];
    date        = [[coder decodeObjectForKey:@"date"] retain];
    doubleRate  =  [coder decodeDoubleForKey:@"doubleRate"];
    prevClose   =  [coder decodeDoubleForKey:@"prevClose"];
    enable      =  [coder decodeBoolForKey:  @"enable"];
    lastRate    = doubleRate;
    differ      = 0;
    if (formatDisplay == CURRANCY_FORMAT_DOT) {
        strDiffer   = [[NSString alloc] initWithFormat:@"0.00"];
    } else {
        strDiffer   = [[NSString alloc] initWithFormat:@"0,00"];
    }
    prevCloseUpdated = NO;
    return self;
}

@synthesize		index;
@synthesize		targetCode;
@synthesize		againstCode;
@synthesize		strRate;
@synthesize		date;
@synthesize		doubleRate;
@synthesize		lastRate;
@synthesize		strDiffer;
@synthesize		prevClose;
@synthesize		differ;
@synthesize		enable;
@synthesize     prevCloseUpdated;

@end
