//
// Created by Ryan Harter on 6/1/16.
// Copyright (c) 2016 Pixite Apps LLC. All rights reserved.
//

#import "PIXPhotoUtils.h"


@implementation PIXPhotoUtils {

}

+ (NSString *)flattenHTML:(NSString *)html {

    NSScanner *thescanner;
    NSString *text = nil;

    thescanner = [NSScanner scannerWithString:html];

    while ([thescanner isAtEnd] == NO) {

        // find start of tag
        [thescanner scanUpToString:@"<" intoString:nil] ;

        // find end of tag
        [thescanner scanUpToString:@">" intoString:&text] ;

        // replace the found tag with a space
        //(you can filter multi-spaces out later if you wish)
        html = [html stringByReplacingOccurrencesOfString:[ NSString stringWithFormat:@"%@>", text] withString:@""];
        html = [html stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
        html = [html stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
        html = [html stringByReplacingOccurrencesOfString: @"&lt;" withString: @"<"];
        html = [html stringByReplacingOccurrencesOfString: @"&gt;" withString: @">"];
    }

    return html;

}

@end
