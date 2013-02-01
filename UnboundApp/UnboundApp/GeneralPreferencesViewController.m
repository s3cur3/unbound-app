
#import "GeneralPreferencesViewController.h"

@implementation GeneralPreferencesViewController

- (id)init
{
    return [super initWithNibName:@"GeneralPreferencesView" bundle:nil];
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
    
    if([sender selectedColumn] == 0)
    {
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"backgroundTheme"];
    }
    
    else
    {
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"backgroundTheme"];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"backgroundThemeChanged" object:nil];
    

}

@end
