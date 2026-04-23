#ifndef WailsIconLoader_h
#define WailsIconLoader_h

#import <Cocoa/Cocoa.h>

@interface WailsIconLoader : NSObject

- (NSImage *)loadIcon:(NSString *)iconName;

@end

#endif /* WailsIconLoader_h */