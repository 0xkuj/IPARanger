#import <CommonCrypto/CommonDigest.h>
#pragma clang diagnostic ignored "-Wunused-variable"

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
+ (void)setupUnzipTask:(NSString *)ipaFilePath directoryPath:(NSString *)directoryPath file:(NSString *)fileToUnzip;
+ (NSString *)sha256ForFileAtPath:(NSString *)filePath;
+ (NSString *)getKeyFromFile:(NSString *)key defaultValueIfNil:(NSString *)defaultValue;
+ (void)saveKeyToFile:(NSString *)key withValue:(NSString *)value;
+ (void)accountDetailsToFile:(NSString *)userEmail authName:(NSString *)authName authenticated:(NSString *)authenticated;
+ (NSString *)emojiFlagForISOCountryCode:(NSString *)countryCode;
+ (UIImage *)getAppIconFromApple:(NSString *)bundleId;
+ (NSString *)humanReadableSizeForBytes:(long long)bytes;
+ (void)presentMessageWithTitle:(NSString *)title 
                        message:(NSString *)message 
                        numberOfActions:(NSUInteger)numberOfActions 
                        buttonText:(NSString *)buttonText 
                        alertConfirmationBlock:(AlertActionBlock)confirmationBlock 
                        alertCancelBlock:(AlertActionBlock)cancelBlock 
                        presentOn:(id)viewController;
+ (void)cancelScript;
@end

