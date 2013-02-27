
#import "DebugPrefrencesViewController.h"
#import "PIXAppDelegate.h"
#import "PIXFileParser.h"
#import "PIXDefines.h"
#import "PIXPhoto.h"

@interface  DebugPrefrencesViewController()

@property (weak) IBOutlet NSTextField * albumCount;
@property (weak) IBOutlet NSTextField * photoCount;
@property (weak) IBOutlet NSTextField * photoThumbCount;
@property (weak) IBOutlet NSTextField * photoExifCount;
@property (weak) IBOutlet NSTextField * dbFileSize;


@end

@implementation DebugPrefrencesViewController

- (id)init
{
    return [super initWithNibName:@"DebugPreferencesView" bundle:nil];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    [self.workingSpinner bind:@"animate"
                     toObject:[PIXFileParser sharedFileParser]
                  withKeyPath:@"isWorking"
                      options: nil]; //@{NSValueTransformerNameBindingOption : NSNegateBooleanTransformerName}];
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


-(IBAction)clearDB:(id)sender
{
    [[PIXAppDelegate sharedAppDelegate] clearDatabase];
}

-(IBAction)scanFullDirectoryStructure:(id)sender
{
    [[PIXFileParser sharedFileParser] scanFullDirectory];
}


-(IBAction)updateCounts:(id)sender
{
    NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kAlbumEntityName];
    
    NSUInteger countResult = [[[PIXAppDelegate sharedAppDelegate] managedObjectContext] countForFetchRequest:fetchRequest error:nil];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
    
    NSString *albumCountString = [numberFormatter stringFromNumber:[NSNumber numberWithLong:countResult]];
    
    [fetchRequest setEntity:[NSEntityDescription entityForName:kPhotoEntityName inManagedObjectContext:[[PIXAppDelegate sharedAppDelegate] managedObjectContext]]];
    
    countResult = [[[PIXAppDelegate sharedAppDelegate] managedObjectContext] countForFetchRequest:fetchRequest error:nil];
    
    NSString *photosCountString = [numberFormatter stringFromNumber:[NSNumber numberWithLong:countResult]];
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"exifData != NULL"]];
    
    countResult = [[[PIXAppDelegate sharedAppDelegate] managedObjectContext] countForFetchRequest:fetchRequest error:nil];
    
    NSString *photosExifCountString = [numberFormatter stringFromNumber:[NSNumber numberWithLong:countResult]];
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"thumbnail != NULL"]];
    
    countResult = [[[PIXAppDelegate sharedAppDelegate] managedObjectContext] countForFetchRequest:fetchRequest error:nil];
    
    NSString *photosThumbnailCountString = [numberFormatter stringFromNumber:[NSNumber numberWithLong:countResult]];
    
    NSURL *dbURL = [[[PIXAppDelegate sharedAppDelegate] applicationFilesDirectory]  URLByAppendingPathComponent:@"UnboundApp.sqlite"];
    
    NSNumber * fileSize = nil;
    [dbURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:nil];
    
    NSString * dbsizeString = [NSByteCountFormatter stringFromByteCount:[fileSize unsignedIntegerValue] countStyle:NSByteCountFormatterCountStyleFile];
    
    self.albumCount.stringValue = albumCountString;
    self.photoCount.stringValue = photosCountString;
    self.photoExifCount.stringValue = photosExifCountString;
    self.photoThumbCount.stringValue = photosThumbnailCountString;
    self.dbFileSize.stringValue = dbsizeString;
}

-(IBAction)load1kThumbs:(id)sender
{
    NSManagedObjectContext * context = [[PIXAppDelegate sharedAppDelegate] managedObjectContext];
    // fetch 1000 photos without thumbs
    NSFetchRequest * fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kPhotoEntityName];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"thumbnail == NULL"]];
    [fetchRequest setFetchLimit:1000];
    
    NSArray * photos = [context executeFetchRequest:fetchRequest error:nil];
    
    for(PIXPhoto * photo in photos)
    {
        [photo thumbnailImage];
    }
    
    [context save:nil];
    
    [self updateCounts:nil];
}




@end
