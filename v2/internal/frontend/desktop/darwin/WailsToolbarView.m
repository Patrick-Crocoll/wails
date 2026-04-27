#import "WailsToolbarView.h"
#import "WailsIconLoader.h"

// A toolbar item: Button, ButtonGroup, Button with menu, TextField
@interface WailsToolbarItem : NSObject

@property(nonatomic, retain) NSString *label;
@property(nonatomic, assign) int id;
@property(nonatomic, assign) BOOL isSelected;
@property(nonatomic, assign) BOOL isSeparator;

@end

@implementation WailsToolbarItem

@synthesize label;
@synthesize id;
@synthesize isSelected;
@synthesize isSeparator;

- (instancetype)init {
    self = [super init];
    if (self) {
        self->label = nil;
        self->id = -1;
        self->isSelected = NO;
        self->isSeparator = NO;
    }
    return self;
}

- (void)dealloc {
    [label release];
    [super dealloc];
}

@end

// menu item. Some buttons can have menus. This is one item in such a menu
@interface WailsToolbarMenuItem : WailsToolbarItem
@end

@implementation WailsToolbarMenuItem

- (instancetype)init {
    self = [super init];
    return self;
}

- (void)dealloc {
    [super dealloc];
}

@end

// A text field. Could be a search field (in which case it will display a magnifying glass icon)
@interface WailsToolbarTextField : WailsToolbarItem

@property(nonatomic, assign) BOOL isSearchField;

@end

@implementation WailsToolbarTextField

@synthesize isSearchField;

- (instancetype)init {
    self = [super init];
    if (self) {
        self->isSearchField = NO;
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

@end

// A simple button. Can define a menu
@interface WailsToolbarButton : WailsToolbarItem

@property(nonatomic, retain) NSString *icon;

@end

@implementation WailsToolbarButton

@synthesize icon;

- (instancetype)init {
    self = [super init];
    if (self) {
        self->icon = nil;
    }
    return self;
}

- (void)dealloc {
    [icon release];
    [super dealloc];
}

@end

// A toolbar button with a menu
@interface WailsToolbarMenuButton : WailsToolbarButton

@property(nonatomic, retain) NSMutableArray<WailsToolbarMenuItem *> *menuItems;

@end

@implementation WailsToolbarMenuButton

@synthesize menuItems;

- (instancetype)init {
    self = [super init];
    if (self) {
        self->menuItems = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [menuItems release];
    [super dealloc];
}

@end

// A group of buttons that can be toggled
@interface WailsToolbarButtonGroup : WailsToolbarItem

@property(nonatomic, retain) NSMutableArray<WailsToolbarButton *> *buttons;

@end

@implementation WailsToolbarButtonGroup

@synthesize buttons;

- (instancetype)init {
    self = [super init];
    if (self) {
        self->buttons = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [buttons release];
    [super dealloc];
}

@end

// private part of the model
@interface WailsToolbarModel ()

@property(nonatomic, retain) NSMutableArray<WailsToolbarItem *> *items;
@property(readonly, retain) WailsToolbarButtonGroup *currentGroup;
@property(readonly, retain) WailsToolbarMenuButton *currentMenuButton;

@end

@implementation WailsToolbarModel

@synthesize items;
@synthesize currentGroup;
@synthesize currentMenuButton;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.items = [[NSMutableArray < WailsToolbarItem * > alloc] init];
        self->currentGroup = nil;
        self->currentMenuButton = nil;
    }
    return self;
}

- (void)dealloc {
    [items release];
    [currentGroup release];
    [currentMenuButton release];
    [super dealloc];
}

- (void)addButtonWithLabel:(NSString *)label andIcon:(NSString *)icon andId:(int)buttonId {
    WailsToolbarButton *button = [[WailsToolbarButton alloc] init];
    button.label = label;
    button.icon = icon;
    button.id = buttonId;
    if (self.currentGroup != nil) {
        [self.currentGroup.buttons addObject:button];
    } else {
        [self.items addObject:button];
    }
    [button release];
}

- (void)startButtonGroupWidthName:(NSString *)name andId:(int)groupId {
    if (self.currentGroup != nil) {
        // I guess we just add the unfinished group to the list of items. Maybe we should log a warning?
        [self endButtonGroup];
    }
    WailsToolbarButtonGroup *group = [[WailsToolbarButtonGroup alloc] init];
    group.id = groupId;
    group.label = name;
    self->currentGroup = group;
}

- (void)endButtonGroup {
    if (self.currentGroup != nil) {
        [self.items addObject:self.currentGroup];
        [self.currentGroup release];
        self->currentGroup = nil;
    }
}

- (void)selectButtonInGroup:(int)groupId button:(int)buttonId {
    for (WailsToolbarItem *item in self.items) {
        if (![item isKindOfClass:[WailsToolbarButtonGroup class]] || item.id != groupId) {
            continue;
        }
        WailsToolbarButtonGroup *group = (WailsToolbarButtonGroup *) item;
        for (WailsToolbarButton *button in group.buttons) {
            if (button.id == buttonId) {
                button.isSelected = YES;
            } else {
                button.isSelected = NO;
            }
        }
    }
}

- (void)addLabel:(NSString *)label withId:(int)labelId {
    WailsToolbarItem *item = [[WailsToolbarItem alloc] init];
    item.label = label;
    item.id = labelId;
    [self.items addObject:item];
    [item release];
}

- (void)startButtonWithMenu:(NSString *)label andIcon:(NSString *)icon andId:(int)buttonId {
    if (self.currentMenuButton != nil) {
        [self endButtonWithMenu];
    }
    WailsToolbarMenuButton *button = [[WailsToolbarMenuButton alloc] init];
    button.label = label;
    button.icon = icon;
    button.id = buttonId;
    self->currentMenuButton = button;
}

- (void)endButtonWithMenu {
    if (self.currentMenuButton != nil) {
        [self.items addObject:self.currentMenuButton];
        [self.currentMenuButton release];
        self->currentMenuButton = nil;
    }
}

- (void)addMenuItem:(NSString *)item andId:(int)itemId {
    if (self.currentMenuButton == nil) {
        return;
    }
    WailsToolbarMenuItem *menuItem = [[WailsToolbarMenuItem alloc] init];
    menuItem.label = item;
    menuItem.id = itemId;
    [self.currentMenuButton.menuItems addObject:menuItem];
    [menuItem release];
}

- (void)selectMenuItem:(int)itemId {
    for (WailsToolbarItem *item in self.items) {
        if (![item isKindOfClass:[WailsToolbarMenuButton class]]) {
            continue;
        }
        WailsToolbarMenuButton *menuButton = (WailsToolbarMenuButton *) item;
        for (WailsToolbarMenuItem *menuItem in menuButton.menuItems) {
            if (menuItem.id == itemId) {
                menuItem.isSelected = YES;
            } else {
                menuItem.isSelected = NO;
            }
        }
    }
}

- (void)addSpacer {
    if (self.currentMenuButton != nil) {
        WailsToolbarMenuItem *menuItem = [[WailsToolbarMenuItem alloc] init];
        menuItem.isSeparator = YES;
        [self.currentMenuButton.menuItems addObject:menuItem];
        [menuItem release];
        return;
    }
    WailsToolbarItem *item = [[WailsToolbarItem alloc] init];
    item.isSeparator = YES;
    [self.items addObject:item];
    [item release];
}

- (void)addTextField:(BOOL)isSearchField withId:(int)fieldId {
    WailsToolbarTextField *textField = [[WailsToolbarTextField alloc] init];
    textField.isSearchField = isSearchField;
    textField.id = fieldId;
    [self.items addObject:textField];
    [textField release];
}

@end

@interface WailsToolbarView ()

@property(nonatomic, retain) WailsIconLoader *iconLoader;

@end

@implementation WailsToolbarView

// public properties
@synthesize onButtonClicked;
@synthesize onChangeText;
// private properties
@synthesize iconLoader;

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        _model = nil;
        self.iconLoader = [[WailsIconLoader alloc] init];
        [self setAutoresizingMask:NSViewWidthSizable | NSViewMinYMargin];
        [self setWantsLayer:YES];
        // Set background color using layer-backed view
        if (@available(macOS 10.14, *)) {
            // Use a visual effect view for automatic appearance updates
            NSVisualEffectView *effectView = [[NSVisualEffectView alloc] initWithFrame:[self bounds]];
            [effectView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
            // [effectView setMaterial:NSVisualEffectMaterialTitlebar]; // OK glass look ?
            [effectView setMaterial:NSVisualEffectMaterialContentBackground]; // Beschde!!!
            //[effectView setMaterial:NSVisualEffectMaterialHeaderView];
            //[effectView setBlendingMode:NSVisualEffectBlendingModeBehindWindow]; // ??
            //[effectView setBlendingMode:NSVisualEffectBlendingModeWithinWindow]; // ??
            [effectView setState:NSVisualEffectStateActive];
            [self addSubview:effectView];
            [effectView release];
        } else {
            [self.layer setBackgroundColor:[[NSColor windowBackgroundColor] CGColor]];
        }
        // Add separator line at bottom of toolbar
        NSBox *separatorLine = [[NSBox alloc] initWithFrame:NSMakeRect(0, 0, NSWidth([self bounds]), 1)];
        [separatorLine setBoxType:NSBoxSeparator];
        [separatorLine setAutoresizingMask:NSViewWidthSizable | NSViewMaxYMargin];
        [self addSubview:separatorLine];
        [separatorLine release];
    }
    return self;
}

- (void)dealloc {
    [_model release];
    [onButtonClicked release];
    [onChangeText release];
    [iconLoader release];
    [super dealloc];
}

- (void)setModel:(WailsToolbarModel *)newModel {
    if (_model == newModel) {
        return;
    }
    [_model release];
    _model = [newModel retain];
    [self initToolbar];
}

- (void)initToolbar {
    CGFloat x = 8.0;
    CGFloat y = 6.0;
    CGFloat buttonWidth = 40.0;
    CGFloat buttonHeight = 40.0;
    CGFloat spacing = 6.0;
    CGFloat iconHeight = 36.0;
    CGFloat defaultLabelWidth = 120.0;

    BOOL addSpace = NO;

    for (WailsToolbarItem *item in self.model.items) {
        if ([item isKindOfClass:[WailsToolbarButton class]]) {
            WailsToolbarButton *btn = (WailsToolbarButton *) item;
            NSButton *nsButton = [[NSButton alloc] initWithFrame:NSMakeRect(x, y, buttonWidth, buttonHeight)];
            [self addButton:nsButton withDefinition:btn andIconHeight:iconHeight andSpacerInFront:addSpace];
            addSpace = NO;
            x += buttonWidth + spacing;
        } else if ([item isKindOfClass:[WailsToolbarButtonGroup class]]) {
            WailsToolbarButtonGroup *grp = (WailsToolbarButtonGroup *) item;
            fprintf(stderr, "========================> (0) '%s' x: %f\n", grp.label.UTF8String, x);
            NSSegmentedControl *segmentedControl = [[NSSegmentedControl alloc] initWithFrame:NSMakeRect(x, y, buttonHeight*grp.buttons.count + (2*spacing), buttonHeight)];
            x += spacing;
            [segmentedControl setAutoresizingMask:0];
            [segmentedControl setSegmentCount:grp.buttons.count];
            [segmentedControl setSegmentStyle:NSSegmentStyleTexturedSquare];
            [segmentedControl setTrackingMode:NSSegmentSwitchTrackingSelectOne];
            if (@available(macOS 11.0, *)) {
                for (int i = 0; i < grp.buttons.count; i++) {
                    WailsToolbarButton *btn = grp.buttons[i];
                    NSImage *icon = [self.iconLoader loadIcon:btn.icon withPreferredHeight:iconHeight];
                    [segmentedControl setImage:icon forSegment:i];
                    [segmentedControl setWidth:buttonWidth forSegment:i];
                }
            }
            // Select the first segment by default
            [segmentedControl setSelectedSegment:0];
            [self addSubview:segmentedControl];
            [segmentedControl release];
        } else if ([item isKindOfClass:[WailsToolbarItem class]]) {
            WailsToolbarItem *basicItem = (WailsToolbarItem *) item;
            if (basicItem.isSeparator) {
                addSpace = YES;
            } else {
                NSTextField *label = [NSTextField labelWithString:(basicItem.label != nil ? basicItem.label : @"")];
                [label sizeToFit];
                NSRect frame = label.frame;
                frame.size.width = defaultLabelWidth;
                frame.origin.x = x;
                frame.origin.y = y + ((buttonHeight - NSHeight(frame)) / 2.0);
                label.frame = frame;
                [self addSubview:label];
                fprintf(stderr, "========================> (1) '%s' x: %f\n", basicItem.label.UTF8String, x);
                x += NSWidth(label.frame) + spacing;
                fprintf(stderr, "========================> (2) '%s' x: %f\n", basicItem.label.UTF8String, x);
            }
        }
    }
}

- (void)addButton:(NSButton *)nsButton
   withDefinition:(WailsToolbarButton *)btn
      andIconHeight:(CGFloat)iconHeight
 andSpacerInFront:(BOOL)spacerInFront {
    [nsButton setBordered:YES];
    [nsButton setBezelStyle:NSBezelStyleRegularSquare];
    [nsButton setShowsBorderOnlyWhileMouseInside:YES];
    [nsButton setButtonType:NSButtonTypeMomentaryLight];
    [nsButton setTarget:self];
    [nsButton setAction:@selector(toolbarButtonClicked:)];
    [nsButton setTag:btn.id];
    NSImage *icon = [self.iconLoader loadIcon:btn.icon withPreferredHeight:iconHeight];
    [nsButton setImage:icon];
    [nsButton setTitle:@""];
    [self addSubview:nsButton];
    [nsButton release];
    // Add a spacer between the button and the previous button if requested
    if (spacerInFront) {
        NSControl *lastControl = nil;
        for (NSView *subview in [self.subviews reverseObjectEnumerator]) {
            if ([subview isKindOfClass:[NSControl class]]) {
                lastControl = (NSControl *)subview;
                break;
            }
        }
        if (lastControl == nil) {
            return;
        }
        NSLayoutConstraint *spacingConstraint = [NSLayoutConstraint
                constraintWithItem:lastControl
                         attribute:NSLayoutAttributeTrailing
                         relatedBy:NSLayoutRelationEqual
                            toItem:nsButton
                         attribute:NSLayoutAttributeLeading
                        multiplier:1.0
                          constant:-20]; // Negative because trailing to leading
        spacingConstraint.priority = 250;
        [self addConstraint:spacingConstraint];
    }
}

- (void)toolbarButtonClicked:(NSButton *)sender {
    if (self.onButtonClicked == nil) {
        return;
    }
    self.onButtonClicked((int) sender.tag);
}

@end