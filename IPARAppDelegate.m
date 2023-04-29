#import "IPARAppDelegate.h"
#import <Foundation/Foundation.h>
#import "./Controllers/IPARLoginScreenViewController.h"
#import "./Utils/IPARUtils.h"
#import "./Controllers/IPARSearchViewController.h"
#import "./Controllers/IPARDownloadViewController.h"
#import "./Controllers/IPARAccountAndCreditsController.h"
#import "./Extensions/IPARConstants.h"

@implementation IPARAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	//[self basicSanity];

	if ([[IPARUtils getKeyFromFile:kAuthenticatedKeyFromFile defaultValueIfNil:@"NO"] isEqualToString:@"YES"]) {
        IPARSearchViewController *searchVC = [[IPARSearchViewController alloc] init];
		UINavigationController *searchNC = [[UINavigationController alloc] initWithRootViewController:searchVC];

        IPARDownloadViewController *downloadVC = [[IPARDownloadViewController alloc] init];
        UINavigationController *downloadNC = [[UINavigationController alloc] initWithRootViewController:downloadVC];

		IPARAccountAndCredits *accountVC = [[IPARAccountAndCredits alloc] init];
        UINavigationController *accountNC = [[UINavigationController alloc] initWithRootViewController:accountVC];

        UITabBarController *tabBarController = [[UITabBarController alloc] init];
        tabBarController.viewControllers = @[searchNC, downloadNC, accountNC];
        self.window.rootViewController = tabBarController;
	} else {
		_rootViewController = [[UINavigationController alloc] initWithRootViewController:[[IPARLoginScreenViewController alloc] init]];
		_window.rootViewController = _rootViewController;
	}

	[_window makeKeyAndVisible];
}

- (void)basicSanity {
    NSString *s = [IPARUtils sha256ForFileAtPath:kIpatoolScriptPath];
    AlertActionBlockWithTextField alertBlockConfirm = ^(UITextField *textField) {
        exit(0);
    };
    if (s == nil) {
        [IPARUtils presentDialogWithTitle:kIPARangerErrorHeadline message:@"ipatool file was not found inside resources directory!" hasTextfield:NO withTextfieldBlock:nil
                        alertConfirmationBlock:alertBlockConfirm withConfirmText:@"Exit IPARanger" alertCancelBlock:nil withCancelText:nil presentOn:self];
    } else if (![s isEqualToString:kSha256verification]) {
        [IPARUtils presentDialogWithTitle:kIPARangerErrorHeadline message:@"Could not verify the integrity of files" hasTextfield:NO withTextfieldBlock:nil
                        alertConfirmationBlock:alertBlockConfirm withConfirmText:@"Exit IPARanger" alertCancelBlock:nil withCancelText:nil presentOn:self];
    }
}
@end
