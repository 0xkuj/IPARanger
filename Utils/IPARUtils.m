#import "IPARUtils.h"
#include <spawn.h>
#include <signal.h>
#import "../Extensions/IPARConstants.h"
#include <sys/wait.h>
#include <unistd.h>

#define READ_END 0
#define WRITE_END 1

// global variable to store the pid of the spawned process
int spawnedProcessPid;

@implementation IPARUtils
+ (NSDictionary *)executeCommandAndGetJSON:(NSString *)launchPath arg1:(NSString *)arg1 arg2:(NSString *)arg2 arg3:(NSString *)arg3 {
    // Validate input
    if (!launchPath.length) {
        return @{kJsonLevel: kJsonLevelError, kJsonLevelError : @"Launch path cannot be empty" };
    }
    
    BOOL isDownload = ([arg2 containsString:@"download"]);
    
    int stdout_pipe[2];
    if (pipe(stdout_pipe) == -1) {
        return @{kJsonLevel: kJsonLevelError, kJsonLevelError : @"Failed to create pipe" };
    }

    int fileDescriptor = -1;
    if (isDownload) {
        // Open the file for writing
        fileDescriptor = open(kIPARangerLatestDownloadLogPath, O_CREAT | O_WRONLY | O_TRUNC, 0644);
        if (fileDescriptor == -1) {
            close(stdout_pipe[0]);
            close(stdout_pipe[1]);
            return @{kJsonLevel: kJsonLevelError, kJsonLevelError : @"Failed to open file for writing" };
        }
    }

    posix_spawn_file_actions_t actions;
    posix_spawn_file_actions_init(&actions);
    
    // Redirect output
    if (isDownload) {
        posix_spawn_file_actions_adddup2(&actions, fileDescriptor, STDOUT_FILENO);
    } else {
        posix_spawn_file_actions_adddup2(&actions, stdout_pipe[1], STDOUT_FILENO);
    }

    pid_t pid;
    const char *argv[] = { [launchPath UTF8String], [arg1 UTF8String], 
                          [arg2 UTF8String], [arg3 UTF8String], NULL };
    
    int spawnError = posix_spawn(&pid, [launchPath UTF8String], &actions, NULL, 
                                (char* const*)argv, NULL);
    posix_spawn_file_actions_destroy(&actions);
    
    if (spawnError != 0) {
        close(stdout_pipe[0]); 
        close(stdout_pipe[1]);
        if (isDownload) close(fileDescriptor);
        return @{kJsonLevel: kJsonLevelError, kJsonLevelError : @"Failed to spawn process" };
    }

    spawnedProcessPid = pid;
    if (isDownload) {
        close(fileDescriptor); // Close file descriptor
        close(stdout_pipe[0]);
        close(stdout_pipe[1]);
        
        // Return success so you can track the file separately
        return @{kJsonLevel: kJsonLevelInfo, kJsonResponseContent : @"Download started. Progress written to file."};
    }

    close(stdout_pipe[1]);  // Close write end

    // Read JSON output
    NSMutableData *outputData = [NSMutableData data];
    char buffer[4096];
    ssize_t bytesRead;
    
    while ((bytesRead = read(stdout_pipe[0], buffer, sizeof(buffer))) > 0) {
        [outputData appendBytes:buffer length:bytesRead];
    }
    
    close(stdout_pipe[0]);  // Close read end

    // Wait for process to finish
    waitpid(pid, NULL, 0);

    // Parse JSON
    NSError *jsonError = nil;
    NSDictionary *jsonResult = [NSJSONSerialization JSONObjectWithData:outputData 
                                                             options:0 
                                                               error:&jsonError];

    if (jsonError) {
        return @{kJsonLevel: kJsonLevelError, kJsonLevelError : @"Failed to parse JSON output" };
    }

    return jsonResult;
}

+ (NSDictionary *)setupTaskAndPipesWithCommandposix:(NSString *)launchPath arg1:(NSString *)arg1 
  arg2:(NSString *)arg2 arg3:(NSString *)arg3 {
    int stdout_pipe[2];
    int stderr_pipe[2];
    pipe(stdout_pipe);
    pipe(stderr_pipe);
    
    posix_spawn_file_actions_t actions;
    posix_spawn_file_actions_init(&actions);
    posix_spawn_file_actions_adddup2(&actions, stdout_pipe[WRITE_END], STDOUT_FILENO);
    posix_spawn_file_actions_adddup2(&actions, stderr_pipe[WRITE_END], STDERR_FILENO);

    pid_t pid;
    const char *argv[] = { [launchPath UTF8String], [arg1 UTF8String], [arg2 UTF8String], [arg3 UTF8String], NULL };
    if (posix_spawn(&pid, [launchPath UTF8String], &actions, NULL, (char* const*)argv, NULL) != 0) {
        NSString *error = [NSString stringWithFormat:@"posix spawn failed with command: %@ %@", launchPath, arg1];
        return @{kerrorOutput: error};
    }
    
    close(stdout_pipe[WRITE_END]);
    close(stderr_pipe[WRITE_END]);

    NSArray *standardOutputArray = [NSArray array];
    NSArray *errorOutputArray = [NSArray array];
    NSData *outputData = readDataFromFD(stdout_pipe[READ_END]);
    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    standardOutputArray = [outputString componentsSeparatedByString:@"\n"];
        
    NSData *errorData = readDataFromFD(stderr_pipe[READ_END]);
    NSString *errorOutput = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
    errorOutputArray = [errorOutput componentsSeparatedByString:@"\n"];
    close(stdout_pipe[READ_END]);
    close(stderr_pipe[READ_END]);

    return @{kstdOutput: standardOutputArray, kerrorOutput: errorOutputArray};
}

NSData *readDataFromFD(int fd) {
    NSMutableData *data = [[NSMutableData alloc] init];
    ssize_t count;
    char buffer[4096];
    while ((count = read(fd, buffer, sizeof(buffer))) > 0) {
        [data appendBytes:buffer length:count];
    }
    return data;
}

+ (NSDictionary<NSString*,NSArray*> *)setupTaskAndPipesWithCommand:(NSString *)command {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:kLaunchPathBash];
    [task setArguments:@[kBashCommandKey, command]];
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
    settings[kAccountNameKeyFromFile] = authName;
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

+ (UIButton *)createButtonWithImageName:(NSString *)imageName title:(NSString *)title fontSize:(CGFloat)fontSize selectorName:(NSString *)selectorName frame:(CGRect)frame {
    SEL selector = NSSelectorFromString(selectorName);
    UIButton *button = [[UIButton alloc] initWithFrame:frame];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:fontSize];
    [button sizeToFit];
    [button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setImageEdgeInsets:UIEdgeInsetsMake(0, -30, 0, 0)]; // shift image left by 10 points
    [button setTitleEdgeInsets:UIEdgeInsetsMake(0, -20, 0, 0)]; // shift text right by 10 points
    return button;
}

+ (void)openTW {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:kTwitterLink];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {return;}];
}

+ (void)openPP {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:kPaypalLink];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {return;}];
}

+ (void)openGithub {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:kGithubRepoLink];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {return;}];
}

+ (void)getAppIconFromApple:(NSString *)bundleId completion:(void (^)(UIImage *appIcon))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kItunesImagesForBundleURL, bundleId]];
        NSData *data = [NSData dataWithContentsOfURL:url];

        UIImage *iconImage = nil;

        if (data) {
            NSError *jsonError = nil;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];

            if (!jsonError) {
                NSArray *results = json[@"results"];
                if (results.count > 0) {
                    NSDictionary *appInfo = results[0];
                    NSString *iconUrlString = appInfo[kItunesImagesForBundleAnswerField];
                    NSURL *iconUrl = [NSURL URLWithString:iconUrlString];
                    NSData *iconData = [NSData dataWithContentsOfURL:iconUrl];

                    if (iconData) {
                        iconImage = [UIImage imageWithData:iconData];
                    }
                }
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(iconImage);
            }
        });
    });
}

+ (NSString *)humanReadableSizeForBytes:(long long)bytes {
    NSArray *suffixes = @[@"B", @"KB", @"MB", @"GB"];
    int suffixIndex = 0;
    double size = (double)bytes;
    
    while (size > 1024 && suffixIndex < suffixes.count - 1) {
        size /= 1024;
        suffixIndex++;
    }
    
    NSString *sizeString = [NSString stringWithFormat:@"%.1f %@", size, suffixes[suffixIndex]];
    return sizeString;
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

+ (unsigned long long)calculateFolderSize:(NSString *)folderPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    if (![fileManager fileExistsAtPath:folderPath]) {
        return 0;
    }

    NSArray *contents = [fileManager contentsOfDirectoryAtPath:folderPath error:&error];
    if (error) {
        return 0;
    }

    unsigned long long folderSize = 0;
    for (NSString *item in contents) {
        NSString *itemPath = [folderPath stringByAppendingPathComponent:item];
        NSDictionary *attributes = [fileManager attributesOfItemAtPath:itemPath error:&error];
        if (error) {
            continue;
        }
        
        if ([[attributes fileType] isEqualToString:NSFileTypeDirectory]) {
            folderSize += [self calculateFolderSize:itemPath];
        } else {
            folderSize += [attributes fileSize];
        }
    }
    
    return folderSize;
}

+ (void)cancelScript {
    kill(spawnedProcessPid, SIGKILL);
}
@end

