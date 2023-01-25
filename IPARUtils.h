#import <CommonCrypto/CommonDigest.h>
#pragma clang diagnostic ignored "-Wunused-variable"
#define IPATOOL_SCRIPT_PATH @"/Applications/IPARanger.app/ipatool/ipatool"
#define IPARANGER_SETTINGS_DICT @"/var/mobile/Documents/IPARanger/com.0xkuj.iparangersettings.plist"

@interface NSTask : NSObject
@property (copy) NSArray * arguments; 
@property (retain) id standardOutput; 
@property (retain) id standardError; 
@property (readonly) int terminationStatus; 
-(void)waitUntilExit;
-(id)launchPath;
-(void)launch;
-(void)setLaunchPath:(id)arg1 ;
-(void)setStandardInput:(id)arg1 ;
@end

typedef void (^AlertActionBlock)(void);

@interface IPARUtils : NSObject
+ (NSDictionary<NSString*,NSArray*> *)setupTaskAndPipesWithCommand:(NSString *)command;
+ (void)presentErrorWithTitle:(NSString *)title message:(NSString *)message numberOfActions:(NSUInteger)numberOfActions buttonText:(NSString *)buttonText alertBlock:(AlertActionBlock)block presentOn:(id)viewController;
+ (NSString *)sha256ForFileAtPath:(NSString *)filePath;
@end
