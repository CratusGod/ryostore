import "../../../../../services"
import "../../../../common"
import "../../../../common/widgets"
import "../../../../common/models/quickToggles"
import QtQuick

GroupButton {
    id: button
    property QuickToggleModel toggleModel: null
    property string buttonIcon: toggleModel?.icon ?? ""

    baseWidth: 40
    baseHeight: 40
    clickedWidth: baseWidth + 20
    toggled: toggleModel?.toggled ?? false
    visible: toggleModel?.available ?? true
    altAction: toggleModel?.altAction ?? null
    buttonRadius: (altAction && toggled) ? Appearance?.rounding.normal : Math.min(baseHeight, baseWidth) / 2
    buttonRadiusPressed: Appearance?.rounding?.small

    onClicked: {
        if (!button.toggleModel) return;
        if (button.toggleModel.mainAction) button.toggleModel.mainAction();
        else if (button.altAction) button.altAction();
    }

    contentItem: MaterialSymbol {
        anchors.centerIn: parent
        iconSize: 22
        fill: toggled ? 1 : 0
        color: toggled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: buttonIcon
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    StyledToolTip {
        extraVisibleCondition: (button.toggleModel?.tooltipText ?? "").length > 0
        text: button.toggleModel?.tooltipText ?? ""
    }
}
