import "../../../../common/models/quickToggles"
import "../../../../common/widgets"
import QtQuick

AndroidQuickToggleButton {
    id: root

    toggleModel: PhoneConnectToggle {}
    mainAction: () => root.openMenu()
}
