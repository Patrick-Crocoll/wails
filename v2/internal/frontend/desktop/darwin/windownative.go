//go:build darwin
// +build darwin

package darwin

import (
	"github.com/wailsapp/wails/v2/pkg/native"
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
}

func (s *SidebarController) Refresh() {
	if s.modelProvider != nil && s.w != nil {
		model := CreateSidebarModel(s.modelProvider())
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

func (w *Window) setupSidebar(sidebar *native.Sidebar) {
	if sidebar == nil || sidebar.ModelProvider == nil {
		return
	}
	w.nativeSidebar = sidebar
	provider := sidebar.ModelProvider
	model := CreateSidebarModel(provider())
	SetContextSidebarModel(w.context, model)
	if sidebar.OnControlReady != nil {
		sidebarController := &SidebarController{
			w:             w,
			modelProvider: provider,
		}
		sidebar.OnControlReady(sidebarController)
	}
	SetSidebarTestCallbacks(w.context)
}
