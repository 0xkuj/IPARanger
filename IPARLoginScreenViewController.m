#import "IPARLoginScreenViewController.h"
#import "IPARRootViewController.h"

#pragma clang diagnostic ignored "-Wunused-variable"
#define IPATOOL_SCRIPT_PATH @"/Applications/IPARanger.app/ipatool/ipatool"
#define IPARANGER_SETTINGS_DICT @"/var/mobile/Library/Preferences/IPARanger/com.0xkuj.iparangersettings.plist"

@interface IPARLoginScreenViewController ()
@property (nonatomic) IBOutlet UITextField *emailTextField;
@property (nonatomic) IBOutlet UITextField *passwordTextField;
@property (nonatomic) UIButton *loginButton;
@property (nonatomic, strong) NSArray *linesStandardOutput;
@property (nonatomic, strong) NSArray *linesErrorOutput;
@end

@implementation IPARLoginScreenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setLoginButtons];
    [self.view addSubview:_emailTextField];
    [self.view addSubview:_passwordTextField];
    [self.view addSubview:_loginButton];
}

- (void)setLoginButtons {
    // Create email text field
    self.emailTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 100, 280, 40)];
    self.emailTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.emailTextField.placeholder = @"Email";
    self.emailTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.emailTextField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailTextField.returnKeyType = UIReturnKeyDone;
    self.emailTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.emailTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;

    // Create password text field
    self.passwordTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, 150, 280, 40)];
    self.passwordTextField.borderStyle = UITextBorderStyleRoundedRect;
    self.passwordTextField.placeholder = @"Password";
    self.passwordTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.passwordTextField.keyboardType = UIKeyboardTypeDefault;
    self.passwordTextField.returnKeyType = UIReturnKeyDone;
    self.passwordTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.passwordTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.passwordTextField.secureTextEntry = YES;

    // Create login button
    self.loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.loginButton setTitle:@"Login" forState:UIControlStateNormal];
    self.loginButton.frame = CGRectMake(20, 200, 280, 40);
    [self.loginButton addTarget:self action:@selector(loginButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
}


- (IBAction)loginButtonTapped:(id)sender {

    //why is this all needed..? can we call handleLoginEmailPass directly?!?! maybe here we can check if binary exists.. its good.
    NSFileManager *fileManager = [NSFileManager defaultManager];
	// Get the resource path
	NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
	// Get the contents of the resource directory
	NSError *error = nil;
	NSString *scriptPath = [NSString stringWithFormat:@"%@/ipatool", resourcePath];
	NSArray *files = [fileManager contentsOfDirectoryAtPath:scriptPath error:&error];
    BOOL checkIfBinaryExists = NO;

	if (error) {
		NSLog(@"omriku Error getting files from resource directory: %@", error);
	} else {
		// Iterate through the files
		for (NSString *file in files) {
            if ([file isEqualToString:@"ipatool"]) {
                NSLog(@"omriku ipatool binary was found. all good!");
                checkIfBinaryExists = YES;
                break;
            }
		}
        if (checkIfBinaryExists == NO) {
            NSLog(@"omriku CRITICAL: ipatool binary WAS NOT FOUND!");
        }
	}
	
	//file not found. wtf? maybe cancel -c or break the command into multiple arguments. create array and stuff.
	//scriptPath = [NSString stringWithFormat:@"%@/ipatool/ipatool", resourcePath];
	//NSLog(@"omriku cmd? %@:",CMD(scriptPath));
	//works this way. no need to split arguments.
	//NSLog(@"omriku cmd? %@:",CMD(@"/Applications/IPARanger.app/ipatool/ipatool search --limit 1 faceboo"));
	//this works. this will be the first login screen..
    //after you will recognize 2fa is required, you will popup a window that will recall auth login with the 2fa after the -p password stuff..
    [self handleLoginEmailPass];
}

- (void)handleLoginEmailPass {
    NSString *commandToExecute = [NSString stringWithFormat:@"%@ auth login -e %@ -p %@", IPATOOL_SCRIPT_PATH, self.emailTextField.text, self.passwordTextField.text];
    [self setupTaskAndPipesWithCommand:commandToExecute];

    for (id obj in self.linesStandardOutput) {
        NSLog(@"omriku line output :%@", obj);
        if ([obj containsString:@"Authenticated as"]) {
            [self writeAuthToFile];
        } else {
            //possible errors:
            //email missing
            //pass missing
            //something with 2fa.. not sure.
            //looks like we can say its an error ONLY AFTER 2FA IS WRONG.
            //handle errors.. present them at least. we are expecting for this to work in standardoutput after login.
        }
    }

    for (id obj in self.linesErrorOutput) {
        NSLog(@"omriku line error :%@", obj);
        if ([obj containsString:@"2FA"]) {
            [self handle2FADialog];
        } else {
            //do we actually can get error here? dont think so.. need to check.
            //handle errors.. we are expecting to see only 2fa errors here. if not, present them!
        }
    }
}

- (void)handle2FADialog {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Continue with 2FA" message:@"Please enter 2FA you got from Apple" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // Retrieve the text entered in the text field
        UITextField *textField = alert.textFields.firstObject;
        NSString *twoFAResponse = textField.text;
        NSLog(@"omriku 2fa");
        [self handle2FALogic:twoFAResponse];
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];

    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Enter your 2FA you got from Apple here";
    }];

    [alert addAction:okAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)handle2FALogic:(NSString *)twoFARes {
    NSString *commandToExecute = [NSString stringWithFormat:@"%@ auth login -e %@ -p %@%@", IPATOOL_SCRIPT_PATH, self.emailTextField.text, self.passwordTextField.text, twoFARes];
    [self setupTaskAndPipesWithCommand:commandToExecute];
    
    for (id obj in self.linesStandardOutput) {
         if ([obj containsString:@"Authenticated as"]) {
            [self writeAuthToFile];
        }
        NSLog(@"omriku line output :%@", obj);
    }

    for (id obj in self.linesErrorOutput) {
        if ([obj containsString:@"An unknown error has occurred"]) {
            NSLog(@"omriku CRITICAL ERROR. SOMETHING WRONG WITH YOUR CREDS. TRY AGAIN AND CHECK!");
        }
        NSLog(@"omriku line error :%@", obj);
    }
}

- (void)writeAuthToFile {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:IPARANGER_SETTINGS_DICT error:nil];
    NSMutableDictionary *newFileAttributes = [fileAttributes mutableCopy];

    // Set permissions to all
    newFileAttributes[NSFilePosixPermissions] = @(0777);

    // Update the permissions
    [fileManager setAttributes:newFileAttributes ofItemAtPath:IPARANGER_SETTINGS_DICT error:nil];

    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:IPARANGER_SETTINGS_DICT];
    settings[@"Authenticated"] = @YES;
    settings[@"AccountEmail"] = self.emailTextField.text;
    settings[@"lastLoginDate"] = [NSDate date];
    [settings writeToFile:IPARANGER_SETTINGS_DICT atomically:YES];
    IPARRootViewController *mainVC = [[IPARRootViewController alloc] init];
    [self.navigationController pushViewController:mainVC animated:YES];
}

- (void)setupTaskAndPipesWithCommand:(NSString *)command {
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
    [task launch];

    NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

    NSData *errorData = [[errorPipe fileHandleForReading] readDataToEndOfFile];
    NSString *errorOutput = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];

    NSLog(@"omriku reading outputstring.. command: %@ %@",task.launchPath, [task.arguments componentsJoinedByString:@" "]);
    self.linesStandardOutput = [outputString componentsSeparatedByCharactersInSet:
                                            [NSCharacterSet newlineCharacterSet]];

    self.linesErrorOutput = [errorOutput componentsSeparatedByCharactersInSet:
                                            [NSCharacterSet newlineCharacterSet]];
}
// NSString *CMD(NSString *CMD) {
        
//    NSTask *task = [[NSTask alloc] init];
//    NSMutableArray *args = [NSMutableArray array];
//    [args addObject:@"-c"];
//    [args addObject:CMD];
//    [task setLaunchPath:@"/bin/sh"];
//    [task setArguments:args];
//    NSPipe *outputPipe = [NSPipe pipe];
//    NSPipe *errorPipe = [NSPipe pipe];
//    [task setStandardError:errorPipe];
//    [task setStandardOutput:outputPipe];
//    [task launch];
//    NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
//    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

//    NSData *errorData = [[errorPipe fileHandleForReading] readDataToEndOfFile];
//    NSString *errorOutput = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];

//    NSLog(@"omriku reading outputstring.. command: %@ %@",task.launchPath, [task.arguments componentsJoinedByString:@" "]);
//    NSArray *linesOutput = [outputString componentsSeparatedByCharactersInSet:
// 										[NSCharacterSet newlineCharacterSet]];

//    NSArray *linesError = [errorOutput componentsSeparatedByCharactersInSet:
// 										[NSCharacterSet newlineCharacterSet]];
//    for (id obj in linesOutput) {
//       NSLog(@"omriku line output :%@", obj);
//       if ([obj containsString:@"Authenticated as"]) {
//         return @"Success";
//       }
//    }

//    for (id obj in linesError) {
//       NSLog(@"omriku line error :%@", obj);
//       if ([obj containsString:@"2FA"]) {
//         return @"2FA";
//       }
//    }

//    //returns one line, this is shit basically..
//    return outputString;
// }
@end
