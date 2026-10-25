pragma Singleton

import QtQuick

// Typography — the one face name the Obelisk asks for. In Jurai
// shell it read the house config (fonts.technical, whose own
// default is Orbitron); the launcher carries that default.
QtObject {
    readonly property string technical: "Orbitron"
    readonly property string technicalFallback: "sans-serif"
}
