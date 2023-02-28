#import "IPARUtils.h"
#include <spawn.h>
#include <signal.h>
#import "IPARConstants.h"

// global variable to store the pid of the spawned process
int spawnedProcessPid;

@implementation IPARUtils
+ (NSDictionary<NSString*,NSArray*> *)setupTaskAndPipesWithCommand:(NSString *)command {
    NSTask *task = [[NSTask alloc] init];
    NSMutableArray *args = [NSMutableArray array];
    [args addObject:@"-c"];
    [args addObject:command];
    [task setLaunchPath:kLaunchPathBash];
    [task setArguments:args];
    NSPipe *outputPipe = [NSPipe pipe];
    NSPipe *errorPipe = [NSPipe pipe];
    [task setStandardError:errorPipe];
    [task setStandardOutput:outputPipe];
    NSArray *standardOutputArray = [NSArray array];
    NSArray *errorOutputArray = [NSArray array];
    [task launch];
    spawnedProcessPid = task.processIdentifier;
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

+ (void)setupUnzipTask:(NSString *)ipaFilePath directoryPath:(NSString *)directoryPath file:(NSString *)fileToUnzip {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:kLaunchPathUnzip];
    [task setArguments:@[ipaFilePath, [NSString stringWithFormat:@"Payload/*.app/%@", fileToUnzip]]];
    task.currentDirectoryPath = directoryPath;
    [task launch];
    [task waitUntilExit];
}

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

+ (NSString *)getKeyFromFile:(NSString *)key defaultValueIfNil:(NSString *)defaultValue {
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:kIPARangerSettingsDict]];
    return settings[key] ? settings[key] : defaultValue;
}

+ (void)saveKeyToFile:(NSString *)key withValue:(NSString *)value {
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:kIPARangerSettingsDict]];
    settings[key] = value;
    [settings writeToFile:kIPARangerSettingsDict atomically:YES];
    //post a notification once we save a country
    if ([[key lowercaseString] containsString:@"country"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kIPARCountryChangedNotification object:nil];
    }
}

+ (void)accountDetailsToFile:(NSString *)userEmail authName:(NSString *)authName authenticated:(NSString *)authenticated 
{
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:kIPARangerSettingsDict]];
    settings[@"AccountEmail"] = userEmail;
    settings[@"AccountName"] = [self parseLoginNameFromAuthString:authName];
    settings[@"Authenticated"] = authenticated;
    if ([authenticated isEqualToString:@"NO"]) {
        settings[@"lastLogoutDate"] = [NSDate date];
    } else {
        settings[@"lastLoginDate"] = [NSDate date];
    }
    [settings writeToFile:kIPARangerSettingsDict atomically:YES];
}

+ (NSString *)emojiFlagForISOCountryCode:(NSString *)countryCode {
    //our fallback country
    if (countryCode.length != 2) {
        countryCode = @"US";
    }

    int base = 127462 -65;

    wchar_t bytes[2] = {
        base +[countryCode characterAtIndex:0],
        base +[countryCode characterAtIndex:1]
    };

    return [[NSString alloc] initWithBytes:bytes length:countryCode.length *sizeof(wchar_t) encoding:NSUTF32LittleEndianStringEncoding];
}

+ (NSString *)parseLoginNameFromAuthString:(NSString *)authString {
    // Create the regular expression pattern
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"'([^']*)'" options:NSRegularExpressionCaseInsensitive error:nil];

    // Search the input string for matches to the pattern
    NSArray *matches = [regex matchesInString:authString options:0 range:NSMakeRange(0, authString.length)];

    // Extract the matched strings between single quotes
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match rangeAtIndex:1];
        return [authString substringWithRange:matchRange];
    }
    return @"";
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
            return iconImage;
        }
    }
    return nil;
}

+ (NSString *)humanReadableSizeForBytes:(long long)bytes {
    NSArray *suffixes = @[@"B", @"KB", @"MB", @"GB", @"TB"];
    int suffixIndex = 0;
    double size = (double)bytes;
    
    while (size > 1024 && suffixIndex < suffixes.count - 1) {
        size /= 1024;
        suffixIndex++;
    }
    
    NSString *sizeString = [NSString stringWithFormat:@"%.1f %@", size, suffixes[suffixIndex]];
    return sizeString;
}

+ (void)presentMessageWithTitle:(NSString *)title 
                      message:(NSString *)message 
                      numberOfActions:(NSUInteger)numberOfActions 
                      buttonText:(NSString *)buttonText 
                      alertConfirmationBlock:(AlertActionBlock)confirmationBlock 
                      alertCancelBlock:(AlertActionBlock)cancelBlock
                      presentOn:(id)viewController {

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:buttonText style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (confirmationBlock != nil) {
            confirmationBlock();
        }
    }];
    [alert addAction:okAction];
    if (numberOfActions > 1) {
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            if (cancelBlock != nil) {
                cancelBlock();
            }
        }];
        [alert addAction:cancelAction];
    }

    [viewController presentViewController:alert animated:YES completion:nil];
}

+ (void)cancelScript {
    kill(spawnedProcessPid, SIGKILL);
}
@end

