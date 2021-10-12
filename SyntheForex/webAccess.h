//
//  webAccess.h
//  SyntheTicker
//
//  Created by 佐山 隆裕 on 11/12/26.
//  Copyright (c) 2011年 tanuki-project. All rights reserved.
//

#ifndef SyntheForex_webAccess_h
#define SyntheForex_webAccess_h

#import     <Foundation/Foundation.h>
#include    "Currency.h"

#define DEFAULT_DIGIT_THRESHOLD     2.0
#define DETAILED_DIGIT_THRESHOLD    10.0
#define UNLIMITED_DIGIT_THRESHOLD   0

#define DEFAULT_ALARM_THRESHOLD     0
#define ALARM_THRESHOLD_MIN         0.1
#define ALARM_THRESHOLD_MID         0.2
#define ALARM_THRESHOLD_MAX         0.5

#define SERVER_NAME_YAHOO_US            @"Yahoo! Finance US"
#define SERVER_NAME_YAHOO_AU            @"Yahoo! Finance AU"
#define SERVER_NAME_YAHOO_UK            @"Yahoo! Finance UK"
#define SERVER_NAME_YAHOO_JP            @"Yahoo! Finance JP"
#define SERVER_NAME_YAHOO_DE            @"Yahoo! Finance DE"
#define SERVER_NAME_YAHOO_FR            @"Yahoo! Finance FR"
#define SERVER_NAME_YAHOO_IT            @"Yahoo! Finance IT"
#define SERVER_NAME_YAHOO_ES            @"Yahoo! Finance ES"
#define SERVER_NAME_YAHOO_BR            @"Yahoo! Finance BR"
#define SERVER_NAME_YAHOO_SG            @"Yahoo! Finance SG"
#define SERVER_NAME_GOOGLE              @"Google Finance"
#define SERVER_NAME_EXCHANGE_RATES      @"Exchange-Rates.org"

#define	FORMAT_YAHOO_JP_HOME			@"http://quote.yahoo.co.jp/m3"
#define	FORMAT_YAHOO_US_HOME			@"http://finance.yahoo.com/currency-investing"
#define	FORMAT_YAHOO_UK_HOME			@"http://uk.finance.yahoo.com/currencies/investing.html"
#define	FORMAT_YAHOO_AU_HOME			@"http://au.finance.yahoo.com/currencies/investing.html"
#define	FORMAT_YAHOO_DE_HOME			@"http://de.finance.yahoo.com/waehrungen/devisen.html"
#define	FORMAT_YAHOO_FR_HOME			@"http://fr.finance.yahoo.com/devises/investissement.html"
#define	FORMAT_YAHOO_IT_HOME			@"http://it.finance.yahoo.com/valute/forex.html"
#define	FORMAT_YAHOO_ES_HOME			@"http://es.finance.yahoo.com/divisas/mercado.html"
#define	FORMAT_YAHOO_BR_HOME			@"http://br.finance.yahoo.com/moedas/mercado.html"
#define	FORMAT_YAHOO_SG_HOME			@"http://sg.finance.yahoo.com/currencies/investing.html"
#define	FORMAT_GOOGLE_HOME              @"http://www.google.com/finance"
#define	FORMAT_EXCHANGE_RATES_HOME		@"http://exchange-rates.org/"

#define	FORMAT_YAHOO_JP_FX				@"http://stocks.finance.yahoo.co.jp/stocks/detail/?code=%@#financeSearch"
#define	FORMAT_YAHOO_US_FX				@"http://finance.yahoo.com/q?s=%@=X#yfi_doc"
#define	FORMAT_YAHOO_UK_FX				@"http://uk.finance.yahoo.com/q?s=%@=X#yfi_doc"
//#define	FORMAT_YAHOO_AU_FX				@"http://au.finance.yahoo.com/q?s=%@=X#yfi_doc"
#define	FORMAT_YAHOO_AU_FX				@"http://au.finance.yahoo.com/q?s=%@%%3DX"
#define	FORMAT_YAHOO_DE_FX				@"http://de.finance.yahoo.com/q?s=%@=X#yfi_doc"
#define	FORMAT_YAHOO_FR_FX				@"http://fr.finance.yahoo.com/q?s=%@=X#yfi_doc"
#define	FORMAT_YAHOO_IT_FX				@"http://it.finance.yahoo.com/q?s=%@=X#yfi_doc"
#define	FORMAT_YAHOO_ES_FX				@"http://es.finance.yahoo.com/q?s=%@=X#yfi_doc"
#define	FORMAT_YAHOO_BR_FX				@"http://br.finance.yahoo.com/q?s=%@=X#yfi_doc"
#define	FORMAT_YAHOO_SG_FX				@"http://sg.finance.yahoo.com/q?s=%@=X#yfi_doc"
#define	FORMAT_GOOGLE_FINANCE           @"http://www.google.com/finance?q=%@"
#define	FORMAT_EXCHANGE_RATES           @"http://exchange-rates.org/converter/%@/%@/1"

#define	PREFIX_YAHOO_JP_STOCK			@"http://stocks.finance.yahoo.co.jp/stocks/detail/"
#define	PREFIX_YAHOO_US_STOCK			@"http://finance.yahoo.com/q?s="
#define	PREFIX_YAHOO_UK_STOCK			@"http://uk.finance.yahoo.com/q?s="
#define	PREFIX_YAHOO_AU_STOCK			@"http://au.finance.yahoo.com/q?s="
#define	PREFIX_YAHOO_DE_STOCK			@"http://de.finance.yahoo.com/q?s="
#define	PREFIX_YAHOO_FR_STOCK			@"http://fr.finance.yahoo.com/q?s="
#define	PREFIX_YAHOO_IT_STOCK			@"http://it.finance.yahoo.com/q?s="
#define	PREFIX_YAHOO_ES_STOCK			@"http://es.finance.yahoo.com/q?s="
#define	PREFIX_YAHOO_BR_STOCK			@"http://br.finance.yahoo.com/q?s="
#define	PREFIX_YAHOO_SG_STOCK			@"http://sg.finance.yahoo.com/q?s="
#define	PREFIX_GOOGLE_FINANCE			@"http://www.google.com/finance?q="
#define	PREFIX_EXCHANGE_RATES			@"http://exchange-rates.org/converter/"

#define	FILTER_YAHOO_JP_FROM1			@"<table class=\"stocksTable\" summary=\"株価詳細\">"
#define	FILTER_YAHOO_JP_FROM2			@"<td class=\"stoksPrice\">"
#define	FILTER_YAHOO_JP_TO1				@"</table>"
#define	FILTER_YAHOO_JP_TO2				@"</td>"
#define	FILTER_YAHOO_JP_FX_FROM1		@"<table class=\"stocksTable\" summary=\"株価詳細\">"

#define	FILTER_YAHOO_US_FROM1           @"<div class=\"yfi_rt_quote_summary\""
#define	FILTER_YAHOO_US_FROM2			@"<span id=\"yfs_l10_%@\">"
#define	FILTER_YAHOO_US_FROM2_FX		@"<span id=\"yfs_l10_%@=x\">"
#define	FILTER_YAHOO_US_TO1				@"<div id=\"yfi_headlines\" class=\"yfi_quote_headline\">"
#define	FILTER_YAHOO_US_TO2             @"</span></span>"
#define	FILTER_YAHOO_US_FROM1_PREV		@"<div id=\"yfi_investing_head\">"
#define	FILTER_YAHOO_US_TO2_PREV		@"</span></b>"
#define	FILTER_YAHOO_US_FROM1_DIFF      @":</th><td class=\"yfnc_tabledata1\">";
#define	FILTER_YAHOO_US_TO_DIFF         @"</td></tr>";

#define FILTER_YAHOO_MOBILE_FROM1       @"<span class=\"title\"><font color=\"\">%@=X</font></span><br/>"
#define FILTER_YAHOO_MOBILE_FROM2       @"<span class=\"title\"><font color=\"\"><b>"
#define FILTER_YAHOO_MOBILE_TO1         @"<font color=\"\">Open:</font>"
#define FILTER_YAHOO_MOBILE_TO2         @"</b></font>"
#define	FILTER_YAHOO_MOBILE_FROM1_DIFF  @"(<span><font color=\"\">";
#define	FILTER_YAHOO_MOBILE_TO_DIFF     @"</font></span>";

#define FILTER_GOOGLE_FROM1             @"data-last-normal-market-timestamp="
#define	FILTER_GOOGLE_FROM2				@"<span class=\"pr\">"
#define FILTER_GOOGLE_FROM2_FX          @"data-tz-offset="
#define	FILTER_GOOGLE_FROM3				@"_l\">"
#define FILTER_GOOGLE_FROM3_FX          @"<div class=\"YMlKec fxKbKc\">"
#define	FILTER_GOOGLE_TO1				@"<div class=mdata-dis>"
#define FILTER_GOOGLE_TO1_FX            @"https://www.google.com/"
#define FILTER_GOOGLE_TO2               @"</div>"

#define FILTER_GOOGLE_FROM1_DIFFR       @"data-last-price=\"";
#define FILTER_GOOGLE_FROM1_DIFFG       @"data-last-price=\"";
#define FILTER_GOOGLE_FROM2_DIFF        @"\" data-last-normal-market-timestamp=";

#define FILTER_EXCHANGE_RATE_FROM1      @"<div class=\"col-xs-6 result-cur2\">"
#define FILTER_EXCHANGE_RATE_FROM2      @"<span>"
#define FILTER_EXCHANGE_RATE_TO1        @"<small class=\"conversion-wide-note\">"
#define FILTER_EXCHANGE_RATE_TO2        @"</span>"

@interface webAccess : NSObject {
    NSURLConnection *urlConnection;
    NSMutableData   *connectionData;
    NSString        *connectionUrl;
    NSString        *urlContent;
    NSString        *targetCode;
    NSString        *strPrice;
    NSString        *serverSelection;
    CurrencyRate    *targetItem;
    bool             retrying;
}

- (void)startConnection:(NSString*)urlString;
- (void)fetchPrice:(NSString*)code;
- (int)scraipePrice;
- (NSString*)getCurrencyName:(NSString*)lang :(NSString*)code;
- (BOOL)cnnecting;

@property	(readwrite,retain)	CurrencyRate    *targetItem;
@property	(readwrite,copy)	NSString        *serverSelection;
@property	(readwrite)         bool             retrying;

@end

#endif
