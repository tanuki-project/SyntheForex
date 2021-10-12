//
//  webAccess.m
//  SyntheTicker
//
//  Created by 佐山 隆裕 on 11/12/26.
//  Copyright (c) 2011年 tanuki-project. All rights reserved.
//

#import     "webAccess.h"
#include    "AppDelegate.h"
#include    "infoPanel.h"
#include    "build.h"

extern AppDelegate  *syntheTickerDelegate;
extern bool         skipSpeechUnchanged;
extern NSString		*speechVoice;
extern NSString		*speechVoiceLocaleIdentifier;
//extern NSString		*serverSelection;
extern double       digitThreshold;
extern double       alarmThreshold;
extern long         formatDisplay;
extern long         formatSpeech;

@implementation webAccess

- (id)init
{
    self = [super init];
    if (self) {
        urlConnection = nil;
        connectionData = nil;
        urlContent = nil;
    }
    return self;
}

- (void)dealloc
{
    if (connectionData) {
        [connectionData release];
    }
    if (urlContent) {
        [urlContent release];
    }
    [super dealloc];
}

#pragma mark connection

- (void)startConnection: (NSString*)urlString
{
    NSLog(@"startConnection: %@", urlString);
    NSURL* url = [NSURL URLWithString:urlString];
    NSURLRequest* req = [NSURLRequest requestWithURL:url];
    urlConnection = [NSURLConnection connectionWithRequest:req delegate:self];
    if (connectionUrl) {
        [connectionUrl release];
    }
    connectionUrl = [urlString retain];
}

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"didReceiveResponse");
    if (connectionData) {
        [connectionData release];
    }
    // NSLog(@"size = %lld", [response expectedContentLength]);
    NSLog(@"%@", [response MIMEType]);
    NSLog(@"%@", [response textEncodingName]);
    connectionData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection*)connection
    didReceiveData:(NSData*)data
{
    // NSLog(@"didReceiveData: %d", [data length]);
    if (connectionData) {
        [connectionData appendData:data];
    }
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    NSLog(@"didFailWithError: %@", error);
    if (urlConnection == connection) {
        urlConnection = nil;
    }
    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
                                     defaultButton:NSLocalizedString(@"OK",@"Ok")
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:NSLocalizedString(@"CONNECTION_FAILED", @"Failed to connect server:\n%@"), [error localizedDescription]];
    [alert beginSheetModalForWindow:[syntheTickerDelegate mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
    [syntheTickerDelegate playStop:self];
    [syntheTickerDelegate enableRequest:YES];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"didFinishLoading");
    NSString *htmlString = [[NSString alloc] initWithData:connectionData encoding:NSUTF8StringEncoding];
    if (htmlString == nil) {
        htmlString = [[NSString alloc] initWithData:connectionData encoding:NSShiftJISStringEncoding];
    }
    if (htmlString == nil) {
        htmlString = [[NSString alloc] initWithData:connectionData encoding:NSJapaneseEUCStringEncoding];
    }
    // urlContent = [htmlString retain];
    urlContent = htmlString;
    // NSLog(@"urlContent:\n%@", urlContent);
    if (urlConnection == connection) {
        urlConnection = nil;
        if ([self scraipePrice] < 0) {
            NSLog(@"scraipePrice failed.");
            if (retrying == YES) {
                NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"ERROR",@"Error")
                                                 defaultButton:NSLocalizedString(@"OK",@"Ok")
                                               alternateButton:nil
                                                   otherButton:nil
                                     informativeTextWithFormat:NSLocalizedString(@"DOWNLOAD_FAILED", @"Failed to download exchange rate: %@"), targetCode];
                [alert beginSheetModalForWindow:[syntheTickerDelegate mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
                [urlContent release];
                urlContent = nil;
                [syntheTickerDelegate startSpeech:@" "];
                //[syntheTickerDelegate playStop:self];
            } else {
                retrying = YES;
                [urlContent release];
                urlContent = nil;
                usleep(500000);
                [self fetchPrice:targetCode];
            }
        }
    }
    [urlContent release];
    urlContent = nil;
    [syntheTickerDelegate enableRequest:YES];
}

- (BOOL)cnnecting {
    if (urlConnection == nil) {
        return NO;
    }
    return YES;
}

#pragma mark scraping

- (void)fetchPrice:(NSString*)code
{
    if (code == nil) {
        return;
    }
    NSString* urlString = nil;
    if (serverSelection) {
        if ([serverSelection isEqualToString:SERVER_NAME_YAHOO_US] == YES) {
            urlString = [[NSString alloc] initWithFormat:FORMAT_YAHOO_US_FX,code];
        } else if ([serverSelection isEqualToString:SERVER_NAME_YAHOO_JP] == YES) {
            urlString = [[NSString alloc] initWithFormat:FORMAT_YAHOO_JP_FX,code];
        } else if ([serverSelection isEqualToString:SERVER_NAME_YAHOO_UK] == YES) {
            urlString = [[NSString alloc] initWithFormat:FORMAT_YAHOO_UK_FX,code];
        } else if ([serverSelection isEqualToString:SERVER_NAME_YAHOO_AU] == YES) {
            urlString = [[NSString alloc] initWithFormat:FORMAT_YAHOO_AU_FX,code];
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
        } else if ([serverSelection isEqualToString:SERVER_NAME_GOOGLE] == YES) {
            urlString = [[NSString alloc] initWithFormat:FORMAT_GOOGLE_FINANCE,code];
        } else if ([serverSelection isEqualToString:SERVER_NAME_EXCHANGE_RATES] == YES) {
            urlString = [[NSString alloc] initWithFormat:FORMAT_EXCHANGE_RATES,[code substringToIndex:3],[code substringFromIndex:3]];
        }
    }
    if (urlString == nil) {
        urlString = [[NSString alloc] initWithFormat:FORMAT_YAHOO_US_FX,code];
    }
    [self startConnection:urlString];
    [urlString release];
    if (retrying == YES) {
        return;
    }
    if (targetCode) {
        [targetCode release];
    }
    targetCode = [code retain];
}

- (int)scraipePrice
{
    double		newPrice = -1;
    double		prevPrice = -1;
    NSString*	filter_from1 = nil;
    NSString*	filter_to1 = nil;
    NSString*	filter_from2 = nil;
    NSString*	filter_to2 = nil;
    NSString*	filter_from3 = nil;
    NSString*	filter_from1_prev = nil;
    NSString*	filter_from1_mobile = nil;
    NSString*	filter_diff_from1 = nil;
    NSString*	filter_diff_from2 = nil;
    NSString*	filter_diff_to = nil;
    NSString*   subString1;
    NSString*   subString2;
    bool        dot2comma = NO;
    bool        alarm = NO;
    bool        fourFigit = NO;
    double      raise = 0;
    double      differ = 0;
    
    if (formatSpeech == CURRANCY_FORMAT_COMMA) {
        dot2comma = YES;
    }
    if ([connectionUrl hasPrefix:PREFIX_YAHOO_US_STOCK] ||
        [connectionUrl hasPrefix:PREFIX_YAHOO_UK_STOCK] ||
        [connectionUrl hasPrefix:PREFIX_YAHOO_DE_STOCK] ||
        [connectionUrl hasPrefix:PREFIX_YAHOO_FR_STOCK] ||
        [connectionUrl hasPrefix:PREFIX_YAHOO_IT_STOCK] ||
        [connectionUrl hasPrefix:PREFIX_YAHOO_ES_STOCK] ||
        [connectionUrl hasPrefix:PREFIX_YAHOO_BR_STOCK] ||
        [connectionUrl hasPrefix:PREFIX_YAHOO_SG_STOCK] ||
        [connectionUrl hasPrefix:PREFIX_YAHOO_AU_STOCK] ) {
        filter_from1	= FILTER_YAHOO_US_FROM1;
        filter_to1		= FILTER_YAHOO_US_TO1;
        filter_from2	= [NSString stringWithFormat:FILTER_YAHOO_US_FROM2_FX,[targetCode lowercaseString]];
        filter_to2		= FILTER_YAHOO_US_TO2;
        filter_from1_prev	= FILTER_YAHOO_US_FROM1_PREV;
        filter_from1_mobile = [NSString stringWithFormat:FILTER_YAHOO_MOBILE_FROM1,[targetCode uppercaseString]];
        filter_diff_from1 = FILTER_YAHOO_US_FROM1_DIFF;
        filter_diff_to = FILTER_YAHOO_US_TO_DIFF;
    } else if ([connectionUrl hasPrefix:PREFIX_YAHOO_JP_STOCK]) {
        filter_from1	= FILTER_YAHOO_JP_FX_FROM1;
        filter_to1		= FILTER_YAHOO_JP_TO1;
        filter_from2	= FILTER_YAHOO_JP_FROM2;
        filter_to2		= FILTER_YAHOO_JP_TO2;
    } else if ([connectionUrl hasPrefix:PREFIX_GOOGLE_FINANCE]) {
        filter_from1	= FILTER_GOOGLE_FROM1;
        filter_from2	= FILTER_GOOGLE_FROM2_FX;
        filter_from3	= FILTER_GOOGLE_FROM3_FX;
        filter_to1		= FILTER_GOOGLE_TO1_FX;
        filter_to2		= FILTER_GOOGLE_TO2;
        filter_diff_from1 = FILTER_GOOGLE_FROM1_DIFFG;
        filter_diff_from2 = FILTER_GOOGLE_FROM2_DIFF;
        filter_diff_to = FILTER_GOOGLE_TO2;
    } else if ([connectionUrl hasPrefix:PREFIX_EXCHANGE_RATES]) {
        filter_from1	= FILTER_EXCHANGE_RATE_FROM1;
        filter_from2	= FILTER_EXCHANGE_RATE_FROM2;
        filter_to1		= FILTER_EXCHANGE_RATE_TO1;
        filter_to2		= FILTER_EXCHANGE_RATE_TO2;
    } else {
        return -1;
    }
    
    //NSLog(@"\r\n%@", urlContent);
    NSRange range = [urlContent rangeOfString:filter_from1];
    if (range.length == 0) {
        NSLog(@"filter_from1 isn't found %d,%d", (int)range.location, (int)range.length);
        if (filter_from1_prev) {
            range = [urlContent rangeOfString:filter_from1_prev];
            if (range.length == 0) {
                NSLog(@"filter_from1_prev isn't found %d,%d", (int)range.location, (int)range.length);
            } else {
                filter_to2 = FILTER_YAHOO_US_TO2_PREV;
            }
        }
        if (range.length == 0 && filter_from1_mobile) {
            range = [urlContent rangeOfString:filter_from1_mobile];
            if (range.length == 0) {
                NSLog(@"filter_from1_mobile isn't found %d,%d", (int)range.location, (int)range.length);
            } else {
                filter_from2 = FILTER_YAHOO_MOBILE_FROM2;
                filter_to1 = FILTER_YAHOO_MOBILE_TO1;
                filter_to2 = FILTER_YAHOO_MOBILE_TO2;
                filter_diff_from1 = FILTER_YAHOO_MOBILE_FROM1_DIFF;
                filter_diff_to = FILTER_YAHOO_MOBILE_TO_DIFF;
            }
        }
    }
    if (range.length == 0) {
        subString1 = [urlContent substringFromIndex:0];
    } else {
        subString1 = [urlContent substringFromIndex:range.location];
    }
    
    range = [subString1 rangeOfString:filter_to1];
    if (range.length == 0) {
        NSLog(@"filter_to1 isn't found %d,%d", (int)range.location, (int)range.length);
        // NSLog(@"\r\n%@",subString1);
        subString2 = subString1;
    } else {
        subString2 = [subString1 substringToIndex:range.location];
    }
    
    range = [subString2 rangeOfString:filter_from2];
    if (range.length == 0) {
        NSLog(@"filter_from2 isn't found");
        return -1;
    }
    subString1 = [subString2 substringFromIndex:range.location];
    
    range = [subString1 rangeOfString:filter_to2];
    if (range.length == 0) {
        NSLog(@"filter_to2 isn't found");
        return -1;
    }
    subString2 = [subString1 substringToIndex:range.location];
    if (filter_from3) {
        range = [subString2 rangeOfString:filter_from3];
        if (range.length == 0) {
            NSLog(@"filter_from3 isn't found");
            return -1;
        }
        subString1 = [subString2 substringFromIndex:range.location+range.length];
        if (strPrice) {
            [strPrice release];
        }
        strPrice = [subString1 retain];
    } else {
        subString1 = [subString2 substringFromIndex:[filter_from2 length]];
        if (strPrice) {
            [strPrice release];
        }
        strPrice = [subString1 retain];
    }
    
    NSMutableString* price = [[NSMutableString alloc] init];
    if ([connectionUrl hasPrefix:PREFIX_YAHOO_DE_STOCK] ||
        [connectionUrl hasPrefix:PREFIX_YAHOO_IT_STOCK] ||
        [connectionUrl hasPrefix:PREFIX_YAHOO_ES_STOCK] ||
        [connectionUrl hasPrefix:PREFIX_YAHOO_BR_STOCK]) {
        NSArray* splits = [strPrice componentsSeparatedByString:@"."];
        for (NSString* split in splits) {
            [price appendString:[split stringByReplacingOccurrencesOfString:@"," withString:@"."]];
        }
    } else if ([connectionUrl hasPrefix:PREFIX_YAHOO_FR_STOCK]) {
        NSArray* splits = [strPrice componentsSeparatedByString:@" "];
        for (NSString* split in splits) {
            [price appendString:[split stringByReplacingOccurrencesOfString:@"," withString:@"."]];
        }
    } else {
        NSArray* splits = [strPrice componentsSeparatedByString:@","];
        for (NSString* split in splits) {
            [price appendString:split];
        }
    }
    
    if ([price isEqualToString:@""] == YES) {
        NSLog(@"price is empty: %@", strPrice);
        [price release];
        return -1;
    }
    
    if (strPrice) {
        [strPrice release];
    }
    
    newPrice = round([price doubleValue]*10000)/10000;
    if (filter_diff_from1) {
        // parse previous close price
        subString1 = nil;
        NSRange range = [urlContent rangeOfString:filter_diff_from1];
        if (range.length == 0 && filter_diff_from2) {
            filter_diff_from1 = FILTER_GOOGLE_FROM1_DIFFR;
            range = [urlContent rangeOfString:filter_diff_from1];
        }
        if (range.length > 0) {
            subString1 = [urlContent substringFromIndex:range.location+range.length];
            if (filter_diff_from2) {
                range = [subString1 rangeOfString:filter_diff_from2];
                if (range.length > 0) {
                    subString2 = [subString1 substringFromIndex:range.location+range.length];
                    subString1 = subString2;
                }
            }
        }
        subString2 = nil;
        if (subString1) {
            range = [subString1 rangeOfString:filter_diff_to];
            if (range.length > 0) {
                subString2 = [subString1 substringToIndex:range.location];
            }
        }
        strPrice = subString2;
        if (strPrice) {
            NSLog(@"strPrice = %@",strPrice);
            NSMutableString* prevClose = [[NSMutableString alloc] init];
            if ([connectionUrl hasPrefix:PREFIX_YAHOO_DE_STOCK] ||
                [connectionUrl hasPrefix:PREFIX_YAHOO_IT_STOCK] ||
                [connectionUrl hasPrefix:PREFIX_YAHOO_ES_STOCK] ||
                [connectionUrl hasPrefix:PREFIX_YAHOO_BR_STOCK]) {
                NSArray* splits = [strPrice componentsSeparatedByString:@"."];
                for (NSString* split in splits) {
                    [prevClose appendString:[split stringByReplacingOccurrencesOfString:@"," withString:@"."]];
                }
            } else if ([connectionUrl hasPrefix:PREFIX_YAHOO_FR_STOCK]) {
                NSArray* splits = [strPrice componentsSeparatedByString:@" "];
                for (NSString* split in splits) {
                    [prevClose appendString:[split stringByReplacingOccurrencesOfString:@"," withString:@"."]];
                }
            } else {
                NSArray* splits = [strPrice componentsSeparatedByString:@","];
                for (NSString* split in splits) {
                    [prevClose appendString:split];
                }
            }
            if ([connectionUrl hasPrefix:PREFIX_GOOGLE_FINANCE]) {
                prevPrice = newPrice - round([prevClose doubleValue]*10000)/10000;
            } else {
                prevPrice = round([prevClose doubleValue]*10000)/10000;
            }
            [prevClose release];
            NSLog(@"prevClose = %0.4f", prevPrice);
            [targetItem setPrevClose:prevPrice];
            [targetItem setPrevCloseUpdated:YES];
        } else {
            if ([targetItem prevCloseUpdated] == NO) {
                [targetItem setPrevClose:0];
            }
        }
    } else {
        if ([targetItem prevCloseUpdated] == NO) {
            [targetItem setPrevClose:0];
        }
    }
    
    NSString* lang = speechVoiceLocaleIdentifier;
    NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
    if (digitThreshold == UNLIMITED_DIGIT_THRESHOLD || [price doubleValue] < digitThreshold) {
        fourFigit = YES;
        // newPrice = round([price doubleValue]*10000)/10000;
        [formatter setFormat:@"###0.0000"];
        strPrice = [NSString stringWithFormat:@"%@",[formatter stringFromNumber:[NSNumber numberWithDouble:newPrice]]];
    } else {
        // newPrice = round([price doubleValue]*100)/100;
        [formatter setFormat:@"###0.00"];
        strPrice = [NSString stringWithFormat:@"%@",[formatter stringFromNumber:[NSNumber numberWithDouble:newPrice]]];
    }
    [strPrice retain];
    NSLog(@"strPrice = %@", strPrice);
    
    if ([price hasPrefix:@"-"] == YES) {
        newPrice = -1;
    }
    if (newPrice < 0) {
        NSLog(@"value of price is minus: %f", newPrice);
        [price release];
        return -1;
    }
    NSLog(@"price = %f",newPrice);
    if ([targetItem doubleRate] > 0 && [price doubleValue] > 0) {
        raise = 100*[price doubleValue]/[targetItem doubleRate] - 100;
        NSLog(@"Change = %0.3f%% Threshold = %0.1f", raise, alarmThreshold);
        if (alarmThreshold > 0 && fabs(raise) >= alarmThreshold) {
            alarm = YES;
        }
    }
    [price release];
    if (targetItem) {
        NSString* symRate;
        if (formatDisplay == CURRANCY_FORMAT_DOT) {
            if ([[targetItem againstCode] isEqualToString:CURRENCY_AE] == YES ||
                [[targetItem againstCode] isEqualToString:CURRENCY_EG] == YES ||
                [[targetItem againstCode] isEqualToString:CURRENCY_QA] == YES ||
                [[targetItem againstCode] isEqualToString:CURRENCY_SA] == YES) {
                // Arabian format
                symRate = [[NSString alloc] initWithFormat:@"%@%@", strPrice, [syntheTickerDelegate getCurrencySymble:[targetItem againstCode]]];
            } else {
                symRate = [[NSString alloc] initWithFormat:@"%@%@", [syntheTickerDelegate getCurrencySymble:[targetItem againstCode]], strPrice];
            }
        } else {
            if ([[targetItem againstCode] isEqualToString:CURRENCY_AE] == YES ||
                [[targetItem againstCode] isEqualToString:CURRENCY_EG] == YES ||
                [[targetItem againstCode] isEqualToString:CURRENCY_QA] == YES ||
                [[targetItem againstCode] isEqualToString:CURRENCY_SA] == YES) {
                symRate = [[NSString alloc] initWithFormat:@"%@ %@", [syntheTickerDelegate getCurrencySymble:[targetItem againstCode]], [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","]];
            } else {
                symRate = [[NSString alloc] initWithFormat:@"%@ %@", [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","],[syntheTickerDelegate getCurrencySymble:[targetItem againstCode]]];
            }
        }
        [targetItem setStrRate:[symRate autorelease]];
        [targetItem setLastRate:[targetItem doubleRate]];
        [targetItem setDoubleRate:newPrice];
        [targetItem setDiffer:[targetItem doubleRate] - [targetItem lastRate]];
        if ([targetItem differ] != 0) {
            [targetItem setDate:[[[NSDate alloc] init] autorelease]];
        }
        if (fourFigit == YES) {
            differ = [targetItem differ];
        } else {
            differ = round(100*[targetItem doubleRate])/100 - round(100*[targetItem lastRate])/100;
        }
        NSString* strDiffer;
        if (differ < 0) {
            strDiffer = [NSString stringWithFormat:@"%@",[formatter stringFromNumber:[NSNumber numberWithDouble:-differ]]];
            [targetItem setStrDiffer: [NSString stringWithFormat:@"-%@",strDiffer]];
        } else if (differ == 0) {
            alarm = NO;
            [formatter setFormat:@"###0.00"];
            strDiffer = [NSString stringWithFormat:@"%@",[formatter stringFromNumber:[NSNumber numberWithDouble:differ]]];
            [targetItem setStrDiffer: [NSString stringWithFormat:@"%@",strDiffer]];
        } else {
            strDiffer = [NSString stringWithFormat:@"%@",[formatter stringFromNumber:[NSNumber numberWithDouble:differ]]];
            [targetItem setStrDiffer: [NSString stringWithFormat:@"+%@",strDiffer]];
        }
        NSLog(@"strDiffer = %@",[targetItem strDiffer]);
        if (formatDisplay == CURRANCY_FORMAT_COMMA) {
            NSString    *work;
            work = [[targetItem strDiffer] stringByReplacingOccurrencesOfString:@"." withString:@","];
            [targetItem setStrDiffer:work];
        }
        if ([targetItem differ] == [targetItem doubleRate]) {
            if (formatDisplay == CURRANCY_FORMAT_DOT) {
                [targetItem setStrDiffer:@"0.00"];
            } else {
                [targetItem setStrDiffer:@"0,00"];
            }
        }
        NSLog(@"strPrice = %@ strDiffer = %@ %f.04", [targetItem strRate], strDiffer, [targetItem differ]);
        NSString* speechText;
        if ([lang isEqualToString:LANG_JA_JP] == YES) {
            // speech in Japanese
            if ([targetItem differ] == [targetItem doubleRate]) {
                [targetItem setDiffer:0];
                [targetItem setEnable:YES];
                speechText = [[NSString alloc] initWithFormat:@"1 %@  %@ %@ . ",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:lang:[targetItem againstCode]]];
            } else if (differ == 0) {
                speechText = [[NSString alloc] initWithFormat:@"1 %@  %@ %@, 変わらず ",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:lang:[targetItem againstCode]]];
            } else if (differ > 0) {
                speechText = [[NSString alloc] initWithFormat:@"1 %@  %@ %@, プラス %@ .",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:lang:[targetItem againstCode]],
                              dot2comma ? [strDiffer stringByReplacingOccurrencesOfString:@"." withString:@","] : strDiffer];
            } else {
                speechText = [[NSString alloc] initWithFormat:@"1 %@  %@ %@, マイナス %@ .",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:lang:[targetItem againstCode]],
                              dot2comma ? [strDiffer stringByReplacingOccurrencesOfString:@"." withString:@","] : strDiffer];
            }
        } else if ([lang isEqualToString:LANG_DE_DE] == YES) {
            // speech in German
            if ([targetItem differ] == [targetItem doubleRate]) {
                [targetItem setDiffer:0];
                [targetItem setEnable:YES];
                speechText = [[NSString alloc] initWithFormat:@"1 %@, %@ %@ . ",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:lang:[targetItem againstCode]]];
            } else if (differ == 0) {
                speechText = [[NSString alloc] initWithFormat:@"1 %@, %@ %@ , unverändert . ",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:lang:[targetItem againstCode]]];
            } else if (differ > 0) {
                speechText = [[NSString alloc] initWithFormat:@"1 %@, %@ %@ , +%@ .",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:lang:[targetItem againstCode]],
                              dot2comma ? [strDiffer stringByReplacingOccurrencesOfString:@"." withString:@","] : strDiffer];
            } else {
                speechText = [[NSString alloc] initWithFormat:@"1 %@, %@ %@ , -%@ .",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:lang:[targetItem againstCode]],
                              dot2comma ? [strDiffer stringByReplacingOccurrencesOfString:@"." withString:@","] : strDiffer];
            }
        } else if ([lang isEqualToString:LANG_IT_IT] == YES) {
            // speech in German
            if ([targetItem differ] == [targetItem doubleRate]) {
                [targetItem setDiffer:0];
                [targetItem setEnable:YES];
                speechText = [[NSString alloc] initWithFormat:@"1 %@, %@ %@ . ",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:lang:[targetItem againstCode]]];
            } else if (differ == 0) {
                speechText = [[NSString alloc] initWithFormat:@"1 %@, %@ %@ , immutato . ",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:lang:[targetItem againstCode]]];
            } else if (differ > 0) {
                speechText = [[NSString alloc] initWithFormat:@"1 %@, %@ %@ , +%@ .",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:lang:[targetItem againstCode]],
                              dot2comma ? [strDiffer stringByReplacingOccurrencesOfString:@"." withString:@","] : strDiffer];
            } else {
                speechText = [[NSString alloc] initWithFormat:@"1 %@, %@ %@ , -%@ .",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:lang:[targetItem againstCode]],
                              dot2comma ? [strDiffer stringByReplacingOccurrencesOfString:@"." withString:@","] : strDiffer];
            }
        } else if ([lang isEqualToString:LANG_FR_FR] == YES ||
                   [lang isEqualToString:LANG_FR_CA] == YES) {
            // speech in French
            if ([targetItem differ] == [targetItem doubleRate]) {
                [targetItem setDiffer:0];
                [targetItem setEnable:YES];
                speechText = [[NSString alloc] initWithFormat:@"1 %@, %@ %@ . ",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:LANG_FR_FR:[targetItem againstCode]]];
            } else if (differ == 0) {
                speechText = [[NSString alloc] initWithFormat:@"1 %@, %@ %@ , inchangée . ",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:LANG_FR_FR:[targetItem againstCode]]];
            } else if (differ > 0) {
                speechText = [[NSString alloc] initWithFormat:@"1 %@, %@ %@ , +%@ .",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:LANG_FR_FR:[targetItem againstCode]],
                              dot2comma ? [strDiffer stringByReplacingOccurrencesOfString:@"." withString:@","] : strDiffer];
            } else {
                speechText = [[NSString alloc] initWithFormat:@"1 %@, %@ %@ , -%@ .",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:LANG_FR_FR:[targetItem againstCode]],
                              dot2comma ? [strDiffer stringByReplacingOccurrencesOfString:@"." withString:@","] : strDiffer];
            }
        } else if ([lang isEqualToString:LANG_ES_ES] == YES ||
                   [lang isEqualToString:LANG_ES_MX] == YES) {
            // speech in Spanish
            if ([targetItem differ] == [targetItem doubleRate]) {
                [targetItem setDiffer:0];
                [targetItem setEnable:YES];
                speechText = [[NSString alloc] initWithFormat:@"1 %@, %@ %@ . ",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:LANG_ES_ES:[targetItem againstCode]]];
            } else if (differ == 0) {
                speechText = [[NSString alloc] initWithFormat:@"1 %@, %@ %@ , sin cambios . ",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:LANG_ES_ES:[targetItem againstCode]]];
            } else if (differ > 0) {
                speechText = [[NSString alloc] initWithFormat:@"1 %@, %@ %@ , +%@ .",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:LANG_ES_ES:[targetItem againstCode]],
                              dot2comma ? [strDiffer stringByReplacingOccurrencesOfString:@"." withString:@","] : strDiffer];
            } else {
                speechText = [[NSString alloc] initWithFormat:@"1 %@, %@ %@ , -%@ .",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:LANG_ES_ES:[targetItem againstCode]],
                              dot2comma ? [strDiffer stringByReplacingOccurrencesOfString:@"." withString:@","] : strDiffer];
            }
        } else if ([lang isEqualToString:LANG_PT_PT] == YES ||
                   [lang isEqualToString:LANG_PT_BR] == YES) {
            // speech in Portuguese
            if ([targetItem differ] == [targetItem doubleRate]) {
                [targetItem setDiffer:0];
                [targetItem setEnable:YES];
                speechText = [[NSString alloc] initWithFormat:@"1 %@, %@ %@ . ",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:LANG_PT_PT:[targetItem againstCode]]];
            } else if (differ == 0) {
                speechText = [[NSString alloc] initWithFormat:@"1 %@, %@ %@ , inalterado . ",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:LANG_PT_PT:[targetItem againstCode]]];
            } else if (differ > 0) {
                speechText = [[NSString alloc] initWithFormat:@"1 %@, %@ %@ , +%@ .",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:LANG_PT_PT:[targetItem againstCode]],
                              dot2comma ? [strDiffer stringByReplacingOccurrencesOfString:@"." withString:@","] : strDiffer];
            } else {
                speechText = [[NSString alloc] initWithFormat:@"1 %@, %@ %@ , -%@ .",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:LANG_PT_PT:[targetItem againstCode]],
                              dot2comma ? [strDiffer stringByReplacingOccurrencesOfString:@"." withString:@","] : strDiffer];
            }
        } else {
            // speech in English
            if ([targetItem differ] == [targetItem doubleRate]) {
                [targetItem setDiffer:0];
                [targetItem setEnable:YES];
                speechText = [[NSString alloc] initWithFormat:@"1 %@, %@ %@ . ",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:lang:[targetItem againstCode]]];
            } else if (differ == 0) {
                speechText = [[NSString alloc] initWithFormat:@"1 %@, %@ %@ , unchanged . ",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:lang:[targetItem againstCode]]];
            } else if (differ > 0) {
                speechText = [[NSString alloc] initWithFormat:@"1 %@, %@ %@ , +%@ .",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:lang:[targetItem againstCode]],
                              dot2comma ? [strDiffer stringByReplacingOccurrencesOfString:@"." withString:@","] : strDiffer];
            } else {
                speechText = [[NSString alloc] initWithFormat:@"1 %@, %@ %@ , -%@ .",
                              [self getCurrencyName:lang:[targetItem targetCode]],
                              dot2comma ? [strPrice stringByReplacingOccurrencesOfString:@"." withString:@","] : strPrice,
                              [self getCurrencyName:lang:[targetItem againstCode]],
                              dot2comma ? [strDiffer stringByReplacingOccurrencesOfString:@"." withString:@","] : strDiffer];
            }
        }
        [syntheTickerDelegate saveCurrencyRates];
        [[syntheTickerDelegate iPanel] setItem:[targetItem targetCode]:[targetItem againstCode]:[targetItem doubleRate]:[targetItem prevClose]];
        [[syntheTickerDelegate iPanel] sortItems];
        NSLog(@"%@",speechText);
        if ([syntheTickerDelegate updating] == YES || [syntheTickerDelegate volumeMuted] == YES ||
            ([syntheTickerDelegate playing] == YES && skipSpeechUnchanged && [targetItem differ] ==0)) {
            [syntheTickerDelegate startSpeech:@" "];
        } else {
            if (alarm == YES) {
                NSSound *sound = [NSSound soundNamed:@"ChangeAlarm"];
                [sound play];
                usleep(500000);
            }
            [syntheTickerDelegate startSpeech:speechText];
        }
        [speechText release];
    }
    return 0;
}

- (NSString*)getCurrencyName:(NSString*)lang :(NSString*)code
{
    return [syntheTickerDelegate getCurrencyName:lang:code];
}

@synthesize		targetItem;
@synthesize     serverSelection;
@synthesize     retrying;

@end
