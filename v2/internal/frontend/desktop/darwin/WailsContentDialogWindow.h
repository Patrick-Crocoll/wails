//
//  WailsContentDialogWindow.h
//

#import <Cocoa/Cocoa.h>

@interface WailsContentDialogWindow : NSWindow

@property(nonatomic, assign) BOOL runningModal;

- (instancetype)initWithWidth:(CGFloat)width
                       height:(CGFloat)height
                     closable:(BOOL)closable
                  minimizable:(BOOL)minimizable
                fullscreenable:(BOOL)fullscreenable;

- (void)configureWithTitle:(NSString *)title
                    width:(CGFloat)width
                   height:(CGFloat)height
                 closable:(BOOL)closable
              minimizable:(BOOL)minimizable
            fullscreenable:(BOOL)fullscreenable;

- (void)installContentView:(NSView *)view;

- (void)showModal:(BOOL)modal;

@end