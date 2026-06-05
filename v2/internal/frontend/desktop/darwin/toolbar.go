package darwin

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework Foundation -framework Cocoa -framework WebKit

#import <Foundation/Foundation.h>
#import "WailsToolbarView.h"
#import "WailsContext.h"  // For context

extern void GoOnButtonClicked(int buttonId);
extern void GoOnTextFieldChanged(int fieldId, char *text);

// C wrappers for Objective-C methods
void* NewToolbarModel(void) {
    return [[WailsToolbarModel alloc] init];
}

void ReleaseToolbarModel(void* ptr) {
    [(id)ptr release];
}

void SetToolbarModel(void* ctx, void* modelPtr) {
    WailsContext* context = (WailsContext*)ctx;
    WailsToolbarModel* model = (WailsToolbarModel*)modelPtr;
    if (context.toolbar == nil) {
        // TODO: log?
        return;
    }
    [context.toolbar setModel:model];
}

void SetToolbarCallbacks(void* ctx) {
    WailsContext* context = (WailsContext*)ctx;
    if (context.toolbar == nil) {
        // TODO: log?
        return;
    }
    context.toolbar.onButtonClicked = ^(int buttonId) {
        GoOnButtonClicked(buttonId);
    };
    context.toolbar.onChangeText = ^(int fieldId, char* text) {
        GoOnTextFieldChanged(fieldId, text);
    };
}

void ToolbarRefreshUi(void* ctx) {
    WailsContext* context = (WailsContext*)ctx;
    if (context.toolbar == nil) {
        // TODO: log?
        return;
    }
    [context.toolbar refreshUi];
}

void ToolbarModelAddButton(void* ptr, char* label, int isSelected, char* icon, int buttonId) {
    WailsToolbarModel* model = (WailsToolbarModel*)ptr;
    NSString* nsLabel = [NSString stringWithUTF8String:label];
    NSString* nsIcon = icon ? [NSString stringWithUTF8String:icon] : nil;
    BOOL sel = isSelected > 0;
    [model addButtonWithLabel:nsLabel isSelected:sel andIcon:nsIcon andId:buttonId];
}

void ToolbarStartButtonGroup(void* ptr, char* name, int groupId) {
    WailsToolbarModel* model = (WailsToolbarModel*)ptr;
    NSString* nsName = [NSString stringWithUTF8String:name];
    [model startButtonGroupWidthName:nsName andId:groupId];
}

void ToolbarEndButtonGroup(void* ptr) {
    WailsToolbarModel* model = (WailsToolbarModel*)ptr;
    [model endButtonGroup];
}

void ToolbarSelectButtonInGroupExclusive(void* ptr, int groupId, int buttonId) {
    WailsToolbarModel* model = (WailsToolbarModel*)ptr;
    [model selectButtonInGroup:groupId button:buttonId];
}

void ToolbarSelectButtonInGroup(void* ptr, int groupId, int buttonId) {
    WailsToolbarModel* model = (WailsToolbarModel*)ptr;
    [model selectButtonInGroup:groupId button:buttonId exclusive:NO];
}

void ToolbarDeselectButtonInGroup(void* ptr, int groupId, int buttonId) {
    WailsToolbarModel* model = (WailsToolbarModel*)ptr;
    [model deselectButtonInGroup:groupId button:buttonId];
}

void ToolbarAddLabel(void* ptr, char* label, int labelId) {
    WailsToolbarModel* model = (WailsToolbarModel*)ptr;
    NSString* nsLabel = [NSString stringWithUTF8String:label];
    [model addLabel:nsLabel withId:labelId];
}

void ToolbarSetLabel(void* ptr, char* label, int labelId) {
    WailsToolbarModel* model = (WailsToolbarModel*)ptr;
    NSString* nsLabel = [NSString stringWithUTF8String:label];
    [model setLabel:nsLabel withId:labelId];
}

void ToolbarStartButtonWithMenu(void* ptr, char* label, char* icon, int buttonId) {
    WailsToolbarModel* model = (WailsToolbarModel*)ptr;
    NSString* nsLabel = [NSString stringWithUTF8String:label];
    NSString* nsIcon = icon ? [NSString stringWithUTF8String:icon] : nil;
    [model startButtonWithMenu:nsLabel andIcon:nsIcon andId:buttonId];
}

void ToolbarEndButtonWithMenu(void* ptr) {
    WailsToolbarModel* model = (WailsToolbarModel*)ptr;
    [model endButtonWithMenu];
}

void ToolbarAddMenuItem(void* ptr, char* item, int isSeparator, int isSelected, int itemId) {
    WailsToolbarModel* model = (WailsToolbarModel*)ptr;
    NSString* nsItem = [NSString stringWithUTF8String:item];
    BOOL sel = isSelected > 0;
    BOOL sep = isSeparator > 0;
    [model addMenuItem:nsItem isSeparator:sep isSelected:sel andId:itemId];
}

void ToolbarSelectMenuItem(void* ptr, int itemId) {
    WailsToolbarModel* model = (WailsToolbarModel*)ptr;
    [model selectMenuItem:itemId];
}

void ToolbarAddSpacer(void* ptr) {
    WailsToolbarModel* model = (WailsToolbarModel*)ptr;
    [model addSpacer];
}

void ToolbarAddTextField(void* ptr, bool isSearchField, int fieldId) {
    WailsToolbarModel* model = (WailsToolbarModel*)ptr;
    [model addTextField:isSearchField withId:fieldId];
}

void ToolbarSetTextInTextField(void* ptr, char* text, int fieldId) {
    WailsToolbarModel* model = (WailsToolbarModel*)ptr;
    NSString* nsText = [NSString stringWithUTF8String:text];
    [model setTextInTextField:nsText withId:fieldId];
}

*/
import "C"
import (
	"unsafe"
)

func setToolbarCallbacks(context unsafe.Pointer) {
	C.SetToolbarCallbacks(context)
}

type ToolbarModel struct {
	ptr unsafe.Pointer
}

func newToolbarModel() *ToolbarModel {
	ptr := C.NewToolbarModel()
	return &ToolbarModel{ptr: ptr}
}

// setContextToolbarModel function to set the model on the context's sidebar
func setContextToolbarModel(context unsafe.Pointer, model *ToolbarModel) {
	C.SetToolbarModel(context, model.ptr)
	// We pass ownership of the model to the objective-c class, so we call release
	// to decrease the reference counter. Now we are not the owners of the model anymore.
	C.ReleaseToolbarModel(model.ptr)
}

func refreshToolbarUi(context unsafe.Pointer) {
	C.ToolbarRefreshUi(context)
}

func (m *ToolbarModel) addButton(label, icon string, isSelected bool, buttonId int) {
	cLabel := C.CString(label)
	cIcon := C.CString(icon)
	cIsSelected := C.int(0)
	if isSelected {
		cIsSelected = C.int(1)
	}
	C.ToolbarModelAddButton(m.ptr, cLabel, cIsSelected, cIcon, C.int(buttonId))
	C.free(unsafe.Pointer(cLabel))
	C.free(unsafe.Pointer(cIcon))
}

func (m *ToolbarModel) startButtonGroup(name string, groupId int) {
	cName := C.CString(name)
	C.ToolbarStartButtonGroup(m.ptr, cName, C.int(groupId))
	C.free(unsafe.Pointer(cName))
}

func (m *ToolbarModel) endButtonGroup() {
	C.ToolbarEndButtonGroup(m.ptr)
}

func (m *ToolbarModel) selectButtonInGroupExclusive(groupId, buttonId int) {
	C.ToolbarSelectButtonInGroupExclusive(m.ptr, C.int(groupId), C.int(buttonId))
}

func (m *ToolbarModel) selectButtonInGroup(groupId, buttonId int) {
	C.ToolbarSelectButtonInGroup(m.ptr, C.int(groupId), C.int(buttonId))
}

func (m *ToolbarModel) deselectButtonInGroup(groupId, buttonId int) {
	C.ToolbarDeselectButtonInGroup(m.ptr, C.int(groupId), C.int(buttonId))
}

func (m *ToolbarModel) addLabel(label string, labelId int) {
	cLabel := C.CString(label)
	C.ToolbarAddLabel(m.ptr, cLabel, C.int(labelId))
	C.free(unsafe.Pointer(cLabel))
}

func (m *ToolbarModel) setLabel(label string, labelId int) {
	cLabel := C.CString(label)
	C.ToolbarSetLabel(m.ptr, cLabel, C.int(labelId))
	C.free(unsafe.Pointer(cLabel))
}

func (m *ToolbarModel) startButtonWithMenu(label, icon string, buttonId int) {
	cLabel := C.CString(label)
	cIcon := C.CString(icon)
	C.ToolbarStartButtonWithMenu(m.ptr, cLabel, cIcon, C.int(buttonId))
	C.free(unsafe.Pointer(cLabel))
	C.free(unsafe.Pointer(cIcon))
}

func (m *ToolbarModel) endButtonWithMenu() {
	C.ToolbarEndButtonWithMenu(m.ptr)
}

func (m *ToolbarModel) addMenuItem(item string, isSeparator, isSelected bool, itemId int) {
	cItem := C.CString(item)
	sep := 0
	if isSeparator {
		sep = 1
	}
	sel := 0
	if isSelected {
		sel = 1
	}
	C.ToolbarAddMenuItem(m.ptr, cItem, C.int(sep), C.int(sel), C.int(itemId))
	C.free(unsafe.Pointer(cItem))
}

func (m *ToolbarModel) selectMenuItem(itemId int) {
	C.ToolbarSelectMenuItem(m.ptr, C.int(itemId))
}

func (m *ToolbarModel) addSpacer() {
	C.ToolbarAddSpacer(m.ptr)
}

func (m *ToolbarModel) addTextField(isSearchField bool, fieldId int) {
	C.ToolbarAddTextField(m.ptr, C.bool(isSearchField), C.int(fieldId))
}

func (m *ToolbarModel) setTextInTextField(text string, fieldId int) {
	cText := C.CString(text)
	C.ToolbarSetTextInTextField(m.ptr, cText, C.int(fieldId))
	C.free(unsafe.Pointer(cText))
}
