#import "IPARAppDelegate.h"
#import "IPARRootViewController.h"
#import <Foundation/Foundation.h>
#import "IPARLoginScreenViewController.h"
#pragma clang diagnostic ignored "-Wunused-variable"

@implementation IPARAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	//if logged in (info.plist) then dont do this..
	//if will try to download and get token error or something, just logout, and change the value in plist.
	//or actually think of a much better safer way, this is stupid.
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    [settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/IPARanger/com.0xkuj.iparangersettings.plist"]];
	if ([settings[@"Authenticated"] boolValue] == YES) {
		_rootViewController = [[UINavigationController alloc] initWithRootViewController:[[IPARRootViewController alloc] init]];
	} else {
		_rootViewController = [[UINavigationController alloc] initWithRootViewController:[[IPARLoginScreenViewController alloc] init]];
	}
	_window.rootViewController = _rootViewController;
	[_window makeKeyAndVisible];

	//NSLog(@"omriku read file contnet?? %@", output);
	// NSTask *task = [[NSTask alloc] init];
	// //[task setLaunchPath:@"/usr/local/bin/python3"];
	// [task launchPath]; // path to the Python interpreter

	// // Arguments for the task
	// // NSMutableArray *args = [NSMutableArray array];
	// // [args addObject:scriptPath];
	// // [task setArguments:args];
	// //task.arguments = @[@"/Applications/IPARanger.app/ipatool/main.py"];
	// NSString *appleID = @"xxx";
	// NSString *applepwd = @"yyy";
	// task.arguments = @[@"/Applications/IPARanger.app/ipatool/main.py", @"lookup", @"-b", @"com.netflix.Netflix", @"-c", @"US", @"download", @"-e", appleID, @"-p", applepwd, @"-o", @"."];
	// // Set the standard output to a pipe so we can read the output
	// NSPipe *pipe = [NSPipe pipe];
	// task.standardOutput = pipe;
	// NSPipe *errorPipe = [NSPipe pipe];
	// task.standardError = errorPipe;

	// // Start the task
	// [task launch];
	// // Read the output from the pipe
	// NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];

	// // Convert the output to a string
	// NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	// NSData *errorData = [[errorPipe fileHandleForReading] readDataToEndOfFile];
	// NSString *errorOutput = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
	// NSLog(@"omriku Running command: %@ %@ output: %@ err output: %@", task.launchPath, [task.arguments componentsJoinedByString:@" "], output, errorOutput);
}



@end
