//go:build darwin
// +build darwin

package darwin

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework Foundation -framework Cocoa -framework WebKit
*/
import "C"

//export GoOnButtonClicked
func GoOnButtonClicked(buttonId C.int) {
	if !toolbarInitialized {
		return
	}
	select {
	case toolbarButtonClickedBuffer <- int(buttonId):
	default:
		// IMPORTANT: drop event if nobody is draining fast enough, otherwise the UI can lock up completely
	}
}

//export GoOnTextFieldChanged
func GoOnTextFieldChanged(fieldId C.int, text *C.char) {
	if !toolbarInitialized {
		return
	}
	select {
	case toolbarTextChangedBuffer <- ToolbarTextChange{
		id:  int(fieldId),
		txt: cStringToGoString(text),
	}:
	default:
		// IMPORTANT: drop event if nobody is draining fast enough, otherwise the UI can lock up completely
	}
}

func cStringToGoString(text *C.char) string {
	if text == nil {
		return ""
	}
	return C.GoString(text)
}
