//
//  Currency.h
//  SyntheForex
//
//  Created by 佐山 隆裕 on 11/12/28.
//  Copyright (c) 2011年 tanuki-project. All rights reserved.
//

#ifndef SyntheForex_currency_h
#define SyntheForex_currency_h

#import     <Foundation/Foundation.h>

#define CURRANCY_FORMAT_DOT         0
#define CURRANCY_FORMAT_COMMA       1

#define LANG_DE_DE          @"de_DE"
#define LANG_EN_US          @"en_US"
#define LANG_ES_ES          @"es_ES"
#define LANG_ES_MX          @"es_MX"
#define LANG_FR_FR          @"fr_FR"
#define LANG_FR_CA          @"fr_CA"
#define LANG_IT_IT          @"it_IT"
#define LANG_JA_JP          @"ja_JP"
#define LANG_PT_PT          @"pt_PT"
#define LANG_PT_BR          @"pt_BR"

#define CURRENCY_AE         @"AED"  // UAE Dirham
#define CURRENCY_AR         @"ARS"  // Argentine Peso
#define CURRENCY_AU         @"AUD"  // Australian Dollar
#define CURRENCY_BH         @"BHD"  // Bahraini Dinar
#define CURRENCY_BR         @"BRL"  // Brazilian Real
#define CURRENCY_CA         @"CAD"  // Canadian Dollar
#define CURRENCY_CH         @"CHF"  // Swiss Franc
#define CURRENCY_CL         @"CLP"  // Chilean Peso
#define CURRENCY_CN         @"CNY"  // Chinese Yuan
#define CURRENCY_CO         @"COP"  // Colombian Peso
#define CURRENCY_CZ         @"CZK"  // Czech Koruna
#define CURRENCY_DK         @"DKK"  // Danish Krone
#define CURRENCY_EG         @"EGP"  // Egyptian Pound
#define CURRENCY_EU         @"EUR"  // Euro
#define CURRENCY_UK         @"GBP"  // British Pound
#define CURRENCY_HK         @"HKD"  // Hong Kong Dollar
#define CURRENCY_HU         @"HUF"  // Hungarian Forint
#define CURRENCY_ID         @"IDR"  // Indonesian Rupiah
#define CURRENCY_IL         @"ILS"  // Israeli Shekel
#define CURRENCY_IN         @"INR"  // Indian Rupee
#define CURRENCY_JP         @"JPY"  // Japanese Yen
#define CURRENCY_KR         @"KRW"  // South Korean Won
#define CURRENCY_MX         @"MXN"  // Mexican Peso
#define CURRENCY_MY         @"MYR"  // Malaysian Ringgit
#define CURRENCY_NO         @"NOK"  // Norwegian Krone
#define CURRENCY_NZ         @"NZD"  // New Zealand Dollar 
#define CURRENCY_PE         @"PEN"  // Peruvian Nuevo Sol
#define CURRENCY_PH         @"PHP"  // Philippine Peso
#define CURRENCY_PL         @"PLN"  // Polish Zloty
#define CURRENCY_QA         @"QAR"  // Qatar Rial
#define CURRENCY_RO         @"RON"  // Romanian New Leu
#define CURRENCY_RU         @"RUB"  // Russian Rouble
#define CURRENCY_SA         @"SAR"  // Saudi Arabian Riyal
#define CURRENCY_SE         @"SEK"  // Swedish Krona
#define CURRENCY_SG         @"SGD"  // Singapore Dollar
#define CURRENCY_TH         @"THB"  // Thai Baht
#define CURRENCY_TR         @"TRY"  // Turkish Lira
#define CURRENCY_TW         @"TWD"  // Taiwan Dollar
#define CURRENCY_US         @"USD"  // United States Dollar
#define CURRENCY_VN         @"VND"  // Vietnam Dong
#define CURRENCY_ZA         @"ZAR"  // South African Rand


@interface CurrencyName : NSObject {
    NSString    *lang;
    NSString    *name;
}

@property	(readwrite,copy)	NSString        *lang;
@property	(readwrite,copy)	NSString        *name;

@end

@interface Currency : NSObject {
    NSString        *code;
    NSString        *symble;
    NSMutableArray  *langs;
}

- (void)addLang:(NSString*)lang :(NSString*)name;
- (NSString*)getLocalName:(NSString*)lang;

@property	(readwrite,copy)	NSString        *code;
@property	(readwrite,copy)	NSString        *symble;
@property	(readwrite,retain)	NSMutableArray  *langs;

@end


@interface CurrencyRate : NSObject {
    int         index;
    NSString    *targetCode;
    NSString    *againstCode;
    NSString    *strRate;
    NSString    *strDiffer;
    NSDate      *date;
    double      doubleRate;
    double      lastRate;
    double      prevClose;
    double      differ;
    bool        enable;
    bool        prevCloseUpdated;
}

@property	(readwrite)         int             index;
@property	(readwrite,copy)	NSString        *targetCode;
@property	(readwrite,copy)	NSString        *againstCode;
@property	(readwrite,copy)	NSString        *strRate;
@property	(readwrite,copy)    NSDate          *date;
@property	(readwrite)         double          doubleRate;
@property	(readwrite)         double          lastRate;
@property	(readwrite,copy)	NSString        *strDiffer;
@property	(readwrite)         double          prevClose;
@property	(readwrite)         double          differ;
@property	(readwrite)         bool            enable;
@property	(readwrite)         bool            prevCloseUpdated;

@end

#endif
