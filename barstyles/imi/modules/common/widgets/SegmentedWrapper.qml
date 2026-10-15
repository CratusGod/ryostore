import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import ".."

Item {
    id: root
    
    readonly property bool isSegmentedWrapper: true
    
    property bool active: false
    property int orientation: Qt.Horizontal
    property bool pillOnActive: true
    
    property var forceFirst: undefined
    property var forceLast: undefined
    property bool forcePill: false
    property bool forceNotStandalone: false
    
    property color color: "transparent"
    property var maxRadius: undefined
    property real fullRadius: {
        let h = (implicitHeight > 0 ? implicitHeight : 40 * Appearance.effectiveScale)
        let r = h / 2
        if (maxRadius !== undefined) return Math.min(r, maxRadius);
        return r
    }
    property real smallRadius: (Appearance.rounding.unsharpenmore || 6) * Appearance.effectiveScale
    
    implicitWidth: 40 * Appearance.effectiveScale
    implicitHeight: 40 * Appearance.effectiveScale
    
    readonly property var visibleSiblings: {
        let trigger = parent ? parent.children.length : 0; 
        
        if (!parent) return [root];
        let siblings = [];
        let pChildren = parent.children;
        if (!pChildren) return [root];
        
        for (let i = 0; i < pChildren.length; i++) {
            let child = pChildren[i];
            if (!child || !child.visible) continue;
            
            let isCandidate = (child === root);
            if (!isCandidate) {
                try {
                    if (child.isSegmentedWrapper === true || child["isSegmentedWrapper"] === true) {
                        isCandidate = true;
                    }
                } catch(e) {}
                
                if (!isCandidate) {
                    try {
                        let name = child.toString();
                        if (name.indexOf("Segmented") !== -1 || name.indexOf("Wrapper") !== -1) {
                            isCandidate = true;
                        }
                    } catch(e) {}
                }
            }
            if (isCandidate) siblings.push(child);
        }
        return siblings;
    }
    
    readonly property bool isFirst: forceFirst !== undefined ? forceFirst : (visibleSiblings.length > 0 && visibleSiblings[0] === root)
    readonly property bool isLast: forceLast !== undefined ? forceLast : (visibleSiblings.length > 0 && visibleSiblings[visibleSiblings.length - 1] === root)
    
    readonly property bool isStandalone: {
        if (forcePill) return true;
        if (forceNotStandalone) return false;
        
        if (forceFirst === true && forceLast === false) return false;
        if (forceFirst === false && forceLast === true) return false;
        
        return isFirst && isLast;
    }
    
    readonly property real rTopLeft: (isFirst || isStandalone || (active && pillOnActive) || forcePill) ? fullRadius : smallRadius
    readonly property real rTopRight: {
        if ((active && pillOnActive) || isStandalone || forcePill) return fullRadius;
        if (orientation === Qt.Horizontal) return isLast ? fullRadius : smallRadius;
        return isFirst ? fullRadius : smallRadius;
    }
    readonly property real rBottomLeft: {
        if ((active && pillOnActive) || isStandalone || forcePill) return fullRadius;
        if (orientation === Qt.Horizontal) return isFirst ? fullRadius : smallRadius;
        return isLast ? fullRadius : smallRadius;
    }
    readonly property real rBottomRight: (isLast || isStandalone || (active && pillOnActive) || forcePill) ? fullRadius : smallRadius

    Rectangle {
        id: maskRect
        visible: false
        width: root.width
        height: root.height
        antialiasing: true
        topLeftRadius: root.rTopLeft
        topRightRadius: root.rTopRight
        bottomLeftRadius: root.rBottomLeft
        bottomRightRadius: root.rBottomRight
        
        Behavior on topLeftRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(null) }
        Behavior on topRightRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(null) }
        Behavior on bottomLeftRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(null) }
        Behavior on bottomRightRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(null) }
    }

    Item {
        id: container
        anchors.fill: parent
        
        layer.enabled: false
        layer.smooth: true
        layer.effect: OpacityMask {
            maskSource: maskRect
        }

        Rectangle {
            id: bgRect
            anchors.fill: parent
            color: root.color
            visible: root.color !== "transparent"
            antialiasing: true
            
            topLeftRadius: root.rTopLeft
            topRightRadius: root.rTopRight
            bottomLeftRadius: root.rBottomLeft
            bottomRightRadius: root.rBottomRight
            
            Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(bgRect) }
            Behavior on topLeftRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(bgRect) }
            Behavior on topRightRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(bgRect) }
            Behavior on bottomLeftRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(bgRect) }
            Behavior on bottomRightRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(bgRect) }
        }

        Item {
            id: contentItem
            anchors.fill: parent
        }
    }

    default property alias content: contentItem.data
}
