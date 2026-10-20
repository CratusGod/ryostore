import QtQuick

// Compatibility shim for QuickPanel's old Apps screen. The real Tansu
// launcher is a separate product under app-launchers/tansu; this face is
// never reachable from the shipped phone, but keeps the host compiling.
Item {
    id: root

    property var source: null
    property real renderScale: 1
    property string screenName: ""
    property real visibleBottom: 0
    property real visibleReach: 0
    property string clockText: ""
    property string dateText: ""
    property real downloadBps: 0
    property real uploadBps: 0
    property string query: ""

    signal appActivated(var app)
    signal closeRequested()
    signal jumpRequested(int index)
    signal doneRequested()
    signal pickerRequested()
    signal colorPickedBack(string hex)

    function appendText(text) { root.query += text }
    function reset() { root.query = "" }
    function back() { root.closeRequested() }
    function setText(text) { root.query = text }
    function focusSearch() {}
}
