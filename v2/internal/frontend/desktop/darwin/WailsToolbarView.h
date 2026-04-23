#ifndef WailsToolbarView_h
#define WailsToolbarView_h

#import <Cocoa/Cocoa.h>

// declaration of the callbacks
typedef void (^WailsToolbarButtonHandler)(int buttonId);
typedef void (^WailsToolbarTextFieldChangeHandler)(int fieldId, char* text);

// The description of the toolbar
@interface WailsToolbarModel : NSObject

- (void)addButtonWithLabel:(NSString *)label andIcon:(NSString *)icon andId:(int)buttonId;
- (void)startButtonGroupWidthName:(NSString *)name andId:(int)groupId;
- (void)endButtonGroup;
- (void)selectButtonInGroup:(int)groupId button:(int)buttonId;
- (void)addLabel:(NSString *)label withId:(int)labelId;
- (void)startButtonWithMenu:(NSString *)label andIcon:(NSString *)icon andId:(int)buttonId;
- (void)endButtonWithMenu;
- (void)addMenuItem:(NSString *)item andId:(int)itemId;
- (void)selectMenuItem:(int)itemId;
- (void)addSpacer;
- (void)addTextField:(BOOL)isSearchField;

@end

@interface WailsToolbarView : NSView

@property (nonatomic, retain) WailsToolbarModel *model;
@property (nonatomic, copy) WailsToolbarButtonHandler onButtonClicked;
@property (nonatomic, copy) WailsToolbarTextFieldChangeHandler onChangeText;

- (instancetype)initWithContainerView:(NSView *)containerView;
- (instancetype)initWithFrame:(NSRect)frameRect ;

@end

#endif /* WailsToolbarView_h */