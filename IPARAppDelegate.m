#import "IPARAppDelegate.h"
#import <Foundation/Foundation.h>
#import "IPARLoginScreenViewController.h"
#import "IPARUtils.h"
#import "IPARSearchViewController.h"
#import "IPARDownloadViewController.h"
#import "IPARAccountAndCredits.h"
#import "IPARConstants.h"

@implementation IPARAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	[self basicSanity];

	if ([[IPARUtils getKeyFromFile:@"Authenticated" defaultValueIfNil:@"NO"] isEqualToString:@"YES"]) {
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
	#define sha256verification @"22b9b697f865d25a702561e47a4748ade2675de6e26ad3a9ca2a607e66b0144b"
    NSString *s = [IPARUtils sha256ForFileAtPath:kIpatoolScriptPath];
    AlertActionBlockWithTextField alertBlockConfirm = ^(UITextField *textField) {
        exit(0);
    };
    if (s == nil) {
        [IPARUtils presentDialogWithTitle:@"IPARanger\nError" message:@"ipatool file was not found inside resources directory!" hasTextfield:NO withTextfieldBlock:nil
                        alertConfirmationBlock:alertBlockConfirm withConfirmText:@"Exit IPARanger" alertCancelBlock:nil withCancelText:nil presentOn:self];
    } else if (![s isEqualToString:sha256verification]) {
        [IPARUtils presentDialogWithTitle:@"IPARanger\nError" message:@"Could not verify the integrity of files" hasTextfield:NO withTextfieldBlock:nil
                        alertConfirmationBlock:alertBlockConfirm withConfirmText:@"Exit IPARanger" alertCancelBlock:nil withCancelText:nil presentOn:self];
    }
}
@end
