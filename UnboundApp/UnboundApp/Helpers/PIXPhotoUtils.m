//
// Created by Ryan Harter on 6/1/16.
// Copyright (c) 2016 Pixite Apps LLC. All rights reserved.
//

#import "PIXPhotoUtils.h"


void alert(NSString * title, NSString * message)
{
    NSAlert * alert = [[NSAlert alloc] init];
    alert.messageText = title;
    alert.informativeText = message;
    [alert runModal];
}

void alertCritical(NSString * title, NSString * message)
{
    NSAlert * alert = [[NSAlert alloc] init];
    alert.messageText = title;
    alert.informativeText = message;
    alert.alertStyle = NSAlertStyleCritical;
    [alert runModal];
}

enum modal_response cancellableAlert(NSString * title, NSString * message)
{
    NSAlert * alert = [[NSAlert alloc] init];
    alert.messageText = title;
    alert.informativeText = message;
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    return [alert runModal] == NSAlertSecondButtonReturn ? modal_response_cancel : modal_response_ok;
}

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
