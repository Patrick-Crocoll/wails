package darwin

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework Foundation -framework Cocoa -framework WebKit

#import <Foundation/Foundation.h>
#import "WailsToolbarView.h"
#import "WailsContext.h"  // For context

extern void GoOnButtonClicked(int buttonId);
extern void GoOnTextFieldChanged(int fieldId, char *text);

// C wrappers for Objective-C methods
void* NewToolbarModel(void) {
    return [[WailsToolbarModel alloc] init];
}

void ReleaseToolbarModel(void* ptr) {
    [(id)ptr release];
}

void SetToolbarCallbacks(void* ctx) {
    WailsContext* context = (WailsContext*)ctx;
    if (context.toolbar == nil) {
        // TODO: log?
        return;
    }
    context.toolbar.onButtonClicked = ^(int buttonId) {
        GoOnButtonClicked(buttonId);
    };
    context.toolbar.onChangeText = ^(int fieldId, char* text) {
        GoOnTextFieldChanged(fieldId, text);
    };
}
*/
import "C"
