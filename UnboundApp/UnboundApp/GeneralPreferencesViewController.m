
#import "GeneralPreferencesViewController.h"
#import "PIXFileParser.h"
#import "PIXAppDelegate.h"
#import "PIXDefines.h"
#import "PIXLeapInputManager.h"
#import "PIXLeapTutorialWindowController.h"

@interface GeneralPreferencesViewController ()

@property NSURL * pickerStartURL;
@property (weak) IBOutlet NSButton * dbFolderButton;
@property (weak) IBOutlet NSTextField * folderDisplay;

@property (weak) IBOutlet NSImageView * leapStatus;
@property (weak) IBOutlet NSTextField * leapStatusText;

@property (strong) IBOutlet NSProgressIndicator * workingSpinner;

@end

@implementation GeneralPreferencesViewController

- (id)init
{
    return [super initWithNibName:@"GeneralPreferencesView" bundle:nil];
}

-(void)awakeFromNib
{
    // set the folder display
    
    [self updateFolderFeild];
    [self updateLeapInfo];
    
    [[PIXLeapInputManager sharedInstance] addObserver:self forKeyPath:@"isConnected" options:NSKeyValueObservingOptionNew context:nil];
    
    [self.workingSpinner bind:@"animate"
                     toObject:[PIXFileParser sharedFileParser]
                  withKeyPath:@"isWorking"
                      options: nil]; //@{NSValueTransformerNameBindingOption : NSNegateBooleanTransformerName}];
    
    
}

-(void)updateFolderFeild
{
    NSArray * directoryURLs = [[PIXFileParser sharedFileParser] observedDirectories];
    
    if([directoryURLs count])
    {
        self.folderDisplay.stringValue = [(NSURL *)[directoryURLs objectAtIndex:0] path];
    }
    
    else
    {
        self.folderDisplay.stringValue = @"No Folders Observed!";
    }
    
    // check to see if the dropbox folder exits
    NSURL * dropboxPhotosFolder = [[PIXFileParser sharedFileParser] defaultDBFolder];
    
    NSNumber * isDirectory;
    [dropboxPhotosFolder getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
    
    // if there is no dropbox photos folder or it's already selected then remove that option
    if(![isDirectory boolValue] || [[dropboxPhotosFolder path] isEqualToString:self.folderDisplay.stringValue])
    {
        [self.dbFolderButton setHidden:YES];
    }
    

}

-(void)updateLeapInfo
{
    if([[PIXLeapInputManager sharedInstance] isConnected])
    {
        [self.leapStatus setImage:[NSImage imageNamed:@"greendot"]];
        [self.leapStatusText setStringValue:@"Leap Motion Controller Connected"];
    }
    
    else
    {
        [self.leapStatus setImage:[NSImage imageNamed:@"graydot"]];
        [self.leapStatusText setStringValue:@"Leap Motion Controller Not Connected"];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self updateLeapInfo];
}

#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)identifier
{
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"General", @"General Unbound Preferences");
}

-(IBAction)themeChanged:(id)sender
{
    // the user default (@"backgroundTheme") is changed through a binding. We just need to send out the notification

    [[NSNotificationCenter defaultCenter] postNotificationName:@"backgroundThemeChanged" object:nil];
}


- (IBAction)useDBDefaults:(id)sender
{
    [[PIXFileParser sharedFileParser] userChoseDropboxPhotosFolder];
    [self updateFolderFeild];
}

- (IBAction)chooseFolder:(id)sender
{
    [[PIXFileParser sharedFileParser] userChooseFolderDialog];    
    [self updateFolderFeild];
}

- (IBAction)reloadFiles:(id)sender
{
    [[PIXFileParser sharedFileParser] rescanFiles];
}

- (IBAction)showLeapTutorial:(id)sender
{    
    [[PIXAppDelegate sharedAppDelegate] showLeapTutorialPressed:sender];
}


-(void)dealloc
{
    [[PIXLeapInputManager sharedInstance] removeObserver:self forKeyPath:@"isConnected"];
}

@end
