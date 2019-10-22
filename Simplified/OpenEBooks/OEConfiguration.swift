class OEConfiguration {
  static let NYPLCirculationBaseURLProduction = "https://circulation.openebooks.us"
  static let NYPLCirculationBaseURLTesting = "http://qa.circulation.openebooks.us"
  
  
}
//
//#import "NYPLSettings.h"
//#import "Bugsnag.h"
//#import "HSHelpStack.h"
//#import "HSZenDeskGear.h"
//
//#if defined(FEATURE_DRM_CONNECTOR)
//#import <ADEPT/ADEPT.h>
//#endif
//
//#import "NYPLConfiguration.h"
//#import "UILabel+NYPLAppearanceAdditions.h"
//#import "UIButton+NYPLAppearanceAdditions.h"
//
//static NSString *const NYPLCirculationBaseURLProduction = @"https://circulation.openebooks.us";
//static NSString *const NYPLCirculationBaseURLTesting = @"http://qa.circulation.openebooks.us";
//
//@implementation NYPLConfiguration
//
//+ (void)initialize
//{
//  [[HSHelpStack instance] setThemeFrompList:@"HelpStackTheme"];
//  HSZenDeskGear *zenDeskGear  = [[HSZenDeskGear alloc]
//                                 initWithInstanceUrl : @"https://openebooks.zendesk.com"
//                                 staffEmailAddress   : @"jamesenglish@nypl.org"
//                                 apiToken            : @"mgNmqzUFmNoj9oTBmDdtDVGYdm1l0HqWgZIZlQcN"];
//
//  HSHelpStack *helpStack = [HSHelpStack instance];
//  helpStack.gear = zenDeskGear;
//
//  [self configureCrashAnalytics];
//
//#if defined(FEATURE_DRM_CONNECTOR)
//  [[NYPLADEPT sharedInstance] setLogCallback:^(__unused NSString *logLevel,
//                                               NSString *const exceptionName,
//                                               __unused NSDictionary *data,
//                                               NSString *const message) {
//    NSLog(@"ADEPT: %@: %@", exceptionName, message);
//  }];
//#endif
//}
//
//+ (void)configureCrashAnalytics
//{
//  if (!TARGET_OS_SIMULATOR) {
//
//    BugsnagConfiguration *config = [BugsnagConfiguration new];
//    config.apiKey = [self bugsnagID];
//
//    if ([self bugsnagEnabled]) {
//      [Bugsnag startBugsnagWithConfiguration:config];
//    }
//  }
//}
//
//+ (BOOL)releaseStageIsBeta
//{
//  NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
//  return ([[receiptURL path] rangeOfString:@"sandboxReceipt"].location != NSNotFound);
//}
//
//+ (BOOL) bugsnagEnabled
//{
//  return YES;
//}
//
//+ (NSString *) bugsnagID
//{
//  return @"cde99c9c1f9d2b3db1d9217f27794191";
//}
//
//+ (NSURL *)circulationURL
//{
////    return [NSURL URLWithString:NYPLCirculationBaseURLTesting];
//  return [NSURL URLWithString:NYPLCirculationBaseURLProduction];
//}
//
//+ (NSURL *)mainFeedURL
//{
//    NSURL *const customURL = [NYPLSettings sharedSettings].customMainFeedURL;
//
//    if(customURL) return customURL;
//
//    return [self circulationURL];
//}
//
//+ (BOOL)customFeedEnabled
//{
//  return NO;
//}
//
//+ (BOOL)preloadedContentEnabled
//{
//  return NO;
//}
//
//+ (NSURL *)tokenURL
//{
//  return [[self circulationURL] URLByAppendingPathComponent:@"AdobeAuth/authdata"];
//}
//
//+ (NSURL *)loanURL
//{
//    return [[self circulationURL] URLByAppendingPathComponent:@"loans"];
//}
//
//+ (BOOL)cardCreationEnabled
//{
//  return NO;
//}
//
//+ (NSURL *)registrationURL
//{
////  return [NSURL URLWithString:@"https://simplifiedcard.herokuapp.com"];
//  return [NSURL URLWithString:@"https://patrons.librarysimplified.org/"];
//}
//
//+ (NSURL *)openEBooksRequestCodesURL
//{
//  return [NSURL URLWithString:@"http://openebooks.net/getstarted.html"];
//}
//
//+ (UIColor *)mainColor
//{
//  return [UIColor colorWithRed:141/255.0 green:198/255.0 blue:63/255.0 alpha:1.0];
//}
//
//+ (UIColor *)accentColor
//{
//  return [UIColor colorWithRed:0.0/255.0 green:144/255.0 blue:196/255.0 alpha:1.0];
//}
//
//+ (UIColor *)backgroundColor
//{
//  return [UIColor colorWithWhite:250/255.0 alpha:1.0];
//}
//
//+ (UIColor *)backgroundDarkColor
//{
//  return [UIColor colorWithWhite:5/255.0 alpha:1.0];
//}
//
//+ (UIColor *)backgroundSepiaColor
//{
//  return [UIColor colorWithRed:242/255.0 green:228/255.0 blue:203/255.0 alpha:1.0];
//}
//
//+(UIColor *)backgroundMediaOverlayHighlightColor {
//  return [UIColor yellowColor];
//}
//
//+(UIColor *)backgroundMediaOverlayHighlightDarkColor {
//  return [UIColor orangeColor];
//}
//
//+(UIColor *)backgroundMediaOverlayHighlightSepiaColor {
//  return [UIColor yellowColor];
//}
//
//// Set for the whole app via UIView+NYPLFontAdditions.
//+ (NSString *)systemFontName
//{
//  return @"AvenirNext-Medium";
//}
//
//// Set for the whole app via UIView+NYPLFontAdditions.
//+ (NSString *)boldSystemFontName
//{
//  return @"AvenirNext-Bold";
//}
//
//@end
