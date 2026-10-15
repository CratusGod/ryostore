import "../../../../../services"
import "../../../../common"
import "../../../../common/models/quickToggles"
import "../../../../common/functions"
import "../../../../common/widgets"
import QtQuick

AndroidQuickToggleButton {
    id: root
    
    toggleModel: NetworkToggle {}
}

