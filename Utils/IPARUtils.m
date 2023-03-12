#import "IPARUtils.h"
#include <spawn.h>
#include <signal.h>
#import "../Extensions/IPARConstants.h"

// global variable to store the pid of the spawned process
int spawnedProcessPid;

@implementation IPARUtils
+ (NSDictionary<NSString*,NSArray*> *)setupTaskAndPipesWithCommand:(NSString *)command {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:kLaunchPathBash];
    [task setArguments:@[@"-c", command]];
    NSPipe *outputPipe = [NSPipe pipe];
    NSPipe *errorPipe = [NSPipe pipe];
    [task setStandardError:errorPipe];
    [task setStandardOutput:outputPipe];
    [task launch];

    NSArray *standardOutputArray = [NSArray array];
    NSArray *errorOutputArray = [NSArray array];
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
    
    return @{kstdOutput: standardOutputArray, kerrorOutput: errorOutputArray};
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

+ (id)getKeyFromFile:(NSString *)key defaultValueIfNil:(NSString *)defaultValue {
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

+ (void)accountDetailsToFile:(NSString *)userEmail authName:(NSString *)authName authenticated:(NSString *)authenticated {
    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:kIPARangerSettingsDict]];
    settings[kAccountEmailKeyFromFile] = userEmail;
    settings[kAccountNameKeyFromFile] = [self parseLoginNameFromAuthString:authName];
    settings[kAuthenticatedKeyFromFile] = authenticated;
    if ([authenticated isEqualToString:@"NO"]) {
        settings[kLastLogoutDateKeyFromFile] = [NSDate date];
    } else {
        settings[kLastLoginDateKeyFromFile] = [NSDate date];
    }
    [settings writeToFile:kIPARangerSettingsDict atomically:YES];
}

+ (NSString *)emojiFlagForISOCountryCode:(NSString *)countryCode {
    //our fallback country
    if (countryCode.length != 2) {
        countryCode = kDefaultInitialCountry;
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
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kItunesImagesForBundleURL, bundleId]];
    NSData *data = [NSData dataWithContentsOfURL:url];

    if (data) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        NSArray *results = json[@"results"];
        
        if (results.count > 0) {
            NSDictionary *appInfo = results[0];
            NSString *iconUrlString = appInfo[kItunesImagesForBundleAnswerField];
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

+ (NSArray *)parseDetailFromStringByRegex:(NSArray *)strings regex:(NSString *)regex {
    NSError *error = nil;
    NSMutableArray *retval = [NSMutableArray array];
    NSRegularExpression *regx = [NSRegularExpression regularExpressionWithPattern:regex options:0 error:&error];

    for (NSString *string in strings) {
        NSTextCheckingResult *match = [regx firstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
        if (match) {
            NSRange range = [match rangeAtIndex:1];
            [retval addObject:[string substringWithRange:range]];
        }
    }
    return retval;
}

+ (NSString *)parseValueFromKey:(NSString *)CFKey {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(.+?)\\s*\\(" options:0 error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:CFKey options:0 range:NSMakeRange(0, [CFKey length])];
    NSString *result = [CFKey substringWithRange:[match rangeAtIndex:1]];
    return result;
}

+ (NSArray *)parseAppVersionFromStrings:(NSArray *)strings {
    NSString *pattern = @"\\((.*?)\\)[^\\(]*$";
    NSMutableArray *retval = [NSMutableArray array];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];

    for (NSString *string in strings) {
        NSRange range = [regex rangeOfFirstMatchInString:string options:NSMatchingReportCompletion range:NSMakeRange(0, [string length])];
        if (range.location != NSNotFound) {
            NSString *version = [string substringWithRange:range];
            [retval addObject:[version substringWithRange:NSMakeRange(1, [version length] - 3)]];
        }
    }
    return retval;
}

+ (void)animateClickOnCell:(UITableViewCell *)cell {
    [UIView animateWithDuration:0.08 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        cell.transform = CGAffineTransformMakeScale(0.90, 0.90);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.08 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            cell.transform = CGAffineTransformIdentity;
        } completion:nil];
    }];
}

+ (void)presentDialogWithTitle:(NSString *)title 
                    message:(NSString *)message
                    hasTextfield:(BOOL)hasTextfield
                    withTextfieldBlock:(AlertTextFieldBlock)textFieldBlock
                    alertConfirmationBlock:(AlertActionBlockWithTextField)confirmationBlock
                    withConfirmText:(NSString *)confirmText
                    alertCancelBlock:(AlertActionBlock)cancelBlock
                    withCancelText:(NSString *)cancelText
                    presentOn:(id)viewController {

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    if (hasTextfield == YES) {
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textFieldBlock(textField);
        }];
    }
    if ([confirmText length] != 0) {
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:confirmText style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (confirmationBlock != nil) {
                if (hasTextfield == YES) {
                    confirmationBlock(alert.textFields.firstObject);
                } else {
                    confirmationBlock(nil);
                }
            }
        }];
        [alert addAction:confirmAction];
    }

    if ([cancelText length] != 0) {
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelText style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            if (cancelBlock != nil) {
                cancelBlock();
            }
        }];
        [alert addAction:cancelAction];
    }
    
    [viewController presentViewController:alert animated:YES completion:nil];
}

+ (UIActivityIndicatorView *)createActivitiyIndicatorWithPoint:(CGPoint)point {
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    spinner.center = point;
    spinner.color = [UIColor grayColor];
    [spinner startAnimating];
    return spinner;
}

+ (void)cancelScript {
    kill(spawnedProcessPid, SIGKILL);
}
@end

