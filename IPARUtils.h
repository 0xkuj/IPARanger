#import <CommonCrypto/CommonDigest.h>
#pragma clang diagnostic ignored "-Wunused-variable"
#define IPATOOL_SCRIPT_PATH @"/Applications/IPARanger.app/ipatool/ipatool"
#define APPINST_SCRIPT_PATH @"/Applications/IPARanger.app/ipatool/appinst"
#define IPARANGER_DOCUMENTS_LIBRARY @"/var/mobile/Documents/IPARanger/"
#define IPARANGER_SETTINGS_DICT @"/var/mobile/Documents/IPARanger/com.0xkuj.iparangersettings.plist"
#define kIPARCountryChangedNotification @"com.0xkuj.iparanger.countryChanged"

@interface NSTask : NSObject
@property (copy) NSArray * arguments; 
@property (retain) id standardOutput; 
@property (retain) id standardError; 
@property (readonly) int terminationStatus; 
@property (readonly) int processIdentifier;
-(void)waitUntilExit;
-(id)launchPath;
-(void)launch;
-(void)setLaunchPath:(id)arg1 ;
-(void)setStandardInput:(id)arg1 ;
@property(copy) NSString *currentDirectoryPath;
@end

typedef void (^AlertActionBlock)(void);

@interface IPARUtils : NSObject
+ (NSDictionary<NSString*,NSArray*> *)setupTaskAndPipesWithCommand:(NSString *)command;
+ (void)presentMessageWithTitle:(NSString *)title message:(NSString *)message numberOfActions:(NSUInteger)numberOfActions buttonText:(NSString *)buttonText alertConfirmationBlock:(AlertActionBlock)confirmationBlock alertCancelBlock:(AlertActionBlock)cancelBlock presentOn:(id)viewController;
+ (NSString *)sha256ForFileAtPath:(NSString *)filePath;
+ (void)loginToFile:(NSString *)userEmail authNameFromOutput:(NSString *)authNameFromOutput;
+ (void)logoutToFile;
+ (void)cancelScript;
+ (NSString *)emojiFlagForISOCountryCode:(NSString *)countryCode;
+ (void)downloadCountryToFile:(NSString *)accountCountry;
+ (NSString *)getMostUpdatedDownloadCountryFromFile;
+ (void)searchCountryToFile:(NSString *)accountCountry;
+ (NSString *)getMostUpdatedSearchCountryFromFile;
+ (UIImage *)getAppIconFromApple:(NSString *)bundleId;
+ (NSString *)humanReadableSizeForBytes:(long long)bytes;
+ (void)setupUnzipTask:(NSString *)ipaFilePath directoryPath:(NSString *)directoryPath file:(NSString *)fileToUnzip;
+ (NSString *)getMostUpdateLoginDate;
@end

