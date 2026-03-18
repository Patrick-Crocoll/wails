package native

type SidebarItem struct {
	Name string
	Icon *string
}

type SidebarGroup struct {
	Name     string
	Items    []SidebarItem
	Expanded bool
}
