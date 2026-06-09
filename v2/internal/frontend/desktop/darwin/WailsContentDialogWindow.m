//
//  WailsContentDialogWindow.m
//

#import "WailsContentDialogWindow.h"

@implementation WailsContentDialogWindow

- (void)close {
    if (self.runningModal) {
        self.runningModal = NO;
        [NSApp stopModal];
    }
    [super close];
}

@end