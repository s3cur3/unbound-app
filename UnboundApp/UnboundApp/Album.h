//
//  Album.h
//  UnboundApp
//
//  Created by Bob on 12/13/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXObject.h"

@interface Album : PIXObject
{
    
}

@property (nonatomic, strong)   NSDate *dateLastScanned;
@property (nonatomic, strong)   NSDate *dateMostRecentPhoto;
@property (nonatomic, copy)     NSString *filePath;
@property (nonatomic, strong)   NSImage *thumbnailImage;
@property (nonatomic, copy)     NSString *title;

@property (nonatomic, strong)   NSMutableArray *photos;

- (id)initWithFilePath:(NSString *) aPath;
-(void)updatePhotosFromFileSystem;
- (NSString *)imageSubtitle;

-(BOOL)albumExistsWithPhotos;

@end
