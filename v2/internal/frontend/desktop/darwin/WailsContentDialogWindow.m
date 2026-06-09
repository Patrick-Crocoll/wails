//
//  WailsContentDialogWindow.m
//

#import "WailsContentDialogWindow.h"

@interface WailsContentDialogWindow ()

+ (NSWindowStyleMask)styleMaskClosable:(BOOL)closable
                           minimizable:(BOOL)minimizable
                        fullscreenable:(BOOL)fullscreenable;

@end

@implementation WailsContentDialogWindow

- (instancetype)initWithWidth:(CGFloat)width
                       height:(CGFloat)height
                     closable:(BOOL)closable
                  minimizable:(BOOL)minimizable
               fullscreenable:(BOOL)fullscreenable {
    CGFloat dialogWidth = width > 0 ? width : 600.0;
    CGFloat dialogHeight = height > 0 ? height : 400.0;
    NSWindowStyleMask styleMask = [WailsContentDialogWindow styleMaskClosable:closable
                                                                  minimizable:minimizable
                                                               fullscreenable:fullscreenable];
    self = [super initWithContentRect:NSMakeRect(0, 0, dialogWidth, dialogHeight)
                            styleMask:styleMask
                              backing:NSBackingStoreBuffered
                                defer:NO];
    if (self) {
        [self setReleasedWhenClosed:NO];
        if (fullscreenable) {
            [self setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
        } else {
            [self setCollectionBehavior:NSWindowCollectionBehaviorDefault];
        }
        [self center];
    }
    return self;
}

- (void)configureWithTitle:(NSString *)title
                     width:(CGFloat)width
                    height:(CGFloat)height
                  closable:(BOOL)closable
               minimizable:(BOOL)minimizable
            fullscreenable:(BOOL)fullscreenable {
    [self setTitle:title ?: @""];
    NSWindowStyleMask styleMask = [WailsContentDialogWindow styleMaskClosable:closable
                                                                  minimizable:minimizable
                                                               fullscreenable:fullscreenable];
    [self setStyleMask:styleMask];
    if (width > 0 && height > 0) {
        // negative is flag for: do not change the current size
        [self setContentSize:NSMakeSize(width, height)];
        [self center];
    }
    if (fullscreenable) {
        [self setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
    } else {
        [self setCollectionBehavior:NSWindowCollectionBehaviorDefault];
    }
}

- (void)installContentView:(NSView *)view {
    NSView *contentView = [self contentView];
    [contentView setSubviews:@[]];
    [view setFrame:[contentView bounds]];
    [view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [contentView addSubview:view];
}

+ (NSWindowStyleMask)styleMaskClosable:(BOOL)closable
                           minimizable:(BOOL)minimizable
                        fullscreenable:(BOOL)fullscreenable {
    NSWindowStyleMask styleMask = NSWindowStyleMaskTitled;
    if (closable) {
        styleMask |= NSWindowStyleMaskClosable;
    }
    if (minimizable) {
        styleMask |= NSWindowStyleMaskMiniaturizable;
    }
    if (fullscreenable) {
        styleMask |= NSWindowStyleMaskResizable;
    }
    return styleMask;
}

- (void)showModal:(BOOL)modal {
    [self makeKeyAndOrderFront:nil];
    if (modal) {
        self.runningModal = YES;
        [NSApp runModalForWindow:self];
        self.runningModal = NO;
    }
}

- (void)close {
    NSWindow *parentWindow = [self parentWindow];
    if (parentWindow != nil) {
        [parentWindow removeChildWindow:self];
    }
    if (self.runningModal) {
        self.runningModal = NO;
        [NSApp stopModal];
    }
    [super close];
}

@end