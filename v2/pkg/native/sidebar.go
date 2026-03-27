package native

type SidebarElementValue interface {
	SidebarItem | SidebarGroup
}

type SidebarElement[T SidebarElementValue] struct {
	Index int
	Value T
}

type Sidebar struct {
	// description of the native sidebar

	ModelProvider SidebarModelProvider

	// callbacks from the sidebar

	OnControlReady SidebarControlHandler
	OnItemSelected SidebarItemSelectedHandler
	OnGroupToggled SidebarGroupToggledHandler
}

type SidebarModel struct {
	SidebarGroups []SidebarElement[SidebarGroup]
	SidebarItems  []SidebarElement[SidebarItem]
	WidthPixels   int
	IsExpanded    bool
}

type SidebarModelProvider func() SidebarModel

type SidebarItemSelectEvent struct {
	Item  *SidebarItem
	Group *SidebarGroup
}

type SidebarGroupToggleEvent struct {
	Group      *SidebarGroup
	IsExpanded bool
}

type SidebarControlHandler func(ctrl SidebarControl)

type SidebarItemSelectedHandler func(evt SidebarItemSelectEvent)
type SidebarGroupToggledHandler func(evt SidebarGroupToggleEvent)

// TODO: Do we have to return errors?

type SidebarControl interface {
	Refresh()
	SetWidth(width int)
	Expand()
	Collapse()
}
