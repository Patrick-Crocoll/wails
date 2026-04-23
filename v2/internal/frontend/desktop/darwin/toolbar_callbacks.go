//go:build darwin
// +build darwin

package darwin

/*
#cgo CFLAGS: -x objective-c
#cgo LDFLAGS: -framework Foundation -framework Cocoa -framework WebKit
*/
import "C"

import "log/slog"

//export GoOnButtonClicked
func GoOnButtonClicked(buttonId C.int) {
	slog.Debug("Le button est clické", slog.Int("buttonId", int(buttonId)))

}

//export GoOnTextFieldChanged
func GoOnTextFieldChanged(fieldId C.int, text *C.char) {
}
