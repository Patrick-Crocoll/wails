package native

type SidebarElementValue interface {
	SidebarItem | SidebarGroup
}

type SidebarElement[T SidebarElementValue] struct {
	Index int
	Value T
}

type Sidebar struct {
	SidebarGroups []SidebarElement[SidebarGroup]
	// The items that do not belong to any group
	SidebarItems []SidebarElement[SidebarItem]
}

type SidebarProvider func() Sidebar
