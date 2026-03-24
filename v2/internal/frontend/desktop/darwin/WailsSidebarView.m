#import "WailsSidebarView.h"

// FIXME: Check formatting in other objective-c files and make sure this is consistent

@implementation WailsSidebarNode

@synthesize title;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self->title = nil;
    }
    return self;
}

- (void)dealloc
{
    [title release];
    [super dealloc];
}

@end

@implementation WailsSidebarGroupNode

@synthesize isExpanded;
@synthesize children;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self->isExpanded = YES;
        self->children = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [children release];
    [super dealloc];
}

@end

@implementation WailsSidebarItemNode

@synthesize icon;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self->icon = nil;
    }
    return self;
}

- (void)dealloc
{
    [icon release];
    [super dealloc];
}

@end

// implementation for WailsSidebarModel. Used to bridge to go code
@interface WailsSidebarModel ()

@property (nonatomic, retain) NSMutableArray *ungroupedItems;
@property (nonatomic, retain) NSMutableArray *groups;

@end

@implementation WailsSidebarModel

- (instancetype)init {
    self = [super init];
    if (self) {
        self.ungroupedItems = [[NSMutableArray alloc] init];
        self.groups = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [self.ungroupedItems release];
    [self.groups release];
    [super dealloc];
}

- (NSInteger)numberOfGroups {
    return [self.groups count];
}

- (WailsSidebarGroupNode *)groupAt:(NSInteger)groupIndex {
    if (groupIndex < 0 || groupIndex >= [self.groups count]) {
        return nil;
    }
    id node = [self.groups objectAtIndex:groupIndex];
    if (![node isKindOfClass:[WailsSidebarGroupNode class]]) {
        return nil;
    }
    return (WailsSidebarGroupNode *)node;
}

- (NSInteger)numberOfUngroupedItems {
    return [self.ungroupedItems count];
}

- (WailsSidebarItemNode *)ungroupedItemAt:(NSInteger)nodeIndex {
    if (nodeIndex < 0 || nodeIndex >= [self.ungroupedItems count]) {
        return nil;
    }
    id node = [self.ungroupedItems objectAtIndex:nodeIndex];
    if (![node isKindOfClass:[WailsSidebarItemNode class]]) {
        return nil;
    }
    return (WailsSidebarItemNode *)node;
}

#pragma mark - WailsSidebarDefaultModel

- (void)addUngroupedItemWithLabel:(NSString *)label iconName:(NSString *)iconName {
    WailsSidebarItemNode *node = [self createNodeWithTitle:label iconName:iconName];
    [self.ungroupedItems addObject:node];
    [node release];
}

- (void)addGroupWithTitle:(NSString *)title initiallyExpanded:(BOOL)expanded {
    WailsSidebarGroupNode *groupNode = [self createGroupWithTitle:title];
    groupNode.isExpanded = expanded;
    [self.groups addObject:groupNode];
    [groupNode release];
}

- (void)addItemWithLabel:(NSString *)label iconName:(NSString *)iconName {
    WailsSidebarGroupNode *lastGroup = [self.groups lastObject];
    if (lastGroup == nil) {
        return;
    }
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
    node.icon = [self imageForIconName:iconName];
    if (node.icon == nil) {
        node.icon = [NSImage imageNamed:@"NSApplicationIcon"];
    } else {
        [node.icon setTemplate:YES];
    }
    return node;
}

- (NSImage *)imageForIconName:(NSString *)iconName {
    if (iconName == nil || [iconName length] == 0) {
        return nil;
    }
    // (1) we support a special syntax for icon path. If it starts with "System:" we use the system symbol image.
    if ([iconName hasPrefix:@"System:"]) {
        NSString *symbolName = [[iconName substringFromIndex:[@"System:" length]]
                stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([symbolName length] == 0) {
            return nil;
        }
        return [self systemSymbolImageNamed:symbolName];
    }
    // (2) else we just load the image from the file system.
    return [[[NSImage alloc] initWithContentsOfFile:iconName] autorelease];
}

- (NSImage *)systemSymbolImageNamed:(NSString *)symbolName {
    Class imageClass = [NSImage class];
    SEL selector = NSSelectorFromString(@"imageWithSystemSymbolName:accessibilityDescription:");
    if ([imageClass respondsToSelector:selector]) {
        typedef NSImage *(*SymbolImageFunc)(id, SEL, NSString *, NSString *);
        SymbolImageFunc func = (SymbolImageFunc)[imageClass methodForSelector:selector];
        NSImage *image = func(imageClass, selector, symbolName, nil);
        [image setTemplate:YES];
        return image;
    }
    return [NSImage imageNamed:symbolName];
}

@end

// WailsSidebarDataSource is a basic implementation of NSOutlineViewDataSource,
// using WailsSidebarViewModel as the source.
@interface WailsSidebarDataSource : NSObject <NSOutlineViewDataSource>

@property (nonatomic, assign) id<WailsSidebarViewModel> model;
@property (nonatomic, retain) NSMutableArray *rootNodes;

- (void)reloadData;
- (NSInteger)groupIndexForRootNode:(WailsSidebarNode *)rootNode;

@end

@implementation WailsSidebarDataSource

@synthesize model;
@synthesize rootNodes;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self->model = nil;
        self->rootNodes = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [rootNodes release];
    [super dealloc];
}

#pragma mark - internal helpers

- (NSArray<WailsSidebarGroupNode *> *)nodesMatchingExpansionState:(BOOL)shouldBeExpanded
{
    NSMutableArray<WailsSidebarNode *> *nodes = [NSMutableArray array];
    if (self.model == nil || [self.rootNodes count] == 0) {
        return nodes;
    }
    NSInteger currentGroupIndex = 0;
    for (WailsSidebarNode *rootNode in self.rootNodes) {
        if (!rootNode.isGroup) {
            // only groups can be expanded/collapsed
            continue;
        }
        if ([self.model isGroupInitiallyExpandedAtIndex:currentGroupIndex] == shouldBeExpanded) {
            [nodes addObject:rootNode];
        }
        currentGroupIndex++;
    }
    return nodes;
}

- (NSArray<WailsSidebarNode *> *)expandedNodes
{
    return [self nodesMatchingExpansionState:YES];
}

- (NSArray<WailsSidebarNode *> *)collapsedNodes
{
    return [self nodesMatchingExpansionState:NO];
}

- (WailsSidebarNode *)buildNodeWithTitle:(NSString *)title icon:(NSImage *)icon isGroup:(BOOL)isGroup
{
    WailsSidebarNode *node = [[WailsSidebarNode alloc] init];
    node.isGroup = isGroup;
    node.title = title;
    node.icon = icon;
    return node;
}

- (void)appendNodeToParent:(NSMutableArray *)parent node:(WailsSidebarNode *)node
{
    [parent addObject:node];
    [node release];
}

// We use a custom setter for the model because we want to call reloadData when the model changes.
- (void)setModel:(id<WailsSidebarViewModel>)newModel
{
    if (model != newModel) {
        model = newModel;
        [self reloadData];
    }
}

- (void)reloadData
{
    [self.rootNodes removeAllObjects];
    id<WailsSidebarViewModel> activeModel = self.model;
    if (activeModel == nil) {
        return;
    }
    // (1) add all ungrouped items
    NSInteger ungroupedCount = [activeModel numberOfUngroupedItems];
    for (NSInteger i = 0; i < ungroupedCount; i++) {
        WailsSidebarNode *node = [self
                                  buildNodeWithTitle:[activeModel labelForUngroupedItemAtIndex:i]
                                                icon:[activeModel iconForUngroupedItemAtIndex:i]
                                             isGroup:NO];
        [self appendNodeToParent:self.rootNodes node:node];
    }
    // (2) add all groups, and all items in each group
    NSInteger groupCount = [activeModel numberOfGroups];
    for (NSInteger groupIndex = 0; groupIndex < groupCount; groupIndex++) {
        WailsSidebarNode *groupNode = [self
                                       buildNodeWithTitle:[activeModel titleForGroupAtIndex:groupIndex]
                                                     icon:nil
                                                  isGroup:YES];
        NSInteger itemCount = [activeModel numberOfItemsInGroupAtIndex:groupIndex];
        for (NSInteger itemIndex = 0; itemIndex < itemCount; itemIndex++) {
            WailsSidebarNode *itemNode = [self
                                          buildNodeWithTitle:[activeModel labelForItemAtIndex:itemIndex inGroupAtIndex:groupIndex]
                                                        icon:[activeModel iconForItemAtIndex:itemIndex inGroupAtIndex:groupIndex]
                                                     isGroup:NO];
            [self appendNodeToParent:groupNode.children node:itemNode];
        }

        [self appendNodeToParent:self.rootNodes node:groupNode];
    }
}

- (NSInteger)groupIndexForRootNode:(WailsSidebarNode *)rootNode
{
    NSInteger currentGroupIndex = 0;
    for (WailsSidebarNode *node in self.rootNodes) {
        if (!node.isGroup) {
            continue;
        }
        if (node == rootNode) {
            return currentGroupIndex;
        }
        currentGroupIndex++;
    }
    return NSNotFound;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == nil) {
        return [self.rootNodes count];
    }
    WailsSidebarNode *node = (WailsSidebarNode *)item;
    return [node.children count];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (item == nil) {
        return [self.rootNodes objectAtIndex:index];
    }
    WailsSidebarNode *node = (WailsSidebarNode *)item;
    return [node.children objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    WailsSidebarNode *node = (WailsSidebarNode *)item;
    return node.isGroup && [node.children count] > 0;
}

@end

// the private properties of WailsSidebarView
@interface WailsSidebarView ()

@property (nonatomic, retain) NSScrollView *scrollView;
@property (nonatomic, retain) NSOutlineView *outlineView;
@property (nonatomic, retain) WailsSidebarDataSource *dataSource;

@end

@implementation WailsSidebarView

// public properties
@synthesize onItemSelected;
@synthesize onGroupToggled;
// private properties
@synthesize scrollView;
@synthesize outlineView;
@synthesize dataSource;

- (instancetype)initWithFrame:(NSRect)frameRect
{
    return [self initWithFrame:frameRect model:nil];
}

- (instancetype)initWithFrame:(NSRect)frameRect model:(id<WailsSidebarViewModel>)sidebarModel
{
    self = [super initWithFrame:frameRect];
    if (self) {
        self->onItemSelected = nil;
        self->onGroupToggled = nil;
        self->dataSource = [[WailsSidebarDataSource alloc] init];

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
        [createdOutlineView setDataSource:self.dataSource];
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

- (void)dealloc
{
    [onItemSelected release];
    [onGroupToggled release];
    [scrollView release];
    [outlineView release];
    [dataSource release];
    [super dealloc];
}

- (void)setModel:(id<WailsSidebarViewModel>)newModel
{
    self.dataSource.model = newModel;
    [self.outlineView reloadData];
}

- (void)setOnItemSelected:(WailsSidebarSelectionChangedHandler)newHandler
{
    if (onItemSelected != newHandler) {
        [onItemSelected release];
        onItemSelected = [newHandler copy];
    }
}

- (void)setOnGroupToggled:(WailsSidebarGroupToggledHandler)newHandler
{
    if (onGroupToggled != newHandler) {
        [onGroupToggled release];
        onGroupToggled = [newHandler copy];
    }
}

- (void)reloadData
{
    [self.outlineView reloadData];
    [self expandNodes];
}

- (void)expandNodes
{
    for (WailsSidebarNode *rootNode in self.dataSource.expandedNodes) {
        [self.outlineView expandItem:rootNode];
    }
    for (WailsSidebarNode *rootNode in self.dataSource.collapsedNodes) {
        [self.outlineView collapseItem:rootNode];
    }
}

#pragma mark - NSOutlineViewDelegate

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
    WailsSidebarNode *node = (WailsSidebarNode *)item;
    return node.isGroup;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    WailsSidebarNode *node = (WailsSidebarNode *)item;
    return !node.isGroup;
}

- (NSTableCellView *)createBaseCellWithWidth:(CGFloat)width rowHeight:(CGFloat)height
{
    NSTableCellView *cell = [[[NSTableCellView alloc] initWithFrame:NSMakeRect(0, 0, width, height)] autorelease];
    return cell;
}

- (NSTextField *)createBaseTextFieldWithFrame:(NSRect)frame
{
    NSTextField *textField = [[[NSTextField alloc] initWithFrame:frame] autorelease];
    [textField setBezeled:NO];
    [textField setBordered:NO];
    [textField setDrawsBackground:NO];
    [textField setEditable:NO];
    [textField setSelectable:NO];
    return textField;
}

// Convert the WailsSidebarNode to a NSTableCellView, which is what NSOutlineView expects.
- (NSView *)outlineView:(NSOutlineView *)sidebarOutlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    WailsSidebarNode *node = (WailsSidebarNode *)item;

    if (node.isGroup) {
        NSTableCellView *groupCell = [self createBaseCellWithWidth:tableColumn.width rowHeight:20.0];
        NSTextField *textField = [self createBaseTextFieldWithFrame:NSMakeRect(8, 1, tableColumn.width - 16, 16)];
        [textField setStringValue:node.title != nil ? node.title : @""];
        [textField setTextColor:[NSColor secondaryLabelColor]];
        [textField setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize] weight:NSFontWeightSemibold]];
        [groupCell setTextField:textField];
        [groupCell addSubview:textField];
        return groupCell;
    }

    NSTableCellView *itemCell = [self createBaseCellWithWidth:tableColumn.width rowHeight:28.0];
    NSImageView *imageView = [[[NSImageView alloc] initWithFrame:NSMakeRect(6, 4, 16, 16)] autorelease];
    NSImage *resolvedImage = node.icon;
    [resolvedImage setTemplate:YES];
    [imageView setImage:resolvedImage];
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

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
    WailsSidebarNode *node = (WailsSidebarNode *)item;
    return node.isGroup ? 20.0 : 28.0;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger selectedRow = [self.outlineView selectedRow];
    if (selectedRow < 0) {
        return;
    }

    id item = [self.outlineView itemAtRow:selectedRow];
    if (item == nil) {
        return;
    }

    WailsSidebarNode *node = (WailsSidebarNode *)item;
    if (node.isGroup) {
        return;
    }

    if (self.onItemSelected != nil) {
        self.onItemSelected(node.title);
    }
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
    id item = [[notification userInfo] objectForKey:@"NSObject"];
    if (item == nil) {
        return;
    }

    WailsSidebarNode *node = (WailsSidebarNode *)item;
    if (!node.isGroup) {
        return;
    }

    if (self.onGroupToggled != nil) {
        self.onGroupToggled(node.title, YES);
    }
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
    id item = [[notification userInfo] objectForKey:@"NSObject"];
    if (item == nil) {
        return;
    }

    WailsSidebarNode *node = (WailsSidebarNode *)item;
    if (!node.isGroup) {
        return;
    }

    if (self.onGroupToggled != nil) {
        self.onGroupToggled(node.title, NO);
    }
}

@end