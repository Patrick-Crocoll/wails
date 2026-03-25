package darwin

import (
	"sort"
	"unsafe"

	"github.com/wailsapp/wails/v2/pkg/native"
)

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework Foundation -framework Cocoa -framework WebKit

#import <Foundation/Foundation.h>
#import "WailsSidebarView.h"
#import "WailsContext.h"  // For context

// C wrappers for Objective-C methods
void* NewSidebarModel(void) {
    return [[WailsSidebarDataSource alloc] init];
}

void SidebarModelAddUngroupedItem(void* ptr, char* label, char* icon) {
    WailsSidebarDataSource* model = (WailsSidebarDataSource*)ptr;
    NSString* nsLabel = [NSString stringWithUTF8String:label];
    NSString* nsIcon = icon ? [NSString stringWithUTF8String:icon] : nil;
    [model addUngroupedItemWithLabel:nsLabel iconName:nsIcon];
}

void SidebarModelAddGroup(void* ptr, char* title, int expanded) {
    WailsSidebarDataSource* model = (WailsSidebarDataSource*)ptr;
    NSString* nsTitle = [NSString stringWithUTF8String:title];
    [model addGroupWithTitle:nsTitle initiallyExpanded:(BOOL)expanded];
}

void SidebarModelAddItem(void* ptr, char* label, char* icon) {
    WailsSidebarDataSource* model = (WailsSidebarDataSource*)ptr;
    NSString* nsLabel = [NSString stringWithUTF8String:label];
    NSString* nsIcon = icon ? [NSString stringWithUTF8String:icon] : nil;
    [model addItemWithLabel:nsLabel iconName:nsIcon];
}

void SetSidebarModel(void* ctx, void* modelPtr) {
    WailsContext* context = (WailsContext*)ctx;
    WailsSidebarDataSource* model = (WailsSidebarDataSource*)modelPtr;
    [context.sidebar setModel:model];
    [context.sidebar reloadData];  // Refresh after setting model
}

void ReleaseSidebarModel(void* ptr) {
    [(id)ptr release];
}
*/
import "C"

type SidebarModel struct {
	ptr unsafe.Pointer
}

func newSidebarModel() *SidebarModel {
	ptr := C.NewSidebarModel()
	return &SidebarModel{ptr: ptr}
}

func (m *SidebarModel) release() {
	C.ReleaseSidebarModel(m.ptr)
}

func (m *SidebarModel) addUngroupedItem(item native.SidebarItem) {
	cLabel := C.CString(item.Name)
	var cIcon *C.char
	if item.Icon != nil {
		cIcon = C.CString(*item.Icon)
	}
	C.SidebarModelAddUngroupedItem(m.ptr, cLabel, cIcon)
	C.free(unsafe.Pointer(cLabel))
	if cIcon != nil {
		C.free(unsafe.Pointer(cIcon))
	}
}

func (m *SidebarModel) addGroup(group native.SidebarGroup) {
	cTitle := C.CString(group.Name)
	var expanded C.int
	if group.Expanded {
		expanded = 1
	} else {
		expanded = 0
	}
	C.SidebarModelAddGroup(m.ptr, cTitle, expanded)
	C.free(unsafe.Pointer(cTitle))
}

func (m *SidebarModel) addItem(item native.SidebarItem) {
	cLabel := C.CString(item.Name)
	var cIcon *C.char
	if item.Icon != nil {
		cIcon = C.CString(*item.Icon)
	}
	C.SidebarModelAddItem(m.ptr, cLabel, cIcon)
	C.free(unsafe.Pointer(cLabel))
	if cIcon != nil {
		C.free(unsafe.Pointer(cIcon))
	}
}

// CreateSidebarModel builds a WailsSidebarModel from native.Sidebar.
// Call release() on the result when done.
func CreateSidebarModel(sidebar native.Sidebar) *SidebarModel {
	model := newSidebarModel()

	// Sort and add ungrouped items
	sort.Slice(
		sidebar.SidebarItems, func(i, j int) bool {
			return sidebar.SidebarItems[i].Index < sidebar.SidebarItems[j].Index
		},
	)
	for _, elem := range sidebar.SidebarItems {
		model.addUngroupedItem(elem.Value)
	}

	// Sort and add groups with their items
	sort.Slice(
		sidebar.SidebarGroups, func(i, j int) bool {
			return sidebar.SidebarGroups[i].Index < sidebar.SidebarGroups[j].Index
		},
	)
	for _, gelem := range sidebar.SidebarGroups {
		group := gelem.Value
		model.addGroup(group)
		for _, item := range group.Items {
			model.addItem(item)
		}
	}

	return model
}

// SetContextSidebarModel function to set the model on the context's sidebar
func SetContextSidebarModel(context unsafe.Pointer, model *SidebarModel) {
	C.SetSidebarModel(context, model.ptr)
	// We pass ownership of the model to the objective-c class, so we call release
	// to decrease the reference counter. Now we are not the owner of the model any
	// more. When we want the sidebar to change, we have to create a new model.
	model.release()
}
