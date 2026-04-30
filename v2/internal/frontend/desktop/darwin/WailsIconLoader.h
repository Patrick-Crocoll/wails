#ifndef WailsIconLoader_h
#define WailsIconLoader_h

#import <Cocoa/Cocoa.h>

@interface WailsIconLoader : NSObject

- (NSImage *)loadIcon:(NSString *)iconName;
- (NSImage *)loadIcon:(NSString *)iconName withPreferredHeight:(CGFloat)height;
- (NSImage *)imageWithReducedAlpha:(NSImage *)src fraction:(double)alpha;

@end

#endif /* WailsIconLoader_h */