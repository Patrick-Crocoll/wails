#import "WailsIconLoader.h"

@implementation WailsIconLoader

- (NSImage *)loadIcon:(NSString *)iconName {
    NSImage *image = nil;
    if ([self isSystemIconName:iconName]) {
        NSArray *parts = [self getSystemImageParts:iconName];
        image = [self imageForSystemName:[parts objectAtIndex:0]];
    } else if ([self isImageFilePath:iconName]) {
        image = [[[NSImage alloc] initWithContentsOfFile:iconName] autorelease];
    }
    if (image == nil) {
        image = [NSImage imageNamed:@"NSApplicationIcon"];
    } else {
        [image setTemplate:YES];
    }
    return image;
}

- (NSImage *)loadIcon:(NSString *)iconName withPreferredHeight:(CGFloat)height {
    if (height <= 0) {
        return nil;
    }
    NSImage *image = [self loadIcon:iconName];
    if (image == nil) {
        return nil;
    }
    if ([iconName hasPrefix:@"System:"]) {
        // Let the system handle scaling for system icons
        if (@available(macOS 11.0, *)) {
            NSImageSymbolConfiguration *config =
                    [NSImageSymbolConfiguration configurationWithPointSize:height
                                                                    weight:NSFontWeightRegular
                                                                     scale:NSImageSymbolScaleSmall];
            NSImage *configured = [image imageWithSymbolConfiguration:config];
            if (configured != nil) {
                image = configured;
            }
        }
        return image;
    }
    NSSize originalSize = [image size];
    if (originalSize.width <= 0 || originalSize.height <= 0) {
        return nil;
    }
    CGFloat aspectRatio = originalSize.width / originalSize.height;
    NSSize scaledSize = NSMakeSize(height * aspectRatio, height);
    NSImage *scaledImage = [[[NSImage alloc] initWithSize:scaledSize] autorelease];
    [scaledImage lockFocus];
    [image drawInRect:NSMakeRect(0, 0, scaledSize.width, scaledSize.height)
             fromRect:NSZeroRect
            operation:NSCompositingOperationSourceOver
             fraction:1.0
       respectFlipped:YES
                hints:@{NSImageHintInterpolation: @(NSImageInterpolationHigh)}];
    [scaledImage unlockFocus];
    [scaledImage setTemplate:[image isTemplate]];
    return scaledImage;
}

- (BOOL)isSystemIconName:(NSString *)iconName {
    return iconName != nil && [iconName hasPrefix:@"System:"];
}

- (BOOL)isImageFilePath:(NSString *)iconName {
    return iconName != nil && [iconName length] > 0 && ![self isSystemIconName:iconName];
}

- (NSArray *)getSystemImageParts:(NSString *)iconName {
    return [iconName componentsSeparatedByString:@"/"];
}

- (NSImage *)imageForSystemName:(NSString *)iconSystemName {
    if (iconSystemName == nil || [iconSystemName length] == 0) {
        return nil;
    }
    NSString *symbolName = iconSystemName;
    if ([symbolName hasPrefix:@"System:"]) {
        symbolName = [[symbolName substringFromIndex:[@"System:" length]]
                stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    return [self systemSymbolImageNamed:symbolName];
}

- (NSImage *)systemSymbolImageNamed:(NSString *)symbolName {
    Class imageClass = [NSImage class];
    SEL selector = NSSelectorFromString(@"imageWithSystemSymbolName:accessibilityDescription:");
    if ([imageClass respondsToSelector:selector]) {
        typedef NSImage *(*SymbolImageFunc)(id, SEL, NSString *, NSString *);
        SymbolImageFunc func = (SymbolImageFunc) [imageClass methodForSelector:selector];
        NSImage *image = func(imageClass, selector, symbolName, nil);
        [image setTemplate:YES];
        return image;
    }
    return [NSImage imageNamed:symbolName];
}

- (NSColor *)colorForColorString:(NSString *)colorString {
    if (colorString == nil) {
        return nil;
    }
    NSString *hexString = colorString;
    if ([hexString hasPrefix:@"Color:"]) {
        hexString = [[hexString substringFromIndex:[@"Color:" length]]
                stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    return [self colorFromHexString:hexString];
}

- (NSColor *)colorFromHexString:(NSString *)hexString {
    if (hexString == nil) {
        return nil;
    }
    NSString *hex = [hexString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    hex = [hex stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if ([hex length] != 6 && [hex length] != 8) {
        return nil;
    }
    unsigned int value = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hex];
    if (![scanner scanHexInt:&value]) {
        return nil;
    }
    CGFloat r = 0, g = 0, b = 0, a = 1.0;
    if ([hex length] == 6) {
        r = ((value >> 16) & 0xFF) / 255.0;
        g = ((value >> 8) & 0xFF) / 255.0;
        b = (value & 0xFF) / 255.0;
    } else {
        r = ((value >> 24) & 0xFF) / 255.0;
        g = ((value >> 16) & 0xFF) / 255.0;
        b = ((value >> 8) & 0xFF) / 255.0;
        a = (value & 0xFF) / 255.0;
    }
    return [NSColor colorWithCalibratedRed:r green:g blue:b alpha:a];
}

@end