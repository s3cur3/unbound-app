//
//  PIXShareManager.m
//  UnboundApp
//
//  Created by Scott Sykora on 3/20/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXShareManager.h"
#import "PIXPhoto.h"
#import "PIXAlbum.h"

@interface PIXShareManager ()

@property NSArray * lastSharedItems;

@end

@implementation PIXShareManager

+ (PIXShareManager *)defaultShareManager
{
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

-(void)showShareSheetForItems:(NSArray *)items relativeToRect:(NSRect)rect ofView:(NSView *)view preferredEdge:(NSRectEdge)preferredEdge
{
    self.lastSharedItems = items;
    
    NSMutableArray * urls = [[NSMutableArray alloc] initWithCapacity:[items count]];
    
    for(id anItem in items)
    {
        if([anItem isKindOfClass:[PIXPhoto class]])
        {
            [urls addObject:[NSURL fileURLWithPath:[(PIXPhoto *)anItem path]]];
        }
        
        if([anItem isKindOfClass:[PIXAlbum class]])
        {
            [urls addObject:[NSURL fileURLWithPath:[(PIXAlbum *)anItem path]]];
        }
        
    }
    
    NSSharingServicePicker * picker = [[NSSharingServicePicker alloc] initWithItems:urls];
    picker.delegate = [PIXShareManager defaultShareManager];
    [picker showRelativeToRect:rect ofView:view preferredEdge:preferredEdge];
}

- (NSArray *)sharingServicePicker:(NSSharingServicePicker *)sharingServicePicker sharingServicesForItems:(NSArray *)items proposedSharingServices:(NSArray *)proposedServices
{
    return proposedServices;
}

- (id < NSSharingServiceDelegate >)sharingServicePicker:(NSSharingServicePicker *)sharingServicePicker delegateForSharingService:(NSSharingService *)sharingService
{
    return self;
}

- (void)sharingServicePicker:(NSSharingServicePicker *)sharingServicePicker didChooseSharingService:(NSSharingService *)service
{
    
}

@end
