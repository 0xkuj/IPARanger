#import "IPARUtils.h"
#include <spawn.h>
#include <signal.h>

// global variable to store the pid of the spawned process
int spawnedProcessPid;

@implementation IPARUtils
+ (NSString *)sha256ForFileAtPath:(NSString *)filePath {
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    if (handle == nil) {
        NSLog(@"File %@ not found", filePath);
        return nil;
    }

    CC_SHA256_CTX sha256;
    CC_SHA256_Init(&sha256);

    BOOL done = NO;
    while (!done) {
        NSData *fileData = [handle readDataOfLength:256];
        CC_SHA256_Update(&sha256, [fileData bytes], (CC_LONG)[fileData length]);
        if ([fileData length] == 0) {
            done = YES;
        }
    }

    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(digest, &sha256);

    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];

    for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];

    return output;
}

+ (void)presentMessageWithTitle:(NSString *)title 
                      message:(NSString *)message 
                      numberOfActions:(NSUInteger)numberOfActions 
                      buttonText:(NSString *)buttonText 
                      alertBlock:(AlertActionBlock)block 
                      presentOn:(id)viewController {

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:buttonText style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (block != nil) {
            block();
        }
    }];
    [alert addAction:okAction];
    if (numberOfActions > 1) {
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancelAction];
    }

    [viewController presentViewController:alert animated:YES completion:nil];
}

+ (NSDictionary<NSString*,NSArray*> *)setupTaskAndPipesWithCommand:(NSString *)command {
    NSLog(@"omriku running command.. %@", command);
    NSTask *task = [[NSTask alloc] init];
    NSMutableArray *args = [NSMutableArray array];
    [args addObject:@"-c"];
    [args addObject:command];
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:args];
    NSPipe *outputPipe = [NSPipe pipe];
    NSPipe *errorPipe = [NSPipe pipe];
    [task setStandardError:errorPipe];
    [task setStandardOutput:outputPipe];
    NSArray *standardOutputArray = [NSArray array];
    NSArray *errorOutputArray = [NSArray array];
    [task launch];
    spawnedProcessPid = task.processIdentifier;
    NSLog(@"omriku ran command with args: %@ %@",task.launchPath, [task.arguments componentsJoinedByString:@" "]);
    if ([command containsString:@"download"]) {
       [[errorPipe fileHandleForReading] waitForDataInBackgroundAndNotify];
       [[outputPipe fileHandleForReading] waitForDataInBackgroundAndNotify];
    } else {
        NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
        NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
        standardOutputArray = [outputString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        NSData *errorData = [[errorPipe fileHandleForReading] readDataToEndOfFile];
        NSString *errorOutput = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
        errorOutputArray = [errorOutput componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    }
    
    return @{@"standardOutput": standardOutputArray, @"errorOutput": errorOutputArray};
}

+ (void)loginToFile:(NSString *)userEmail {
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:IPARANGER_SETTINGS_DICT]];
    settings[@"Authenticated"] = @YES;
    settings[@"AccountEmail"] = userEmail;
    settings[@"lastLoginDate"] = [NSDate date];
    [settings writeToFile:IPARANGER_SETTINGS_DICT atomically:YES];
}

+ (void)logoutToFile {
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:IPARANGER_SETTINGS_DICT]];
    settings[@"Authenticated"] = @NO;
    settings[@"AccountEmail"] = @"";
    settings[@"lastLogoutDate"] = [NSDate date];
    [settings writeToFile:IPARANGER_SETTINGS_DICT atomically:YES];
}

+ (void)downloadCountryToFile:(NSString *)accountCountry {
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:IPARANGER_SETTINGS_DICT]];
    settings[@"AccountCountryDownload"] = accountCountry;
    [settings writeToFile:IPARANGER_SETTINGS_DICT atomically:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:kIPARCountryChangedNotification object:nil];
}

+ (NSString *)getMostUpdatedDownloadCountryFromFile {
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:IPARANGER_SETTINGS_DICT]];
    return settings[@"AccountCountryDownload"];
}

+ (void)searchCountryToFile:(NSString *)accountCountry {
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:IPARANGER_SETTINGS_DICT]];
    settings[@"AccountCountrySearch"] = accountCountry;
    [settings writeToFile:IPARANGER_SETTINGS_DICT atomically:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:kIPARCountryChangedNotification object:nil];
}

+ (NSString *)getMostUpdatedSearchCountryFromFile {
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:IPARANGER_SETTINGS_DICT]];
    return settings[@"AccountCountrySearch"];
}

//+ (void)cancelScript:(int)pid {
+ (void)cancelScript {
    kill(spawnedProcessPid, SIGKILL);
}

+ (NSString *)emojiFlagForISOCountryCode:(NSString *)countryCode {
    NSAssert(countryCode.length == 2, @"Expecting ISO country code");

    int base = 127462 -65;

    wchar_t bytes[2] = {
        base +[countryCode characterAtIndex:0],
        base +[countryCode characterAtIndex:1]
    };

    return [[NSString alloc] initWithBytes:bytes length:countryCode.length *sizeof(wchar_t) encoding:NSUTF32LittleEndianStringEncoding];
}

+ (UIImage *)getAppIconFromApple:(NSString *)bundleId {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com/lookup?bundleId=%@", bundleId]];
    NSData *data = [NSData dataWithContentsOfURL:url];

    if (data) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        NSArray *results = json[@"results"];
        
        if (results.count > 0) {
            NSDictionary *appInfo = results[0];
            NSString *iconUrlString = appInfo[@"artworkUrl100"];
            NSURL *iconUrl = [NSURL URLWithString:iconUrlString];
            NSData *iconData = [NSData dataWithContentsOfURL:iconUrl];
            UIImage *iconImage = [UIImage imageWithData:iconData];
            NSLog(@"omriku returning image: %@ for bundle: %@", iconImage, bundleId);
            return iconImage;
            // Use the icon image in your list
        }
    }
    NSLog(@"omriku returns nil FOR BUNDLE: %@", bundleId);
    return nil;
}
@end

