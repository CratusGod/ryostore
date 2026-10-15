import QtQuick
import Quickshell
import ".."
import "../widgets"
import "../../../services"

Item {
    id: rootNode
    property var manifestNode
    property string pluginId: ""
    property var optionDefinitions: []
    property string basePath: ""
    property string screenName: ""

    property real hostX: 0
    property real hostY: 0
    property color hostColText: Appearance.colors.colOnLayer0
    property bool hostWallpaperSafetyTriggered: false
    property bool hostInteractionLocked: false

    readonly property bool wantsVisibleWhenLocked: componentLoader.item
        ? componentLoader.item.visibleWhenLocked === true : false
    readonly property bool wantsForceCenter: componentLoader.item
        ? componentLoader.item.forceCenter === true : false
    readonly property bool wantsOwnSpanTransition: componentLoader.item
        ? componentLoader.item.handlesSpanTransition === true : false
    readonly property bool wantsAdaptiveTextColor: componentLoader.item
        ? componentLoader.item.needsColText === true : false

    property real gridWidth: 0
    property real gridHeight: 0
    readonly property bool hasGrid: gridWidth > 0 && gridHeight > 0
    property string gridSize: ""
    property point resizeBow: Qt.point(0, 0)
    property bool hostDragging: false
    property bool hostBoxInMotion: false

    readonly property string effectiveBasePath: manifestNode?._basePath || basePath
    readonly property string componentPath: manifestNode?.component && effectiveBasePath
        ? (String(manifestNode.component).startsWith("/")
            ? String(manifestNode.component)
            : effectiveBasePath + "/" + String(manifestNode.component).replace(/^\.\//, ""))
        : ""

    implicitWidth: hasGrid ? gridWidth
        : (componentLoader.item ? (componentLoader.item.implicitWidth || componentLoader.item.width) : 0)
    implicitHeight: hasGrid ? gridHeight
        : (componentLoader.item ? (componentLoader.item.implicitHeight || componentLoader.item.height) : 0)
    readonly property bool hasCustomBlurRegions: componentLoader.item
        ? componentLoader.item.blurRegions !== undefined : false
    readonly property var blurRegions: hasCustomBlurRegions ? componentLoader.item.blurRegions : []
    readonly property bool managesBlurTint: componentLoader.item
        ? componentLoader.item.managesBlurTint === true : false
    width: implicitWidth
    height: implicitHeight

    function resolveBinding(bindingString) {
        switch (bindingString) {
            case "DateTime.time": return DateTime.time;
            case "DateTime.date": return DateTime.date;
            case "DateTime.shortDate": return DateTime.shortDate;
            case "Battery.percentage": return Battery.percentage;
            case "Battery.charging": return Battery.charging;
            case "Battery.pluggedIn": return Battery.pluggedIn;
            case "Network.networkName": return Network.networkName;
            case "Network.primaryIp": return Network.primaryIp;
            case "SystemInfo.cpuUsage": return SystemInfo.cpuUsage;
            case "SystemInfo.ramUsage": return SystemInfo.ramUsage;
            case "Audio.volume": return Audio.volume;
            case "Audio.muted": return Audio.muted;
            default: return undefined;
        }
    }

    function optionDefinition(propertyName) {
        for (const definition of rootNode.optionDefinitions) {
            if (definition.key === propertyName) return definition;
        }
        return null;
    }

    function declarativeComponent() {
        if (!manifestNode) return null;
        switch (manifestNode.type) {
        case "StyledText": return styledTextComponent;
        case "MaterialSymbol": return materialSymbolComponent;
        case "ResourceCard": return resourceCardComponent;
        case "StyledImage": return styledImageComponent;
        case "MaterialShape": return materialShapeComponent;
        case "Row": return rowComponent;
        case "Column": return columnComponent;
        case "Item": return itemComponent;
        case "Rectangle": return rectangleComponent;
        case "RippleButton": return rippleButtonComponent;
        case "StyledRectangularShadow": return styledRectangularShadowComponent;
        case "GroupedList": return groupedListComponent;
        case "ConfigSwitch": return configSwitchComponent;
        case "NoticeBox": return noticeBoxComponent;
        case "StyledPopup": return styledPopupComponent;
        default: return null;
        }
    }

    Loader {
        id: componentLoader
        anchors.fill: rootNode.hasGrid ? rootNode : undefined
        source: rootNode.componentPath
        sourceComponent: rootNode.componentPath ? null : rootNode.declarativeComponent()

        onLoaded: {
            if (!item) return;
            if (rootNode.componentPath) {
                if (item.screenName !== undefined)
                    item.screenName = Qt.binding(() => rootNode.screenName);
                if (item.hostX !== undefined)
                    item.hostX = Qt.binding(() => rootNode.hostX);
                if (item.hostY !== undefined)
                    item.hostY = Qt.binding(() => rootNode.hostY);
                if (item.hostColText !== undefined)
                    item.hostColText = Qt.binding(() => rootNode.hostColText);
                if (item.wallpaperSafetyTriggered !== undefined)
                    item.wallpaperSafetyTriggered = Qt.binding(() => rootNode.hostWallpaperSafetyTriggered);
                if (item.hostInteractionLocked !== undefined)
                    item.hostInteractionLocked = Qt.binding(() => rootNode.hostInteractionLocked);
                if (item.hostGridSize !== undefined)
                    item.hostGridSize = Qt.binding(() => rootNode.gridSize);
                if (item.hostResizeBow !== undefined)
                    item.hostResizeBow = Qt.binding(() => rootNode.resizeBow);
                if (item.hostDragging !== undefined)
                    item.hostDragging = Qt.binding(() => rootNode.hostDragging);
                if (item.hostBoxInMotion !== undefined)
                    item.hostBoxInMotion = Qt.binding(() => rootNode.hostBoxInMotion);
                return;
            }
            if (manifestNode.props) {
                for (let prop in manifestNode.props) {
                    let val = manifestNode.props[prop];
                    let finalVal = val;

                    const option = rootNode.optionDefinition(prop);
                    if (option) {
                        finalVal = Qt.binding(function() {
                            return PluginState.option(rootNode.pluginId, prop, option.default);
                        });
                    } else if (typeof val === "string" && val.startsWith("Appearance.colors.")) {
                        let colorName = val.substring(18);
                        finalVal = Qt.binding(function() { return Appearance.colors[colorName]; });
                    } else if (typeof val === "string" && val.startsWith("Appearance.rounding.")) {
                        let rName = val.substring(20);
                        finalVal = Qt.binding(function() { return Appearance.rounding[rName]; });
                    } else if (typeof val === "string" && val === "parent" && prop.startsWith("anchors")) {
                        finalVal = item.parent;
                    }
                    
                    let parts = prop.split('.');
                    let obj = item;
                    for (let i = 0; i < parts.length - 1; i++) {
                        if (obj[parts[i]] === undefined) break;
                        obj = obj[parts[i]];
                    }
                    obj[parts[parts.length - 1]] = finalVal;
                }
            }
            if (manifestNode.bindings) {
                for (let prop in manifestNode.bindings) {
                    let bindTarget = manifestNode.bindings[prop];
                    let finalVal = Qt.binding(function() {
                        return rootNode.resolveBinding(bindTarget);
                    });
                    
                    let parts = prop.split('.');
                    let obj = item;
                    for (let i = 0; i < parts.length - 1; i++) {
                        if (obj[parts[i]] === undefined) break;
                        obj = obj[parts[i]];
                    }
                    obj[parts[parts.length - 1]] = finalVal;
                }
            }
        }
    }

    Component { id: styledTextComponent; StyledText {} }
    Component { id: materialSymbolComponent; MaterialSymbol {} }
    Component { id: resourceCardComponent; ResourceCard {} }
    Component { id: styledImageComponent; StyledImage {} }

    Component { id: materialShapeComponent; MaterialShape {
        Repeater {
            model: manifestNode.children || []
            Loader {
                source: "PluginNode.qml"
                onLoaded: { if (item) { item.manifestNode = modelData; item.pluginId = rootNode.pluginId; item.optionDefinitions = rootNode.optionDefinitions; item.basePath = rootNode.basePath } }
            }
        }
    }}

    Component { id: rowComponent; Row {
        Repeater {
            model: manifestNode.children || []
            Loader {
                source: "PluginNode.qml"
                onLoaded: { if (item) { item.manifestNode = modelData; item.pluginId = rootNode.pluginId; item.optionDefinitions = rootNode.optionDefinitions; item.basePath = rootNode.basePath } }
            }
        }
    }}

    Component { id: columnComponent; Column {
        Repeater {
            model: manifestNode.children || []
            Loader {
                source: "PluginNode.qml"
                onLoaded: { if (item) { item.manifestNode = modelData; item.pluginId = rootNode.pluginId; item.optionDefinitions = rootNode.optionDefinitions; item.basePath = rootNode.basePath } }
            }
        }
    }}

    Component { id: itemComponent; Item {
        Repeater {
            model: manifestNode.children || []
            Loader {
                source: "PluginNode.qml"
                onLoaded: { if (item) { item.manifestNode = modelData; item.pluginId = rootNode.pluginId; item.optionDefinitions = rootNode.optionDefinitions; item.basePath = rootNode.basePath } }
            }
        }
    }}

    Component { id: rectangleComponent; Rectangle {
        Repeater {
            model: manifestNode.children || []
            Loader {
                source: "PluginNode.qml"
                onLoaded: { if (item) { item.manifestNode = modelData; item.pluginId = rootNode.pluginId; item.optionDefinitions = rootNode.optionDefinitions; item.basePath = rootNode.basePath } }
            }
        }
    }}
    
    Component { id: rippleButtonComponent; RippleButton {
        Repeater {
            model: manifestNode.children || []
            Loader {
                source: "PluginNode.qml"
                onLoaded: { if (item) { item.manifestNode = modelData; item.pluginId = rootNode.pluginId; item.optionDefinitions = rootNode.optionDefinitions; item.basePath = rootNode.basePath } }
            }
        }
    }}

    Component { id: styledRectangularShadowComponent; StyledRectangularShadow {
        Repeater {
            model: manifestNode.children || []
            Loader {
                source: "PluginNode.qml"
                onLoaded: { if (item) { item.manifestNode = modelData; item.pluginId = rootNode.pluginId; item.optionDefinitions = rootNode.optionDefinitions; item.basePath = rootNode.basePath } }
            }
        }
    }}

    Component { id: groupedListComponent; GroupedList {
        Repeater {
            model: manifestNode.children || []
            Loader {
                source: "PluginNode.qml"
                onLoaded: { if (item) { item.manifestNode = modelData; item.pluginId = rootNode.pluginId; item.optionDefinitions = rootNode.optionDefinitions; item.basePath = rootNode.basePath } }
            }
        }
    }}

    Component { id: configSwitchComponent; ConfigSwitch {} }
    Component { id: noticeBoxComponent; NoticeBox {} }
    Component { id: styledPopupComponent; StyledPopup {
        Repeater {
            model: manifestNode.children || []
            Loader {
                source: "PluginNode.qml"
                onLoaded: { if (item) { item.manifestNode = modelData; item.pluginId = rootNode.pluginId; item.optionDefinitions = rootNode.optionDefinitions; item.basePath = rootNode.basePath } }
            }
        }
    }}
}
