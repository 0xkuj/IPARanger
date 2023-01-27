#import "IPARDownloadViewController.h"
#import "IPARUtils.h"

@interface IPARDownloadViewController ()
@property (nonatomic, strong) NSMutableArray *appsBeingDownloaded;
@property (nonatomic, strong) NSMutableArray *existingApps;
@end

//IMPLEMENT SELECT COUNTRY!
@implementation IPARDownloadViewController
- (void)loadView {
    [super loadView];
    //in case i want to add percatnage to downloaded app.. but probably we will do it in nice UI and not in shit cell. after done, reload table.
    _appsBeingDownloaded = [NSMutableArray array];
    _existingApps = [NSMutableArray array];
    [self populateTableWithExistingApps];
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    [self _setUpNavigationBar2];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

- (void)_setUpNavigationBar2
{
	UIAction *accountAction = [UIAction actionWithTitle:@"Account" image:[UIImage systemImageNamed:@"person.crop.circle"] identifier:@"IPARangerAccount" handler:^(__kindof UIAction *action)
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{

		});
	}];

	UIAction *creditsAction = [UIAction actionWithTitle:@"Credits" image:[UIImage systemImageNamed:@"info.circle.fill"] identifier:@"IPARangerCredits" handler:^(__kindof UIAction *action)
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{

		});
	}];

	UIAction *logoutAction = [UIAction actionWithTitle:@"Logout" image:[UIImage systemImageNamed:@"arrow.right"] identifier:@"IPARangerLogout" handler:^(__kindof UIAction *action)
	{
		dispatch_async(dispatch_get_main_queue(), ^
		{

		});
	}];

	UIMenu* menu = [UIMenu menuWithChildren:@[accountAction, creditsAction, logoutAction]];
    UIBarButtonItem *optionsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"ellipsis"] menu:menu];
    UIBarButtonItem *downloadButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"square.and.arrow.down.on.square.fill"] style:UIBarButtonItemStylePlain target:self action:@selector(addButtonTapped:)];
    self.navigationItem.rightBarButtonItems = @[optionsButton, downloadButton];
}

- (void)populateTableWithExistingApps {
    NSLog(@"omriku will try to read directory content.. ");
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;

    // Get an array of all files and directories in the specified directory
    NSArray *files = [fileManager contentsOfDirectoryAtPath:IPARANGER_DOCUMENTS_LIBRARY error:&error];
    if (error) {
        NSLog(@"omriku Error getting contents of directory: %@", error);
        return;
    }

    // Filter the array to only include "ipa" files
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self ENDSWITH '.ipa'"];
    NSArray *ipaFiles = [files filteredArrayUsingPredicate:predicate];

    // Get the size of each "ipa" file
    [self.existingApps removeAllObjects];
    NSMutableArray *ipaFileInfos = [NSMutableArray array];
    for (NSString *fileName in ipaFiles) {
        NSLog(@"omriku checking file: %@", fileName);
        NSString *filePath = [IPARANGER_DOCUMENTS_LIBRARY stringByAppendingPathComponent:fileName];
        NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:&error];
        if (error) {
            NSLog(@"omriku Error getting attributes of file at path: %@", filePath);
            continue;
        }
        NSNumber *fileSize = [attributes objectForKey:NSFileSize];
        [self.existingApps addObject:@{@"name": fileName, @"size": fileSize}];
    }
    [self.tableView reloadData];
    // Now you can use the `ipaFileInfos` array to populate your table view.
}

- (void)addButtonTapped:(id)sender {
  	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IPARanger - Download" message:@"Enter App Bundle ID" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Download" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // Retrieve the text entered in the text field
        UITextField *textField = alert.textFields.firstObject;
        NSString *bundleToDownload = textField.text;
        NSString *commandToExecute = [NSString stringWithFormat:@"%@ download --bundle-identifier %@ -o %@ --purchase -c US", IPATOOL_SCRIPT_PATH, bundleToDownload, IPARANGER_DOCUMENTS_LIBRARY];
        [self testing:commandToExecute];
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];

    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"e.g com.facebook.Facebook";
    }];

    [alert addAction:okAction];
    [alert addAction:cancelAction];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // NSLog(@"omriku counting rows.. %lu",self.searchResults.count);
    // if (self.searchResults.count > 0) {
    //     return self.searchResults.count;
    // }
    return self.existingApps.count + self.appsBeingDownloaded.count;
   //return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}

    cell.textLabel.text = [NSString stringWithFormat:@"appname: %@ size: %@", self.existingApps[indexPath.row][@"name"], self.existingApps[indexPath.row][@"size"]]; 
	return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	//[self.searchResults removeObjectAtIndex:indexPath.row];
	[tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

 -(void)testing:(NSString *)command {
    NSLog(@"omriku in testing, command %@", command);
    NSTask *task = [[NSTask alloc] init];
    NSMutableArray *args = [NSMutableArray array];
    [args addObject:@"-c"];
    [args addObject:command];
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:args];
    // Create a pipe for the task's standard output
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;

    [[pipe fileHandleForReading] waitForDataInBackgroundAndNotify];
    NSLog(@"omriku sigining to notif..");
    // Register for notifications when new data is available to read
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(receivedData:)
                                                name:NSFileHandleDataAvailableNotification
                                            object:[pipe fileHandleForReading]];

    // Start the task
    [task launch];
 }

- (void)receivedData:(NSNotification *)notification {
    // Read the data from the pipe
    NSData *data = [[notification object] availableData];

    // Convert the data to a string
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //NSLog(@"omriku Output: %@", output);

    // Check the percentage
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\[(\\d+)%\\]" options:0 error:nil];
    NSArray *matches = [regex matchesInString:output options:0 range:NSMakeRange(0, output.length)];
    for (NSTextCheckingResult *match in matches) {
        // Extract the percentage from the match
        NSString *percentage = [output substringWithRange:[match rangeAtIndex:1]];
        NSLog(@"omriku Percentage: %@%%", percentage);
        if ([percentage containsString:@"100"]) {
            NSLog(@"omriku have 100!");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self populateTableWithExistingApps];
            });
        }
    }

    // Register for notifications again
    [[notification object] waitForDataInBackgroundAndNotify];
}

@end
