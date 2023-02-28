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
		//_rootViewController = [[UINavigationController alloc] initWithRootViewController:[[IPARSearchViewController alloc] init]];
        // Create the tab bar controller
        UITabBarController *tabBarController = [[UITabBarController alloc] init];

        // Create the first view controller
        IPARSearchViewController *firstViewController = [[IPARSearchViewController alloc] init];
		firstViewController.title = @"Search";
		firstViewController.tabBarItem.image = [UIImage systemImageNamed:@"magnifyingglass"];
		firstViewController.tabBarItem.title = @"Search";
        // Create the navigation controller for the first view controller
        
		UINavigationController *firstNavigationController = [[UINavigationController alloc] initWithRootViewController:firstViewController];
        // Create the second view controller
        IPARDownloadViewController *secondViewController = [[IPARDownloadViewController alloc] init];
		secondViewController.title = @"Download";
		secondViewController.tabBarItem.image = [UIImage systemImageNamed:@"square.stack.3d.up"];
		secondViewController.tabBarItem.title = @"Download";
        // Create the navigation controller for the second view controller
        UINavigationController *secondNavigationController = [[UINavigationController alloc] initWithRootViewController:secondViewController];

		IPARAccountAndCredits *thirdViewController = [[IPARAccountAndCredits alloc] init];
		thirdViewController.title = @"Account";
		thirdViewController.tabBarItem.image = [UIImage systemImageNamed:@"person.crop.circle"];
		thirdViewController.tabBarItem.title = @"Account";
        // Create the navigation controller for the second view controller
        UINavigationController *thirdNavigationController = [[UINavigationController alloc] initWithRootViewController:thirdViewController];
        // Add the navigation controllers to the tab bar controller
        tabBarController.viewControllers = @[firstNavigationController, secondNavigationController, thirdNavigationController];

        // Set the tab bar controller as the root view controller
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
    AlertActionBlock alertBlock = ^(void) {
        exit(0);
    };
    if (s == nil) {
        [IPARUtils presentMessageWithTitle:@"IPARanger\nError" message:@"ipatool file was not found inside resources directory!" numberOfActions:1 buttonText:@"Exit IPARanger" alertConfirmationBlock:alertBlock alertCancelBlock:nil presentOn:self];
    } else if (![s isEqualToString:sha256verification]) {
        [IPARUtils presentMessageWithTitle:@"IPARanger\nError" message:@"Could not verify the integrity of files" numberOfActions:1 buttonText:@"Exit IPARanger" alertConfirmationBlock:alertBlock alertCancelBlock:nil presentOn:self];
    }
}
@end
