import "../../../../../services"
import "../../../../common"
import "../../../../common/models/quickToggles"
import "../../../../common/functions"
import "../../../../common/widgets"
import QtQuick
import Quickshell
import Quickshell.Bluetooth

AndroidQuickToggleButton {
    id: root
    
    toggleModel: BluetoothToggle {}
}
