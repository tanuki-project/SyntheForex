//
//  PreferenceController.m
//  SyntheForex
//
//  Created by 佐山 隆裕 on 11/12/31.
//  Copyright (c) 2011年 tanuki-project. All rights reserved.
//

#import     "PreferenceController.h"
#include    "AppDelegate.h"
#include    "build.h"

extern AppDelegate  *syntheTickerDelegate;

extern bool         autoStartupSpeech;
extern bool         skipSpeechUnchanged;
extern bool         sortSubPanel;
extern bool         showRelativeDate;
extern NSString		*serverSelection;
extern double       digitThreshold;
extern double       alarmThreshold;
extern long         formatDisplay;
extern long         formatSpeech;

extern NSString     *autoStartupSpeechKey;
extern NSString     *skipSpeechUnchangedKey;
extern NSString     *sortSubPanelKey;
extern NSString     *showRelativeDateKey;
extern NSString     *serverSelectionKey;
extern NSString     *digitThresholdKey;
extern NSString     *alarmThresholdKey;
extern NSString     *formatSpeechKey;
extern NSString     *formatDisplayKey;

@implementation PreferenceController

- (id)init
{
    self = [super initWithWindowNibName:@"Preference"];
    return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)windowDidLoad
{
    NSLog(@"windowDidLoad");
    [preferenceWindow setTitle:@"Preference"];
    [self localizeView];
    [serverComboBox addItemWithObjectValue:SERVER_NAME_GOOGLE];
//    [serverComboBox addItemWithObjectValue:SERVER_NAME_YAHOO_AU];
//    [serverComboBox addItemWithObjectValue:SERVER_NAME_YAHOO_BR];
//    [serverComboBox addItemWithObjectValue:SERVER_NAME_YAHOO_DE];
//    [serverComboBox addItemWithObjectValue:SERVER_NAME_YAHOO_ES];
//    [serverComboBox addItemWithObjectValue:SERVER_NAME_YAHOO_FR];
//    [serverComboBox addItemWithObjectValue:SERVER_NAME_YAHOO_IT];
    [serverComboBox addItemWithObjectValue:SERVER_NAME_YAHOO_JP];
//    [serverComboBox addItemWithObjectValue:SERVER_NAME_YAHOO_SG];
//    [serverComboBox addItemWithObjectValue:SERVER_NAME_YAHOO_UK];
//    [serverComboBox addItemWithObjectValue:SERVER_NAME_YAHOO_US];
    [serverComboBox addItemWithObjectValue:SERVER_NAME_EXCHANGE_RATES];
    if (serverSelection) {
        //[serverComboBox setTitleWithMnemonic:serverSelection];
        [serverComboBox selectItemWithObjectValue:serverSelection];
    } else {
        //[serverComboBox setTitleWithMnemonic:SERVER_NAME_YAHOO_US];
        [serverComboBox selectItemWithObjectValue:SERVER_NAME_YAHOO_US];
    }
    if (digitThreshold == DETAILED_DIGIT_THRESHOLD) {
        [digitSegmentControl setSelectedSegment:1];
    } else if (digitThreshold == UNLIMITED_DIGIT_THRESHOLD) {
        [digitSegmentControl setSelectedSegment:2];
    } else {
        [digitSegmentControl setSelectedSegment:0];
    }
    if (alarmThreshold == ALARM_THRESHOLD_MIN) {
        [alarmSegmentControl setSelectedSegment:1];
    } else if (alarmThreshold == ALARM_THRESHOLD_MID) {
        [alarmSegmentControl setSelectedSegment:2];
    } else if (alarmThreshold == ALARM_THRESHOLD_MAX) {
        [alarmSegmentControl setSelectedSegment:3];
    } else {
        [alarmSegmentControl setSelectedSegment:0];
    }
    [checkAutoStartup setState:autoStartupSpeech];
    [checkSkipSpeech setState:skipSpeechUnchanged];
    [checkSortSubPanel setState:sortSubPanel];
    [checkRelativeDate setState:showRelativeDate];
    if (formatSpeech == CURRANCY_FORMAT_DOT) {
        [radioFormatSpeech selectCellAtRow:0 column:0];
    } else {
        [radioFormatSpeech selectCellAtRow:0 column:1];
    }
    if (formatDisplay == CURRANCY_FORMAT_DOT) {
        [radioFormatDisplay selectCellAtRow:0 column:0];
        [alarmSegmentControl setLabel:@"0.1%" forSegment:1];
        [alarmSegmentControl setLabel:@"0.2%" forSegment:2];
        [alarmSegmentControl setLabel:@"0.5%" forSegment:3];
    } else {
        [radioFormatDisplay selectCellAtRow:0 column:1];
        [alarmSegmentControl setLabel:@"0,1%" forSegment:1];
        [alarmSegmentControl setLabel:@"0,2%" forSegment:2];
        [alarmSegmentControl setLabel:@"0,5%" forSegment:3];
    }
}

- (IBAction)selectServer:(id)sender {
    NSLog(@"selectServer: %@", [serverComboBox stringValue]);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[serverComboBox stringValue] forKey:serverSelectionKey];
	serverSelection = [defaults objectForKey:serverSelectionKey];
    NSLog(@"serverSelection = %@", serverSelection);
    [[syntheTickerDelegate webConnection] setServerSelection:serverSelection];
    [syntheTickerDelegate setServerMenu];
}

- (IBAction)selectDigitSegment:(id)sender {
    long index = [digitSegmentControl selectedSegment];
    NSLog(@"selectDigitSegment: %lu", index);
    switch (index) {
        case 1:
            digitThreshold = DETAILED_DIGIT_THRESHOLD;
            break;
        case 2:
            digitThreshold = UNLIMITED_DIGIT_THRESHOLD;
            break;
        default:
            digitThreshold = DEFAULT_DIGIT_THRESHOLD;
            break;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setDouble: digitThreshold forKey:digitThresholdKey];
}

- (IBAction)selectAlarmSegment:(id)sender {
    long index = [alarmSegmentControl selectedSegment];
    NSLog(@"selectAlarmSegment: %lu", index);
    switch (index) {
        case 1:
            alarmThreshold = ALARM_THRESHOLD_MIN;
            break;
        case 2:
            alarmThreshold = ALARM_THRESHOLD_MID;
            break;
        case 3:
            alarmThreshold = ALARM_THRESHOLD_MAX;
            break;
        default:
            alarmThreshold = DEFAULT_ALARM_THRESHOLD;
            break;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setDouble: alarmThreshold forKey:alarmThresholdKey];
}

- (IBAction)setAutoStartup:(id)sender {
    long value = [checkAutoStartup state];
    autoStartupSpeech = value;
    NSLog(@"setAutoStartup %lu", value);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:value forKey:autoStartupSpeechKey];
}

- (IBAction)setSkipUnchanged:(id)sender {
    long value = [checkSkipSpeech state];
    skipSpeechUnchanged = value;
    NSLog(@"skipSpeechUnchanged %lu", value);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:value forKey:skipSpeechUnchangedKey];
}

- (IBAction)setSortSubPanel:(id)sender {
    long value = [checkSortSubPanel state];
    sortSubPanel = value;
    NSLog(@"sortSubPanel %lu", value);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:value forKey:sortSubPanelKey];
    [syntheTickerDelegate refreshPanel];
    if (sortSubPanel == YES) {
        [[syntheTickerDelegate iPanel] sortItems];
    }
}

- (IBAction)setShowRelativeDate:(id)sender{
    long value = [checkRelativeDate state];
    showRelativeDate = value;
    NSLog(@"showRelateveDate %lu", value);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:value forKey:showRelativeDateKey];
    [[syntheTickerDelegate dateFormatter] setDoesRelativeDateFormatting:showRelativeDate];
    [[syntheTickerDelegate tableView] reloadData];
}

- (IBAction)selectFormatSpeech:(id)sender {
    long column = [radioFormatSpeech selectedColumn];
    NSLog(@"selectFormatSpeech %lu", column);
    if (column == 0) {
        formatSpeech = CURRANCY_FORMAT_DOT;
    } else {
        formatSpeech = CURRANCY_FORMAT_COMMA;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:formatSpeech forKey:formatSpeechKey];
}

- (IBAction)selectFormatDisplay:(id)sender {
    long column = [radioFormatDisplay selectedColumn];
    NSLog(@"selectFormatDisplay %lu", column);
    if (column == 0) {
        formatDisplay = CURRANCY_FORMAT_DOT;
        [alarmSegmentControl setLabel:@"0.1%" forSegment:1];
        [alarmSegmentControl setLabel:@"0.2%" forSegment:2];
        [alarmSegmentControl setLabel:@"0.5%" forSegment:3];
    } else {
        formatDisplay = CURRANCY_FORMAT_COMMA;
        [alarmSegmentControl setLabel:@"0,1%" forSegment:1];
        [alarmSegmentControl setLabel:@"0,2%" forSegment:2];
        [alarmSegmentControl setLabel:@"0,5%" forSegment:3];
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:formatDisplay forKey:formatDisplayKey];
    for (CurrencyRate* item in [syntheTickerDelegate currencyRates]) {
        NSString    *work;
        if (formatDisplay == CURRANCY_FORMAT_DOT) {
            if (digitThreshold == UNLIMITED_DIGIT_THRESHOLD || [item doubleRate] < digitThreshold) {
                if ([[item againstCode] isEqualToString:CURRENCY_SA] == YES ||
                    [[item againstCode] isEqualToString:CURRENCY_EG]) {
                    work = [[NSString alloc] initWithFormat:@"%0.4f%@",
                            [item doubleRate],
                            [syntheTickerDelegate getCurrencySymble:[item againstCode]]];
                } else {
                    work = [[NSString alloc] initWithFormat:@"%@%0.4f",
                            [syntheTickerDelegate getCurrencySymble:[item againstCode]],
                            [item doubleRate]];
                }
            } else {
                if ([[item againstCode] isEqualToString:CURRENCY_SA] == YES ||
                    [[item againstCode] isEqualToString:CURRENCY_EG]) {
                    work = [[NSString alloc] initWithFormat:@"%0.2f%@",
                            [item doubleRate], 
                            [syntheTickerDelegate getCurrencySymble:[item againstCode]]];
                } else {
                    work = [[NSString alloc] initWithFormat:@"%@%0.2f",
                            [syntheTickerDelegate getCurrencySymble:[item againstCode]],
                            [item doubleRate]];
                }
            }
            [item setStrRate:[work autorelease]];
            work = [[item strDiffer] stringByReplacingOccurrencesOfString:@"," withString:@"."];
            [item setStrDiffer:work];
        } else {
            if (digitThreshold == UNLIMITED_DIGIT_THRESHOLD || [item doubleRate] < digitThreshold) {
                if ([[item againstCode] isEqualToString:CURRENCY_SA] == YES ||
                    [[item againstCode] isEqualToString:CURRENCY_EG]) {
                    work = [[NSString alloc] initWithFormat:@"%@ %0.4f",
                            [syntheTickerDelegate getCurrencySymble:[item againstCode]],
                            [item doubleRate]];
                } else {
                    work = [[NSString alloc] initWithFormat:@"%0.4f %@",
                            [item doubleRate],
                            [syntheTickerDelegate getCurrencySymble:[item againstCode]]];
                }
            } else {
                if ([[item againstCode] isEqualToString:CURRENCY_SA] == YES ||
                    [[item againstCode] isEqualToString:CURRENCY_EG]) {
                    work = [[NSString alloc] initWithFormat:@"%@ %0.2f",
                            [syntheTickerDelegate getCurrencySymble:[item againstCode]],
                            [item doubleRate]];
                } else {
                    work = [[NSString alloc] initWithFormat:@"%0.2f %@",
                            [item doubleRate],
                            [syntheTickerDelegate getCurrencySymble:[item againstCode]]];
                }
            }
            [item setStrRate:[[work autorelease] stringByReplacingOccurrencesOfString:@"." withString:@","]];
            work = [[item strDiffer] stringByReplacingOccurrencesOfString:@"." withString:@","];
            [item setStrDiffer:work];
        }
    }
    [syntheTickerDelegate saveCurrencyRates];
    [[syntheTickerDelegate iPanel] setDisplayFormatter];    
    [[syntheTickerDelegate iPanel] rearrangePanel];    
}

#pragma mark Localizer

- (void) localizeView
{
	NSString* lang = NSLocalizedString(@"LANG",@"English");
	NSLog(@"localizeView: %@", lang);
	if ([lang isEqualToString:@"Japanese"]) {
        NSLog(@"LANG: %@", lang);
        [preferenceWindow setTitle:@"環境設定"];
        [checkAutoStartup setTitle:@"起動時にスピーチを開始する"];
        [checkSkipSpeech setTitle:@"変更がない場合にスピーチをスキップ"];
        [checkSortSubPanel setTitle:@"サブパネルの項目を騰落率でソート"];
        [checkRelativeDate setTitle:@"日付を相対的に表示する"];
        [labelFourDigit setStringValue:@"小数点以下4桁を表示"];
        [labelAlarm setStringValue:@"アラームのしきい値"];
        [labelSelectServer setStringValue:@"接続先サーバの選択"];
        [labelNote setStringValue:@"為替レートの値やディレイ、レスポンス時間はサーバによって異なります."];
        [labelFormatDisplay setStringValue:@"数値の表示形式"];
        [labelFormatSpeech setStringValue:@"スピーチ時の数値の形式"];
        [digitSegmentControl setLabel:@"0 〜 2" forSegment:0];
        [digitSegmentControl setLabel:@"0 〜 10" forSegment:1];
        [digitSegmentControl setLabel:@"全て" forSegment:2];
    } else if ([lang isEqualToString:@"German"]) {
        NSLog(@"LANG: %@", lang);
        [preferenceWindow setTitle:@"Einstellungen"];
        [checkAutoStartup setTitle:@"Auto Start nach Gestartet"];
        [checkSkipSpeech setTitle:@"Überspringen Sprache wenn Unverändert"];
        [checkSortSubPanel setTitle:@"Sortieren von Elementen der Sub-Panel von Ratio"];
        [checkRelativeDate setTitle:@"Relatives Datum anzeigen"];
        [labelFourDigit setStringValue:@"Vierstellige Dezimalzahl Rate"];
        [labelAlarm setStringValue:@"Schwellenwert für Alarm"];
        [labelSelectServer setStringValue:@"Wählen Finanzielle Server"];
        [labelNoteTag setStringValue:@"Beachten:"];
        [labelNote setStringValue:@"Delay und Reaktionszeit des Wechselkurses sind unterschiedlich in den einzelnen Servern."];
        [labelFormatDisplay setStringValue:@"Numeric Format für Anzeige"];
        [labelFormatSpeech setStringValue:@"Numeric Format für Sprache"];
        [digitSegmentControl setLabel:@"0 bis 2" forSegment:0];
        [digitSegmentControl setLabel:@"0 bis 10" forSegment:1];
        [digitSegmentControl setLabel:@"Alle" forSegment:2];
        [alarmSegmentControl setLabel:@"Keiner" forSegment:0];
    } else if ([lang isEqualToString:@"French"]) {
        NSLog(@"LANG: %@", lang);
        [preferenceWindow setTitle:@"Préférences"];
        [checkAutoStartup setTitle:@"Démarrage Automatique après Lancée"];
        [checkSkipSpeech setTitle:@"Skip Parole quand Inchangée"];
        [checkSortSubPanel setTitle:@"Trier les éléments de Sous-Panneau par Rapport"];
        [checkRelativeDate setTitle:@"Afficher la date relative"];
        [labelFourDigit setStringValue:@"Quatre Chiffres Décimaux Taux"];
        [labelAlarm setStringValue:@"Seuil de pour Alarme"];
        [labelSelectServer setStringValue:@"Sélectionnez le Serveur Financiers"];
        [labelNoteTag setStringValue:@"Remarque:"];
        [labelNote setStringValue:@"Temps de retard et la réponse du taux de change sont différents dans chaque serveur."];
        [labelFormatDisplay setStringValue:@"Format numérique pour les Afficher"];
        [labelFormatSpeech setStringValue:@"Format numérique pour les Parole"];
        [digitSegmentControl setLabel:@"0 à 2" forSegment:0];
        [digitSegmentControl setLabel:@"0 à 10" forSegment:1];
        [digitSegmentControl setLabel:@"tous les" forSegment:2];
        [alarmSegmentControl setLabel:@"Aucune" forSegment:0];
    } else if ([lang isEqualToString:@"Italian"]) {
        NSLog(@"LANG: %@", lang);
        [preferenceWindow setTitle:@"Preferenza"];
        [checkAutoStartup setTitle:@"Avvio automatico dopo Lanciato"];
        [checkSkipSpeech setTitle:@"Passa Parlato quando Invariata"];
        [checkSortSubPanel setTitle:@"Ordinare gli Elementi del Pannello Sub di Rapporto"];
        [checkRelativeDate setTitle:@"Mostra data relativa"];
        [labelFourDigit setStringValue:@"Quattro Cifre Decimali Tasso"];
        [labelAlarm setStringValue:@"Soglia di Allarme"];
        [labelSelectServer setStringValue:@"Seleziona Financeal Server"];
        [labelNoteTag setStringValue:@"Nota:"];
        [labelNote setStringValue:@"Tempo di ritardo e la risposta del tasso di cambio sono diversi in ogni server."];
        [labelFormatDisplay setStringValue:@"Formato Numerico per Display"];
        [labelFormatSpeech setStringValue:@"Formato numerico per Parlato"];
        [digitSegmentControl setLabel:@"0 - 2" forSegment:0];
        [digitSegmentControl setLabel:@"0 - 10" forSegment:1];
        [digitSegmentControl setLabel:@"tutti" forSegment:2];
        [alarmSegmentControl setLabel:@"Nessuna" forSegment:0];
    } else if ([lang isEqualToString:@"Spanish"]) {
        NSLog(@"LANG: %@", lang);
        [preferenceWindow setTitle:@"Preferencias"];
        [checkAutoStartup setTitle:@"Auto de Inicio después de la Lanzada"];
        [checkSkipSpeech setTitle:@"Skip Habla cuando sin cambios"];
        [checkSortSubPanel setTitle:@"Ordenar los Elementos del Subpanel de Relación"];
        [checkRelativeDate setTitle:@"Mostrar Fecha relativa"];
        [labelFourDigit setStringValue:@"De Duatro Dígitos Decimales Tasa"];
        [labelAlarm setStringValue:@"Umbral de Alarma"];
        [labelSelectServer setStringValue:@"Seleccione Financeal Servidor"];
        [labelNoteTag setStringValue:@"Nota:"];
        [labelNote setStringValue:@"Demora y el tiempo de respuesta de tipo de cambio son diferentes en cada servidor."];
        [labelFormatDisplay setStringValue:@"Formato Numérico para el Mostrar"];
        [labelFormatSpeech setStringValue:@"Formato Numérico para el Habla"];
        [digitSegmentControl setLabel:@"0 a 2" forSegment:0];
        [digitSegmentControl setLabel:@"0 a 10" forSegment:1];
        [digitSegmentControl setLabel:@"todos" forSegment:2];
        [alarmSegmentControl setLabel:@"Ninguno" forSegment:0];
    } else if ([lang isEqualToString:@"Portuguese"]) {
        NSLog(@"LANG: %@", lang);
        [preferenceWindow setTitle:@"Preferências"];
        [checkAutoStartup setTitle:@"Startup Auto Lançado após"];
        [checkSkipSpeech setTitle:@"Skip Fala quando Inalterada"];
        [checkSortSubPanel setTitle:@"Ordenar os Itens de Sub Painel de Proporção"];
        [checkRelativeDate setTitle:@"Mostrar Data relativa"];
        [labelFourDigit setStringValue:@"Quatro Dígitos Taxa Decimal"];
        [labelAlarm setStringValue:@"Limiar para Alarme"];
        [labelSelectServer setStringValue:@"Selecione Financeal Servidor"];
        [labelNoteTag setStringValue:@"Nota:"];
        [labelNote setStringValue:@"Atraso e tempo de resposta da taxa de câmbio são diferentes em cada servidor."];
        [labelFormatDisplay setStringValue:@"Formato Numérico para Mostrar"];
        [labelFormatSpeech setStringValue:@"Formato numérico para Fala"];
        [digitSegmentControl setLabel:@"0 - 2" forSegment:0];
        [digitSegmentControl setLabel:@"0 - 10" forSegment:1];
        [digitSegmentControl setLabel:@"todos" forSegment:2];
        [alarmSegmentControl setLabel:@"Nenhum" forSegment:0];
    }
    /* in English
        NSLog(@"LANG: %@", lang);
        [preferenceWindow setTitle:@"Preference"];
        [checkAutoStartup setTitle:@"Auto Startup after Launched"];
        [checkSkipSpeech setTitle:@"Skip Speech when Unchanged"];
        [checkRelativeDate setTitle:@"Show Relative Date"];
        [labelFourDigit setStringValue:@"Four-Digit Decimal Rate"];
        [labelAlarm setStringValue:@"Threshold for Alarm"];
        [labelSelectServer setStringValue:@"Select Financeal Server"];
        [labelNoteTag setStringValue:@"Note:"];
        [labelNote setStringValue:@"Delay and response time of currency exchange rate are different in each server."];
        [labelFormatDisplay setStringValue:@"Numeric Format for Display"];
        [labelFormatSpeech setStringValue:@"Numeric Format for Speech"];
        [digitSegmentControl setLabel:@"0 to 2" forSegment:0];
        [digitSegmentControl setLabel:@"0 to 10" forSegment:1];
        [digitSegmentControl setLabel:@"all" forSegment:2];
        [alarmSegmentControl setLabel:@"None" forSegment:0];
     */
}

@synthesize     serverComboBox;

@end
