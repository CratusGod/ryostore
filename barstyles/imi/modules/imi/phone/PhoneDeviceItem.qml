import "../../../services"
import "../../common"
import "../../common/functions"
import "../../common/widgets"
import "device_glyph.js" as DeviceGlyph
import QtQuick
import QtQuick.Layouts

DialogListItem {
    id: root
    property var device: null
    readonly property bool online: (root.device?.paired ?? false) && (root.device?.reachable ?? false)

    colBackground: root.active
        ? Appearance.colors.colSecondaryContainer
        : ColorUtils.transparentize(Appearance.colors.colLayer3)
    colBackgroundHover: root.active
        ? Appearance.colors.colSecondaryContainer
        : Appearance.colors.colLayer3Hover

    contentItem: RowLayout {
        anchors {
            fill: parent
            topMargin: root.verticalPadding
            bottomMargin: root.verticalPadding
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
        }
        spacing: Appearance.spacing.space150

        MaterialSymbol {
            iconSize: Appearance.font.pixelSize.larger
            text: DeviceGlyph.forType(root.device?.type)
            color: root.active ? Appearance.colors.colOnSecondaryContainer
                : root.online ? Appearance.colors.colPrimary
                : Appearance.colors.colOnSurfaceVariant
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                color: root.active ? Appearance.colors.colOnSecondaryContainer
                    : Appearance.colors.colOnSurfaceVariant
                elide: Text.ElideRight
                text: root.device?.name || root.device?.id || ""
                textFormat: Text.PlainText
            }
            StyledText {
                Layout.fillWidth: true
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smaller
                elide: Text.ElideRight
                textFormat: Text.PlainText
                text: {
                    if (!root.device) return "";
                    if (root.device.hasPairingRequest) return Translation.tr("Wants to pair");
                    if (!root.device.paired) return Translation.tr("Not paired");
                    if (!root.device.reachable) return Translation.tr("Paired • Offline");
                    if (root.device.batteryAvailable)
                        return root.device.batteryCharging
                            ? Translation.tr("%1% • Charging").arg(root.device.batteryCharge)
                            : Translation.tr("%1%").arg(root.device.batteryCharge);
                    return Translation.tr("Connected");
                }
            }
        }

        MaterialSymbol {
            objectName: "rosterSelectedCheck"
            visible: root.active
            text: "check"
            iconSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.colOnSecondaryContainer
        }
    }
}
