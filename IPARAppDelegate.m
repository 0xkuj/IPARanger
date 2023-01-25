#import "IPARAppDelegate.h"
#import "IPARRootViewController.h"
#import <Foundation/Foundation.h>
#import "IPARLoginScreenViewController.h"
#import "IPARUtils.h"

@implementation IPARAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	//if will try to download and get token error or something, just logout, and change the value in plist.
	//or actually think of a much better safer way, this is stupid.
	//wtf
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:IPARANGER_SETTINGS_DICT]];
	if ([settings[@"Authenticated"] boolValue] == YES) {
		_rootViewController = [[UINavigationController alloc] initWithRootViewController:[[IPARRootViewController alloc] init]];
	} else {
		_rootViewController = [[UINavigationController alloc] initWithRootViewController:[[IPARLoginScreenViewController alloc] init]];
	}
	_window.rootViewController = _rootViewController;
	[_window makeKeyAndVisible];
}



@end
