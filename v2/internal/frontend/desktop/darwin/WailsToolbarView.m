#import "WailsToolbarView.h"
#import "WailsIconLoader.h"

static const CGFloat WailsToolbarButtonHeight = 44.0;
static const CGFloat WailsToolbarIconHeight = 32.0;
static const CGFloat WailsToolbarSpacing = 6.0;
static const CGFloat WailsToolbarSpacerWidth = 20.0;

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

// returns a UI button with from this definition of a button.
- (NSButton *)toImageButton:(WailsIconLoader *)iconLoader {
    NSButton *button = [[NSButton alloc] init];
    [button setBordered:YES];
    [button setBezelStyle:NSBezelStyleRegularSquare];
    [button setShowsBorderOnlyWhileMouseInside:YES];
    [button setTranslatesAutoresizingMaskIntoConstraints:NO];
    [button.heightAnchor constraintEqualToConstant:WailsToolbarButtonHeight].active = YES;
    NSImage *icn = [iconLoader loadIcon:self.icon withPreferredHeight:WailsToolbarIconHeight];
    if (icn != nil) {
        [button setImage:icn];
    }
    [button setTitle:@""];
    [button setTag:self.id];
    return button;
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

- (void)addButtonWithLabel:(NSString *)label isSelected:(BOOL)selected andIcon:(NSString *)icon andId:(int)buttonId {
    WailsToolbarButton *button = [[WailsToolbarButton alloc] init];
    button.label = label;
    button.icon = icon;
    button.id = buttonId;
    button.isSelected = selected;
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

- (void)addMenuItem:(NSString *)item isSeparator:(BOOL)separator isSelected:(BOOL)selected andId:(int)itemId {
    if (self.currentMenuButton == nil) {
        return;
    }
    WailsToolbarMenuItem *menuItem = [[WailsToolbarMenuItem alloc] init];
    menuItem.label = item;
    menuItem.id = itemId;
    menuItem.isSeparator = separator;
    menuItem.isSelected = selected;
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
@property(nonatomic, retain) NSStackView *stack;
@property(nonatomic, retain) NSView *firstStretchSpacer;

@end

@interface WailsToolbarButtonGroupView : NSView

@property(nonatomic, retain) NSMutableArray<NSButton *> *buttons;
@property(nonatomic, retain) NSTrackingArea *trackingArea; // for highlight of the View
@property(nonatomic, assign) id target;
@property(nonatomic, assign) SEL action;

- (instancetype)initWithButtonGroup:(WailsToolbarButtonGroup *)group
                         iconLoader:(WailsIconLoader *)iconLoader
                             target:(id)target
                             action:(SEL)action;

@end

@implementation WailsToolbarView

// public properties
@synthesize onButtonClicked;
@synthesize onChangeText;
// private properties
@synthesize iconLoader;
@synthesize stack;
@synthesize firstStretchSpacer;

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
            [effectView setMaterial:NSVisualEffectMaterialContentBackground];
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
        // Add the stack view that will hold the buttons etc
        self.stack = [[NSStackView alloc] initWithFrame:self.bounds];
        self.stack.orientation = NSUserInterfaceLayoutOrientationHorizontal;
        self.stack.alignment = NSLayoutAttributeCenterY;
        self.stack.spacing = WailsToolbarSpacing;
        self.stack.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.stack];
        [NSLayoutConstraint activateConstraints:@[
                [self.stack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:8.0],
                [self.stack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-8.0],
                [self.stack.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]
        ]];
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
    for (WailsToolbarItem *item in self.model.items) {
        if ([item isKindOfClass:[WailsToolbarMenuButton class]]) {
            WailsToolbarMenuButton *btn = (WailsToolbarMenuButton *) item;
            NSPopUpButton *popupButton = [[NSPopUpButton alloc] init];
            [popupButton setBordered:YES];
            [popupButton setBezelStyle:NSBezelStyleRegularSquare];
            [popupButton setShowsBorderOnlyWhileMouseInside:YES];
            [popupButton.heightAnchor constraintEqualToConstant:WailsToolbarButtonHeight].active = YES;
            [popupButton addItemWithTitle:@""];
            [popupButton setPullsDown:YES];
            NSImage *icn = [iconLoader loadIcon:btn.icon withPreferredHeight:WailsToolbarIconHeight];
            if (icn != nil) {
                icn = [iconLoader imageWithReducedAlpha:icn fraction:0.6];
                [[popupButton itemAtIndex:0] setImage:icn];
            }
            for (WailsToolbarMenuItem *menuItem in btn.menuItems) {
                if (menuItem.isSeparator) {
                    [[popupButton menu] addItem:[NSMenuItem separatorItem]];
                } else {
                    [popupButton addItemWithTitle:menuItem.label];
                    NSMenuItem *nsMenuItem = [popupButton lastItem];
                    [nsMenuItem setTag:menuItem.id];
                    [nsMenuItem setTarget:self];
                    [nsMenuItem setAction:@selector(toolbarMenuItemClicked:)];
                    [nsMenuItem setState:(menuItem.isSelected ? NSControlStateValueOn : NSControlStateValueOff)];
                }
            }
            [self.stack addArrangedSubview:popupButton];
            [popupButton release];
        } else if ([item isKindOfClass:[WailsToolbarTextField class]]) {
            WailsToolbarTextField *textFieldItem = (WailsToolbarTextField *) item;
            NSSearchField *textField = [[NSSearchField alloc] init];
            [textField setTag:textFieldItem.id];
            [textField setDelegate:self];
            [textField setTarget:self];
            [textField setAction:@selector(toolbarTextFieldChanged:)];
            [textField setSendsSearchStringImmediately:YES];
            [textField setTranslatesAutoresizingMaskIntoConstraints:NO];
            [textField.heightAnchor constraintEqualToConstant:28.0].active = YES;
            [textField.widthAnchor constraintEqualToConstant:180.0].active = YES;
            if (!textFieldItem.isSearchField) {
                NSSearchFieldCell *cell = (NSSearchFieldCell *) [textField cell];
                [cell setSearchButtonCell:nil];
            }
            [self.stack addArrangedSubview:textField];
            [textField release];
        } else if ([item isKindOfClass:[WailsToolbarButton class]]) {
            WailsToolbarButton *btn = (WailsToolbarButton *) item;
            [self addButton:btn andIconHeight:WailsToolbarIconHeight];
        } else if ([item isKindOfClass:[WailsToolbarButtonGroup class]]) {
            WailsToolbarButtonGroup *grp = (WailsToolbarButtonGroup *) item;
            WailsToolbarButtonGroupView *groupView = [[WailsToolbarButtonGroupView alloc]
                    initWithButtonGroup:grp
                             iconLoader:self.iconLoader
                                 target:self
                                 action:@selector(toolbarButtonClicked:)];
            [self.stack addArrangedSubview:groupView];
            [groupView release];
        } else if ([item isKindOfClass:[WailsToolbarItem class]]) {
            WailsToolbarItem *basicItem = (WailsToolbarItem *) item;
            if (basicItem.isSeparator) {
                NSView *stretch = [[NSView alloc] initWithFrame:NSZeroRect];
                [stretch setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
                [self.stack addArrangedSubview:stretch];
                // Make this stretchy spacer the same size as the first stretchy spacer
                if (self.firstStretchSpacer == nil) {
                    self.firstStretchSpacer = stretch;
                } else {
                    [stretch.widthAnchor constraintEqualToAnchor:self.firstStretchSpacer.widthAnchor].active = YES;
                }
                [stretch release];
            } else {
                if ([WailsToolbarView isStringEmpty: basicItem.label]) {
                    NSView *spacer = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, WailsToolbarSpacerWidth, 1)];
                    [spacer.widthAnchor constraintEqualToConstant:WailsToolbarSpacerWidth].active = YES;
                    [self.stack addArrangedSubview:spacer];
                    [spacer release];
                } else {
                    NSTextField *label = [NSTextField labelWithString:(basicItem.label != nil ? basicItem.label : @"")];
                    [label sizeToFit];
                    [self.stack addArrangedSubview:label];
                    [label release];
                }
            }
        }
    }
}

- (void)addButton:(WailsToolbarButton *)btn
      andIconHeight:(CGFloat)iconHeight {
    NSButton *nsButton = [btn toImageButton:self.iconLoader];
    [nsButton setTarget:self];
    [nsButton setAction:@selector(toolbarButtonClicked:)];
    [self.stack addArrangedSubview:nsButton];
    [nsButton setButtonType:NSButtonTypeMomentaryLight];
    [nsButton release];
}

- (void)toolbarButtonClicked:(NSButton *)sender {
    if (self.onButtonClicked == nil) {
        return;
    }
    self.onButtonClicked((int) sender.tag);
}

- (void)toolbarMenuItemClicked:(NSMenuItem *)sender {
    NSMenu *menu = [sender menu];
    for (NSMenuItem *item in [menu itemArray]) {
        if ([item isSeparatorItem]) {
            continue;
        }
        [item setState:(item == sender ? NSControlStateValueOn : NSControlStateValueOff)];
    }
    if (self.onButtonClicked == nil) {
        return;
    }
    self.onButtonClicked((int) sender.tag);
}

- (void)toolbarTextFieldChanged:(NSSearchField *)sender {
    if (self.onChangeText == nil) {
        return;
    }
    self.onChangeText((int) sender.tag, (char *) [[sender stringValue] UTF8String]);
}

- (void)controlTextDidChange:(NSNotification *)notification {
    id object = [notification object];
    if (![object isKindOfClass:[NSSearchField class]]) {
        return;
    }
    [self toolbarTextFieldChanged:(NSSearchField *) object];
}

+ (BOOL)isStringEmpty:(NSString *)string {
    if (string == nil || [string isKindOfClass:[NSNull class]]) {
        return YES;
    }
    // Trim whitespace and newlines, then check length
    NSString *trimmed = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return trimmed.length == 0;
}

@end

// A group of toggle buttons
@implementation WailsToolbarButtonGroupView

@synthesize buttons;
@synthesize trackingArea;
@synthesize target;
@synthesize action;

- (instancetype)initWithButtonGroup:(WailsToolbarButtonGroup *)group
                         iconLoader:(WailsIconLoader *)iconLoader
                             target:(id)buttonTarget
                             action:(SEL)buttonAction {
    self = [super init];
    if (self) {
        self.wantsLayer = YES;
        self.layer.cornerRadius = 6.0;
        self.layer.masksToBounds = YES;

        self.buttons = [[[NSMutableArray alloc] init] autorelease];
        self.target = buttonTarget;
        self.action = buttonAction;

        NSStackView *stack = [[NSStackView alloc] init];
        stack.orientation = NSUserInterfaceLayoutOrientationHorizontal;
        stack.alignment = NSLayoutAttributeCenterY;
        stack.spacing = 2.0;
        stack.translatesAutoresizingMaskIntoConstraints = NO;

        [self addSubview:stack];

        [NSLayoutConstraint activateConstraints:@[
                [stack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
                [stack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
                [stack.topAnchor constraintEqualToAnchor:self.topAnchor],
                [stack.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
        ]];

        BOOL addSeparator = NO;

        for (WailsToolbarButton *definition in group.buttons) {
            // separator line between buttons
            if (@available(macOS 10.14, *)) {
                if (addSeparator) {
                    NSView *separator = [[NSView alloc] init];
                    [separator setTranslatesAutoresizingMaskIntoConstraints:NO];
                    [separator setWantsLayer:YES];
                    [separator.layer setBackgroundColor:[[[NSColor lightGrayColor] colorWithAlphaComponent:0.1] CGColor]];
                    [stack addArrangedSubview:separator];
                    // Set fixed width (1pt), height comes from stack
                    [separator.widthAnchor constraintEqualToConstant:1].active = YES;
                    [separator release];
                }
            }
            addSeparator = YES;
            // Add the button
            NSButton *button = [definition toImageButton:iconLoader];
            [self.buttons addObject:button];
            [button setTarget:self];
            [button setAction:@selector(groupButtonClicked:)];
            [button.widthAnchor constraintEqualToConstant:WailsToolbarButtonHeight].active = YES;
            [button setButtonType:NSButtonTypeToggle];
            if (definition.isSelected) {
                [button setState:NSControlStateValueOn];
            }
            [stack addArrangedSubview:button];
            [button release];
        }
        [self invalidateIntrinsicContentSize];
        [stack release];
        [self highlightSelectedButton];
    }
    return self;
}

- (void)dealloc {
    [trackingArea release];
    [buttons release];
    [super dealloc];
}

- (NSSize)intrinsicContentSize {
    NSSize size = [super intrinsicContentSize];
    size.height = WailsToolbarButtonHeight;
    return size;
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    if (self.trackingArea != nil) {
        [self removeTrackingArea:self.trackingArea];
        self.trackingArea = nil;
    }
    self.trackingArea = [[[NSTrackingArea alloc] initWithRect:NSZeroRect
                                                      options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways | NSTrackingInVisibleRect
                                                        owner:self
                                                     userInfo:nil] autorelease];
    [self addTrackingArea:self.trackingArea];
}

- (void)mouseEntered:(NSEvent *)event {
    self.layer.backgroundColor = [[[NSColor lightGrayColor] colorWithAlphaComponent:0.1] CGColor];
}

- (void)mouseExited:(NSEvent *)event {
    self.layer.backgroundColor = nil;
}

- (void)groupButtonClicked:(NSButton *)sender {
    for (NSButton *button in self.buttons) {
        [button setState:(button == sender ? NSControlStateValueOn : NSControlStateValueOff)];
    }
    if (self.target != nil && self.action != nil && [self.target respondsToSelector:self.action]) {
        [NSApp sendAction:self.action to:self.target from:sender];
    }
    [self highlightSelectedButton];
}

- (void)highlightSelectedButton {
    for (NSButton *button in self.buttons) {
        if (button.state == NSControlStateValueOn) {
            if (@available(macOS 10.14, *)) {
                [button setWantsLayer:YES];
                [button.layer setBackgroundColor:[[[NSColor lightGrayColor] colorWithAlphaComponent:0.15] CGColor]];
            } else {
                button.showsBorderOnlyWhileMouseInside = NO;
            }
        } else {
            if (@available(macOS 10.14, *)) {
                [button.layer setBackgroundColor:Nil];
            } else {
                button.showsBorderOnlyWhileMouseInside = YES;
            }
        }
    }
}

@end