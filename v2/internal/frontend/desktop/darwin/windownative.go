package darwin

import (
	"github.com/wailsapp/wails/v2/pkg/native"
)

func (w *Window) SetNativeElements(ne *native.Native) {
	if ne == nil {
		return
	}
	// (1) the native sidebar
	if ne.SidebarProvider != nil {
		provider := *ne.SidebarProvider
		model := CreateSidebarModel(provider())
		SetContextSidebarModel(w.context, model)
		// No need to release model here; ObjC retains it
	}
	// FIXME: Code for native support goes here
}
