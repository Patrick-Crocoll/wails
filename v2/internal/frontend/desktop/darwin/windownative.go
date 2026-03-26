//go:build darwin
// +build darwin

package darwin

import (
	"sync"

	"github.com/wailsapp/wails/v2/pkg/native"
)

var (
	sidebarController    SidebarController
	initSBCOnce          sync.Once
	sbModelRefreshLock   sync.Mutex
	sidebarItemIdCounter int
)

type SidebarGroupToggleState struct {
	groupId   int
	collapsed bool
}

var (
	sidebarItemSelectBuffer       = make(chan int, 10)
	sidebarGroupToggleStateBuffer = make(chan SidebarGroupToggleState, 10)
)

func (w *Window) SetNativeElements(ne *native.Native) {
	if ne == nil {
		return
	}
	w.setupSidebar(ne.Sidebar)
	// Code for more native support goes here ...
}

type SidebarController struct {
	w             *Window
	modelProvider native.SidebarModelProvider
	items         map[int]native.SidebarItem
	groups        map[int]native.SidebarGroup
}

func (s *SidebarController) Refresh() {
	if s.modelProvider != nil && s.w != nil {
		sbModelRefreshLock.Lock()
		defer sbModelRefreshLock.Unlock()
		s.items = make(map[int]native.SidebarItem)
		s.groups = make(map[int]native.SidebarGroup)
		sidebarItemIdCounter = -1
		model := CreateSidebarModel(
			s.modelProvider(),
			func(item native.SidebarItem) int {
				sidebarItemIdCounter++
				s.items[sidebarItemIdCounter] = item
				return sidebarItemIdCounter
			},
			func(group native.SidebarGroup) int {
				sidebarItemIdCounter++
				s.groups[sidebarItemIdCounter] = group
				return sidebarItemIdCounter
			},
		)
		SetContextSidebarModel(s.w.context, model)
	}
}

func (s *SidebarController) SetWidth(width int) {
	//TODO implement me
	panic("implement me")
}

func (s *SidebarController) Expand() {
	//TODO implement me
	panic("implement me")
}

func (s *SidebarController) Collapse() {
	//TODO implement me
	panic("implement me")
}

func (s *SidebarController) itemSelected(itemId int) {
	if _, found := s.items[itemId]; found {
		// FIXME: s.items is always nil... Why?
	}
}

func (s *SidebarController) startSidebarItemSelectedProcessor() {
	for selectedItem := range sidebarItemSelectBuffer {
		s.itemSelected(selectedItem)
	}
}

func (w *Window) setupSidebar(sidebar *native.Sidebar) {
	if sidebar == nil || sidebar.ModelProvider == nil {
		return
	}
	w.nativeSidebar = sidebar
	sbc := getSidebarController(w)
	sbc.modelProvider = sidebar.ModelProvider
	sbc.Refresh()
}

func getSidebarController(w *Window) SidebarController {
	initSBCOnce.Do(
		func() {
			sidebarController = SidebarController{
				w: w,
			}
			go sidebarController.startSidebarItemSelectedProcessor()
			SetSidebarCallbacks(w.context)
		},
	)
	return sidebarController
}
