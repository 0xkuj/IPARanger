#import "IPARAppDelegate.h"
#import <Foundation/Foundation.h>
#import "IPARLoginScreenViewController.h"
#import "IPARUtils.h"
#import "IPARSearchViewController.h"
#import "IPARDownloadViewController.h"

@implementation IPARAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	//if will try to download and get token error or something, just logout, and change the value in plist.
	//or actually think of a much better safer way, this is stupid.
	//wtf
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:IPARANGER_SETTINGS_DICT]];
	if ([settings[@"Authenticated"] boolValue] == YES) {
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
        // Add the navigation controllers to the tab bar controller
        tabBarController.viewControllers = @[firstNavigationController, secondNavigationController];

        // Set the tab bar controller as the root view controller
        self.window.rootViewController = tabBarController;
	} else {
		_rootViewController = [[UINavigationController alloc] initWithRootViewController:[[IPARLoginScreenViewController alloc] init]];
		_window.rootViewController = _rootViewController;
	}

	[_window makeKeyAndVisible];
}



@end
