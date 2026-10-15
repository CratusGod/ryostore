pragma ComponentBehavior: Bound
import QtQuick
import ".."

Item {
    id: root
    signal clicked(event: var)
    property alias iconText: fabWidget.iconText
    property alias baseSize: fabWidget.baseSize
    property alias colBackground: fabWidget.colBackground
    property alias colBackgroundHover: fabWidget.colBackgroundHover
    property alias colRipple: fabWidget.colRipple
    property alias colOnBackground: fabWidget.colOnBackground
    default property alias fabData: fabWidget.data
    property bool enableShadow: true

    implicitWidth: fabWidget.implicitWidth
    implicitHeight: fabWidget.implicitHeight

    StyledRectangularShadow {
        visible: root.enableShadow
        target: fabWidget
        radius: fabWidget.buttonRadius
    }

    FloatingActionButton {
        id: fabWidget
        onClicked: e => root.clicked(e)
        baseSize: 48
        colBackground: Appearance.colors.colTertiaryContainer
        colBackgroundHover: Appearance.colors.colTertiaryContainerHover
        colRipple: Appearance.colors.colTertiaryContainerActive
        colOnBackground: Appearance.colors.colOnTertiaryContainer
    }
}
