import "../../common"
import "../../common/widgets"
import "../../../services"
import "notifications"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property int entranceTrigger: -1
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1

    clip: true
    NotificationList {
        id: list
        anchors.fill: parent
        anchors.margins: Appearance.spacing.space100
        visible: root.height >= list.minimumUsefulHeight + Appearance.spacing.space100 * 2
        entranceTrigger: root.entranceTrigger
    }
}
