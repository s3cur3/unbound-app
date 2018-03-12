
#import "GeneralPreferencesViewController.h"
#import "PIXFileParser.h"
#import "PIXAppDelegate.h"
#import "PIXDefines.h"

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

    [self.workingSpinner bind:@"animate"
                     toObject:[PIXFileParser sharedFileParser]
                  withKeyPath:@"isWorking"
                      options: nil]; //@{NSValueTransformerNameBindingOption : NSNegateBooleanTransformerName}];
    
    
}

-(void)updateFolderFeild
{
    NSArray * directoryURLs = [[PIXFileParser sharedFileParser] observedDirectories];
    
    if([directoryURLs count]) {
        NSString *path = [(NSURL *) directoryURLs[0] path];
        self.folderDisplay.stringValue = path;
        self.folderDisplay.toolTip = path;
    } else {
        self.folderDisplay.stringValue = @"No Folders Observed!";
        self.folderDisplay.toolTip = @"";
    }
}

#pragma mark - MASPreferencesViewController

- (NSString *)viewIdentifier {
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage {
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel {
    return NSLocalizedString(@"preferences.general.title", @"General Unbound Preferences");
}

#pragma mark - IBActions

-(IBAction)themeChanged:(id)sender
{
    // the user default (@"backgroundTheme") is changed through a binding. We just need to send out the notification

    [[NSNotificationCenter defaultCenter] postNotificationName:@"backgroundThemeChanged" object:nil];
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

- (IBAction)resetAlerts:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"PIX_supressDeleteWarning"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"PIX_supressAlbumDeleteWarning"];
}

@end
