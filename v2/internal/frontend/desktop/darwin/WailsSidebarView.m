#import "WailsSidebarView.h"

// A sidebar node can be either a group or an item
@interface WailsSidebarNode : NSObject

@property(nonatomic, retain) NSString *title;

@end

@implementation WailsSidebarNode

@synthesize title;

- (instancetype)init {
    self = [super init];
    if (self) {
        self->title = nil;
    }
    return self;
}

- (void)dealloc {
    [title release];
    [super dealloc];
}

@end

// A sidebar group contains items and can be expanded or collapsed
@interface WailsSidebarGroupNode : WailsSidebarNode

@property(nonatomic, assign) BOOL isExpanded;
@property(nonatomic, retain) NSMutableArray *children;

@end

@implementation WailsSidebarGroupNode

@synthesize isExpanded;
@synthesize children;

- (instancetype)init {
    self = [super init];
    if (self) {
        self->isExpanded = YES;
        self->children = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [children release];
    [super dealloc];
}

@end

// A sidebar item is a leaf node
@interface WailsSidebarItemNode : WailsSidebarNode

@property(nonatomic, retain) NSImage *icon;
@property(nonatomic, retain) NSColor *color;

@end

@implementation WailsSidebarItemNode

@synthesize icon;
@synthesize color;

- (instancetype)init {
    self = [super init];
    if (self) {
        self->icon = nil;
        self->color = nil;
    }
    return self;
}

- (void)dealloc {
    [icon release];
    [color release];
    [super dealloc];
}

@end

// WailsSidebarDataSource is a basic implementation of NSOutlineViewDataSource,
// using WailsSidebarViewModel as the source.
@interface WailsSidebarDataSource ()

@property(nonatomic, retain) NSMutableArray *rootNodes;

@end

@implementation WailsSidebarDataSource

@synthesize rootNodes;

- (instancetype)init {
    self = [super init];
    if (self) {
        self->rootNodes = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [rootNodes release];
    [super dealloc];
}

- (NSArray

<WailsSidebarNode *> *)nodesMatchingExpansionState:(BOOL)shouldBeExpanded {
    NSMutableArray < WailsSidebarNode * > *nodes = [NSMutableArray array];
    if ([self.rootNodes count] == 0) {
        return nodes;
    }
    NSInteger currentGroupIndex = 0;
    for (WailsSidebarNode *rootNode in self.rootNodes) {
        if (![rootNode isKindOfClass:[WailsSidebarGroupNode class]]) {
            // only groups can be expanded/collapsed
            continue;
        }
        WailsSidebarGroupNode *group = (WailsSidebarGroupNode *) rootNode;
        if (group.isExpanded == shouldBeExpanded) {
            [nodes addObject:rootNode];
        }
        currentGroupIndex++;
    }
    return nodes;
}

- (NSArray

<WailsSidebarNode *> *)expandedNodes {
    return [self nodesMatchingExpansionState:YES];
}

- (NSArray

<WailsSidebarNode *> *)collapsedNodes {
    return [self nodesMatchingExpansionState:NO];
}

#pragma mark - public methods

- (void)addUngroupedItemWithLabel:(NSString *)label iconName:(NSString *)iconName itemId:(int)itemId {
    WailsSidebarItemNode *node = [self createNodeWithTitle:label iconName:iconName];
    [self.rootNodes addObject:node];
    [node release];
}

- (void)addGroupWithTitle:(NSString *)title initiallyExpanded:(BOOL)expanded groupId:(int)groupId {
    WailsSidebarGroupNode *groupNode = [self createGroupWithTitle:title];
    groupNode.isExpanded = expanded;
    [self.rootNodes addObject:groupNode];
    [groupNode release];
}

- (void)addItemWithLabel:(NSString *)label iconName:(NSString *)iconName itemId:(int)itemId {
    // (1) Find the last group
    WailsSidebarGroupNode *lastGroup = nil;
    for (NSInteger i = [self.rootNodes count] - 1; i >= 0; i--) {
        id node = [self.rootNodes objectAtIndex:i];
        if ([node isKindOfClass:[WailsSidebarGroupNode class]]) {
            lastGroup = (WailsSidebarGroupNode *) node;
            break;
        }
    }
    // (2) there is no group? -> add to ungrouped items
    if (lastGroup == nil) {
        [self addUngroupedItemWithLabel:label iconName:iconName itemId:itemId];;
        return;
    }
    // (3) add to the group
    WailsSidebarItemNode *itemNode = [self createNodeWithTitle:label iconName:iconName];
    [lastGroup.children addObject:itemNode];
    [itemNode release];
}

#pragma mark - internal helpers

- (WailsSidebarGroupNode *)createGroupWithTitle:(NSString *)title {
    WailsSidebarGroupNode *node = [[WailsSidebarGroupNode alloc] init];
    node.title = title;
    return node;
}

- (WailsSidebarItemNode *)createNodeWithTitle:(NSString *)title iconName:(NSString *)iconName {
    WailsSidebarItemNode *node = [[WailsSidebarItemNode alloc] init];
    node.title = title;
    if ([self isSystemIconName:iconName]) {
        NSArray *parts = [self getSystemImageParts:iconName];
        node.icon = [self imageForSystemName:[parts objectAtIndex:0]];
        if ([parts count] > 1) {
            node.color = [self colorForColorString:[parts objectAtIndex:1]];
        }
    } else if ([self isImageFilePath:iconName]) {
        node.icon = [[[NSImage alloc] initWithContentsOfFile:iconName] autorelease];
    }
    if (node.icon == nil) {
        node.icon = [NSImage imageNamed:@"NSApplicationIcon"];
    } else {
        [node.icon setTemplate:YES];
    }
    return node;
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

#pragma mark - NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil) {
        return [self.rootNodes count];
    }
    if ([item isKindOfClass:[WailsSidebarGroupNode class]]) {
        WailsSidebarGroupNode *group = (WailsSidebarGroupNode *) item;
        return [group.children count];
    }
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    // (1) no parent? -> return the root node
    if (item == nil) {
        if (index < 0 || index >= [self.rootNodes count]) {
            return nil;
        }
        return [self.rootNodes objectAtIndex:index];
    }
    // (2) parent is a group? -> return the child of the group
    if (![item isKindOfClass:[WailsSidebarGroupNode class]]) {
        return nil;
    }
    WailsSidebarGroupNode *group = (WailsSidebarGroupNode *) item;
    if (index < 0 || index >= [group.children count]) {
        return nil;
    }
    return [group.children objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return [item isKindOfClass:[WailsSidebarGroupNode class]];
}

@end

// the private properties of WailsSidebarView
@interface WailsSidebarView ()

@property(nonatomic, retain) NSScrollView *scrollView;
@property(nonatomic, retain) NSOutlineView *outlineView;

@end

@implementation WailsSidebarView

// public properties
@synthesize onItemSelected;
@synthesize onGroupToggled;
// private properties
@synthesize scrollView;
@synthesize outlineView;

- (instancetype)initWithFrame:(NSRect)frameRect {
    return [self initWithFrame:frameRect model:nil];
}

- (instancetype)initWithFrame:(NSRect)frameRect model:(WailsSidebarDataSource *)model {
    self = [super initWithFrame:frameRect];
    if (self) {
        self->onItemSelected = nil;
        self->onGroupToggled = nil;
        _model = model;

        [self setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [self setWantsLayer:YES];
        [self.layer setBackgroundColor:[[NSColor windowBackgroundColor] CGColor]];

        NSScrollView *createdScrollView = [[NSScrollView alloc] initWithFrame:[self bounds]];
        [createdScrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [createdScrollView setBorderType:NSNoBorder];
        [createdScrollView setHasVerticalScroller:YES];
        [createdScrollView setHasHorizontalScroller:NO];
        [createdScrollView setDrawsBackground:NO];
        self.scrollView = createdScrollView;
        [createdScrollView release];

        NSOutlineView *createdOutlineView = [[NSOutlineView alloc] initWithFrame:[self bounds]];
        [createdOutlineView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [createdOutlineView setHeaderView:nil];
        [createdOutlineView setRowSizeStyle:NSTableViewRowSizeStyleDefault];
        if ([createdOutlineView respondsToSelector:@selector(setStyle:)]) {
            [createdOutlineView setStyle:NSTableViewStyleSourceList];
        } else {
            // This does not only change the selection highlight but makes the whole list look more macOS sidebar like...
            [createdOutlineView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
        }
        [createdOutlineView setFocusRingType:NSFocusRingTypeNone];
        [createdOutlineView setIndentationPerLevel:12.0];
        [createdOutlineView setGridStyleMask:NSTableViewGridNone];
        [createdOutlineView setIntercellSpacing:NSMakeSize(0.0, 0.0)];
        [createdOutlineView setFloatsGroupRows:NO];
        [createdOutlineView setDataSource:_model];
        [createdOutlineView setDelegate:self];

        NSTableColumn *column = [[[NSTableColumn alloc] initWithIdentifier:@"SidebarColumn"] autorelease];
        [column setWidth:[self bounds].size.width];
        [createdOutlineView addTableColumn:column];
        [createdOutlineView setOutlineTableColumn:column];

        self.outlineView = createdOutlineView;
        [createdOutlineView release];

        [self.scrollView setDocumentView:self.outlineView];
        [self addSubview:self.scrollView];

        [self reloadData];
    }
    return self;
}

- (void)dealloc {
    [_model release];
    [onItemSelected release];
    [onGroupToggled release];
    [scrollView release];
    [outlineView release];
    [super dealloc];
}

- (void)setModel:(WailsSidebarDataSource *)newModel {
    if (_model == newModel) {
        return;
    }
    [_model release];
    _model = [newModel retain];
    [self.outlineView setDataSource:_model];
    [self.outlineView reloadData];
}

- (void)setOnItemSelected:(WailsSidebarSelectionChangedHandler)newHandler {
    if (onItemSelected != newHandler) {
        [onItemSelected release];
        onItemSelected = [newHandler copy];
    }
}

- (void)setOnGroupToggled:(WailsSidebarGroupToggledHandler)newHandler {
    if (onGroupToggled != newHandler) {
        [onGroupToggled release];
        onGroupToggled = [newHandler copy];
    }
}

- (void)reloadData {
    [self.outlineView reloadData];
    [self expandNodes];
}

- (void)expandNodes {
    for (WailsSidebarNode *rootNode in _model.expandedNodes) {
        [self.outlineView expandItem:rootNode];
    }
    for (WailsSidebarNode *rootNode in _model.collapsedNodes) {
        [self.outlineView collapseItem:rootNode];
    }
}

#pragma mark - NSOutlineViewDelegate

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    return [item isKindOfClass:[WailsSidebarGroupNode class]];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    return [item isKindOfClass:[WailsSidebarItemNode class]];
}

- (NSTableCellView *)createBaseCellWithWidth:(CGFloat)width rowHeight:(CGFloat)height {
    NSTableCellView *cell = [[[NSTableCellView alloc] initWithFrame:NSMakeRect(0, 0, width, height)] autorelease];
    return cell;
}

- (NSTextField *)createBaseTextFieldWithFrame:(NSRect)frame {
    NSTextField *textField = [[[NSTextField alloc] initWithFrame:frame] autorelease];
    [textField setBezeled:NO];
    [textField setBordered:NO];
    [textField setDrawsBackground:NO];
    [textField setEditable:NO];
    [textField setSelectable:NO];
    return textField;
}

// Convert the WailsSidebarNode to a NSTableCellView, which is what NSOutlineView expects.
- (NSView *)outlineView:(NSOutlineView *)sidebarOutlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    // (1) group
    if ([item isKindOfClass:[WailsSidebarGroupNode class]]) {
        WailsSidebarGroupNode *node = (WailsSidebarGroupNode *) item;
        NSTableCellView *groupCell = [self createBaseCellWithWidth:tableColumn.width rowHeight:20.0];
        NSTextField *textField = [self createBaseTextFieldWithFrame:NSMakeRect(8, 1, tableColumn.width - 16, 16)];
        [textField setStringValue:node.title != nil ? node.title : @""];
        [textField setTextColor:[NSColor secondaryLabelColor]];
        [textField setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize] weight:NSFontWeightSemibold]];
        [groupCell setTextField:textField];
        [groupCell addSubview:textField];
        return groupCell;
    }
    if (![item isKindOfClass:[WailsSidebarItemNode class]]) {
        // Maybe log some error here?
        return nil;
    }
    WailsSidebarItemNode *node = (WailsSidebarItemNode *) item;
    // (2) item
    NSTableCellView *itemCell = [self createBaseCellWithWidth:tableColumn.width rowHeight:28.0];
    NSImageView *imageView = [[[NSImageView alloc] initWithFrame:NSMakeRect(6, 4, 16, 16)] autorelease];
    NSImage *resolvedImage = node.icon;
    [imageView setImage:resolvedImage];
    if (node.color != nil) {
        if (@available(macOS 10.14, *)) {
            if ([imageView respondsToSelector:@selector(setContentTintColor:)]) {
                [imageView setContentTintColor:node.color];
            }
        }
    }
    [imageView setImageScaling:NSImageScaleProportionallyDown];
    NSTextField *textField = [self createBaseTextFieldWithFrame:NSMakeRect(28, 3, tableColumn.width - 34, 18)];
    [textField setStringValue:node.title != nil ? node.title : @""];
    [textField setFont:[NSFont systemFontOfSize:13.0]];
    [textField setTextColor:[NSColor labelColor]];
    [itemCell setImageView:imageView];
    [itemCell setTextField:textField];
    [itemCell addSubview:imageView];
    [itemCell addSubview:textField];
    return itemCell;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
    return [item isKindOfClass:[WailsSidebarGroupNode class]] ? 20.0 : 28.0;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    NSInteger selectedRow = [self.outlineView selectedRow];
    if (selectedRow < 0) {
        return;
    }
    id item = [self.outlineView itemAtRow:selectedRow];
    if (item == nil) {
        return;
    }
    if ([item isKindOfClass:[WailsSidebarItemNode class]] && self.onItemSelected != nil) {
        WailsSidebarItemNode *node = (WailsSidebarItemNode *) item;
        self.onItemSelected(node.title);
    }
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification {
    id item = [[notification userInfo] objectForKey:@"NSObject"];
    if (item == nil) {
        return;
    }
    if ([item isKindOfClass:[WailsSidebarGroupNode class]] && self.onGroupToggled != nil) {
        WailsSidebarGroupNode *node = (WailsSidebarGroupNode *) item;
        self.onGroupToggled(node.title, YES);
    }
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification {
    id item = [[notification userInfo] objectForKey:@"NSObject"];
    if (item == nil) {
        return;
    }
    if ([item isKindOfClass:[WailsSidebarGroupNode class]] && self.onGroupToggled != nil) {
        WailsSidebarGroupNode *node = (WailsSidebarGroupNode *) item;
        self.onGroupToggled(node.title, NO);
    }
}

@end