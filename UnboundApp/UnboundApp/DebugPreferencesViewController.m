
#import "DebugPrefrencesViewController.h"


@interface  DebugPrefrencesViewController()

@end

@implementation DebugPrefrencesViewController

- (id)init
{
    return [super initWithNibName:@"DebugPreferencesView" bundle:nil];
}

#pragma mark - MASPreferencesViewController

- (NSString *)identifier
{
    return @"DebugPrefrences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNameCaution];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Debug", @"Unbound Debug Preferences");
}




@end
