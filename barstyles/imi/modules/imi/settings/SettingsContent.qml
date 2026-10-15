import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../services"
import "../../.."
import "../../common"
import "../../common/widgets"
import "../../common/functions"

Item {
    id: root

    property real contentPadding: Appearance.spacing.space100
    property int currentPage: 0
    property string navigationQuery: ""
    property string selectedSection: ""

    readonly property real searchBarHeight: 46
    readonly property real contentPaneWidth: root.width - navRailWrapper.implicitWidth - root.contentPadding * 3

    function normalized(value) {
        return String(value || "").toLowerCase().trim();
    }

    function pageMatches(pageIndex, page) {
        const query = normalized(navigationQuery);
        if (query.length === 0) return true;
        if (normalized(page.name).includes(query)) return true;
        if (page.sections.some(section => sectionAvailable(pageIndex, section) && normalized(section).includes(query)))
            return true;
        return (page.searchTerms || []).some(term => normalized(term).includes(query));
    }

    function sectionAvailable(pageIndex, section) {
        const loader = pagesRepeater.itemAt(pageIndex);
        if (!loader?.item) return true;
        const available = loader.item.availableSections || [];
        if (available.length === 0) return true;
        const candidate = normalized(section);
        return available.some(actual => {
            const label = normalized(actual);
            return label === candidate || label.includes(candidate) || candidate.includes(label);
        });
    }

    function sectionMatches(pageIndex, section) {
        const query = normalized(navigationQuery);
        return sectionAvailable(pageIndex, section)
            && (query.length === 0 || normalized(section).includes(query));
    }

    function sectionIsActive(pageIndex, section) {
        if (currentPage !== pageIndex) return false;
        const active = normalized(selectedSection);
        const candidate = normalized(section);
        if (active.length === 0 || candidate.length === 0) return false;
        return active === candidate || active.includes(candidate) || candidate.includes(active);
    }

    function navigateFirstMatch() {
        const query = normalized(navigationQuery);
        if (query.length === 0) return;
        for (let pageIndex = 0; pageIndex < pages.length; pageIndex++) {
            if (normalized(pages[pageIndex].name) === query) {
                navigateTo(pageIndex, "");
                return;
            }
        }
        for (let pageIndex = 0; pageIndex < pages.length; pageIndex++) {
            const page = pages[pageIndex];
            const matchingSection = page.sections.find(section =>
                sectionAvailable(pageIndex, section) && normalized(section).includes(query));
            if (matchingSection) {
                navigateTo(pageIndex, matchingSection);
                return;
            }
            const matchingTerm = (page.searchTerms || []).find(term => normalized(term).includes(query));
            if (matchingTerm) {
                navigateTo(pageIndex, matchingTerm);
                return;
            }
            if (normalized(page.name).includes(query)) {
                navigateTo(pageIndex, "");
                return;
            }
        }
    }

    function navigateTo(pageIndex, section) {
        currentPage = pageIndex;
        selectedSection = section || "";
        const loader = pagesRepeater.itemAt(pageIndex);
        const scroll = () => {
            if (section && loader?.item && typeof loader.item.goTo === "function")
                loader.item.goTo(section);
        };
        if (loader?.item) Qt.callLater(scroll);
        else if (loader) loader.onLoaded.connect(scroll);
    }

    function focusSearch() {
        settingsSearchField.forceActiveFocus();
        settingsSearchField.selectAll();
    }

    readonly property bool typingSomewhere: {
        const focused = root.Window.activeFocusItem;
        return !!focused && focused.selectedText !== undefined;
    }

    Shortcut {
        sequences: [StandardKey.Find]
        onActivated: root.focusSearch()
    }

    Shortcut {
        sequences: ["Ctrl+K"]
        onActivated: root.focusSearch()
    }

    Shortcut {
        sequence: "/"
        enabled: !root.typingSomewhere
        onActivated: root.focusSearch()
    }

    onCurrentPageChanged: {
        if (currentPage === pages.length - 1) {
            if (SystemInfo.cpu === "") SystemInfo.refresh();
            Updates.refresh();
        }
    }

    property var pages: [
        {
            name: Translation.tr("Bar"), id: "bar", icon: "toast", iconRotation: 180,
            component: Qt.resolvedUrl("pages/BarConfig.qml"),
            sections: [],
            searchTerms: [Translation.tr("Screens"), Translation.tr("Bar layout"), Translation.tr("Positioning & Styles"),
                Translation.tr("Privacy"), Translation.tr("Tray"), Translation.tr("Divider"),
                Translation.tr("Utility buttons"), Translation.tr("Workspaces"), Translation.tr("Resources"),
                Translation.tr("Media"), Translation.tr("Tooltips"),
                Translation.tr("Show bar on"), Translation.tr("Buttons & Media"), Translation.tr("Center")]
        },
        {
            name: Translation.tr("Sidebars & Panels"), id: "sidebars-panels", icon: "side_navigation",
            component: Qt.resolvedUrl("pages/SidebarsPanelsConfig.qml"),
            sections: [Translation.tr("Left Sidebar"), Translation.tr("Right Sidebar")],
            searchTerms: [Translation.tr("Quick toggles"), Translation.tr("Sliders"), Translation.tr("Corner open"),
                Translation.tr("Translator")]
        },
        {
            name: Translation.tr("Appearance"), id: "appearance", icon: "palette",
            component: Qt.resolvedUrl("pages/AppearanceConfig.qml"),
            sections: [Translation.tr("Frame"), Translation.tr("Motion"), Translation.tr("Fonts")],
            searchTerms: [Translation.tr("Shadow"), Translation.tr("Rounding"), Translation.tr("Corner style")]
        },
        {
            name: Translation.tr("About"), id: "about", icon: "info",
            component: Qt.resolvedUrl("pages/About.qml"),
            sections: [],
            searchTerms: [Translation.tr("Version"), Translation.tr("License")]
        }
    ]

    Connections {
        target: GlobalStates
        function onSettingsPageChanged() {
            if (GlobalStates.settingsPage === "") return;

            const parts = GlobalStates.settingsPage.split(":");
            const pageId = parts[0];
            const searchTerm = parts.length > 1 ? parts[1] : "";

            const idx = root.pages.findIndex(p => p.id === pageId);

            if (idx >= 0) {
                root.currentPage = idx;
                if (searchTerm !== "") {
                    const loader = pagesRepeater.itemAt(idx);
                    const scroll = () => {
                        if (loader?.item && typeof loader.item.goTo === "function")
                            loader.item.goTo(searchTerm);
                    };
                    if (loader?.item) Qt.callLater(scroll);
                    else if (loader) loader.onLoaded.connect(scroll);
                }
            } else {
                console.warn(`[imi settings] no page with id "${pageId}" (ids: ${root.pages.map(p => p.id).join(", ")})`);
            }
            GlobalStates.settingsPage = "";
        }
    }

    Rectangle {
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            margins: root.contentPadding
        }
        width: navRailWrapper.implicitWidth
        radius: Appearance.rounding.normal
        color: Appearance.m3colors.m3surfaceContainerLow

        Behavior on width {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    ColumnLayout {
        id: mainColumn
        anchors {
            fill: parent
            margins: root.contentPadding
        }

        Rectangle {
            readonly property real searchWidth: Math.min(520, root.contentPaneWidth)
            Layout.preferredWidth: searchWidth
            Layout.preferredHeight: root.searchBarHeight
            Layout.leftMargin: navRailWrapper.implicitWidth + root.contentPadding
                + Math.max(0, (root.contentPaneWidth - searchWidth) / 2)
            radius: Appearance.rounding.full
            color: Appearance.colors.colLayer1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Appearance.spacing.space200
                anchors.rightMargin: Appearance.spacing.space100
                spacing: Appearance.spacing.space100

                MaterialSymbol {
                    text: "search"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colSubtext
                }

                StyledTextInput {
                    id: settingsSearchField
                    Layout.fillWidth: true
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.navigationQuery
                    onTextChanged: root.navigationQuery = text
                    font.pixelSize: Appearance.font.pixelSize.normal
                    Keys.onReturnPressed: root.navigateFirstMatch()
                    Keys.onEnterPressed: root.navigateFirstMatch()
                    Keys.onEscapePressed: {
                        if (text.length > 0) {
                            text = "";
                            event.accepted = true;
                        }
                    }

                    HoverHandler {
                        cursorShape: Qt.IBeamCursor
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: settingsSearchField.text.length === 0
                        text: Translation.tr("Search settings and sections  —  / or Ctrl+K")
                        color: Appearance.colors.colSubtext
                        font.pixelSize: Appearance.font.pixelSize.normal
                    }
                }

                IconButton {
                    visible: root.navigationQuery.length > 0
                    buttonIcon: "close"
                    buttonSize: 32
                    colRipple: Appearance.colors.colLayer2Active
                    onClicked: settingsSearchField.text = ""
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.contentPadding

            Rectangle {
                id: navRailWrapper
                Layout.fillHeight: true
                implicitWidth: navRail.expanded ? 230 : Appearance.spacing.space700
                color: "transparent"
                radius: Appearance.rounding.normal

                Behavior on implicitWidth {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                NavigationRail {
                    id: navRail
                    anchors {
                        fill: parent
                        leftMargin: Appearance.spacing.space200
                        rightMargin: Appearance.spacing.space200
                    }
                    spacing: Appearance.spacing.space150
                    expanded: root.width > 900

                    StyledFlickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentHeight: navigationTree.implicitHeight
                        clip: true
                        expressiveScroll: true

                        Column {
                            id: navigationTree
                            width: parent.width
                            spacing: Appearance.spacing.space25

                            Repeater {
                                model: root.pages

                                Column {
                                    id: pageBranch
                                    required property var modelData
                                    required property int index
                                    property bool branchExpanded: index === root.currentPage
                                    width: navigationTree.width
                                    visible: root.pageMatches(index, modelData)
                                    spacing: Appearance.spacing.space25

                                    Connections {
                                        target: root
                                        function onCurrentPageChanged() {
                                            if (root.currentPage === pageBranch.index)
                                                pageBranch.branchExpanded = true;
                                        }
                                    }

                                    NavigationRailButton {
                                        visible: !navRail.expanded
                                        width: parent.width
                                        toggled: root.currentPage === pageBranch.index
                                        expanded: false
                                        buttonIcon: pageBranch.modelData.icon
                                        buttonIconRotation: pageBranch.modelData.iconRotation || 0
                                        buttonText: pageBranch.modelData.name
                                        showToggledHighlight: false
                                        onPressed: root.navigateTo(pageBranch.index, "")
                                    }

                                    RippleButton {
                                        visible: navRail.expanded
                                        width: parent.width
                                        implicitHeight: 42
                                        buttonRadius: Appearance.rounding.full
                                        toggled: root.currentPage === pageBranch.index
                                        colBackground: "transparent"
                                        colBackgroundToggled: ColorUtils.transparentize(
                                            Appearance.colors.colPrimary, 0.88)
                                        colBackgroundHover: Appearance.colors.colLayer1Hover
                                        colBackgroundToggledHover: ColorUtils.transparentize(
                                            Appearance.colors.colPrimary, 0.78)
                                        colRipple: Appearance.colors.colLayer1Active
                                        colRippleToggled: Appearance.colors.colLayer1Active
                                        onClicked: {
                                            pageBranch.branchExpanded = !pageBranch.branchExpanded;
                                            root.navigateTo(pageBranch.index, "");
                                        }

                                        contentItem: RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: Appearance.spacing.space100
                                            anchors.rightMargin: Appearance.spacing.space100
                                            spacing: Appearance.spacing.space100

                                            MaterialSymbol {
                                                text: pageBranch.modelData.icon
                                                rotation: pageBranch.modelData.iconRotation || 0
                                                iconSize: Appearance.font.pixelSize.larger
                                                fill: root.currentPage === pageBranch.index ? 1 : 0
                                                color: root.currentPage === pageBranch.index
                                                    ? Appearance.colors.colPrimary
                                                    : Appearance.colors.colOnLayer1
                                            }
                                            StyledText {
                                                Layout.fillWidth: true
                                                text: pageBranch.modelData.name
                                                color: root.currentPage === pageBranch.index
                                                    ? Appearance.colors.colPrimary
                                                    : Appearance.colors.colOnLayer1
                                                font.weight: root.currentPage === pageBranch.index ? Font.DemiBold : Font.Normal
                                                elide: Text.ElideRight
                                            }
                                            MaterialSymbol {
                                                visible: pageBranch.modelData.sections.length > 0
                                                text: "expand_more"
                                                rotation: (pageBranch.branchExpanded || root.navigationQuery.length > 0) ? 180 : 0
                                                iconSize: Appearance.font.pixelSize.large
                                                color: Appearance.colors.colSubtext
                                                Behavior on rotation {
                                                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                                }
                                            }
                                        }
                                    }

                                    Revealer {
                                        id: sectionRevealer
                                        vertical: true
                                        reveal: navRail.expanded && (pageBranch.branchExpanded || root.navigationQuery.length > 0)
                                        width: parent.width
                                        opacity: reveal ? 1 : 0

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: Appearance.animation.elementMoveEnter.duration
                                                easing.type: Appearance.animation.elementMoveEnter.type
                                                easing.bezierCurve: Appearance.animation.elementMoveEnter.bezierCurve
                                            }
                                        }

                                        Column {
                                            width: sectionRevealer.width
                                            spacing: Appearance.spacing.space25

                                            Repeater {
                                                model: pageBranch.modelData.sections

                                                RippleButton {
                                                    id: sectionButton
                                                    required property var modelData
                                                    width: pageBranch.width
                                                    implicitHeight: 34
                                                    visible: root.sectionMatches(pageBranch.index, modelData)
                                                    buttonRadius: Appearance.rounding.full
                                                    toggled: root.sectionIsActive(pageBranch.index, modelData)
                                                    colBackground: "transparent"
                                                    colBackgroundToggled: "transparent"
                                                    colBackgroundHover: Appearance.colors.colLayer1Hover
                                                    colBackgroundToggledHover: Appearance.colors.colLayer1Hover
                                                    colRipple: Appearance.colors.colLayer1Active
                                                    colRippleToggled: Appearance.colors.colLayer1Active
                                                    onClicked: root.navigateTo(pageBranch.index, modelData)

                                                    contentItem: RowLayout {
                                                        anchors.fill: parent
                                                        anchors.leftMargin: Appearance.spacing.space500
                                                        anchors.rightMargin: Appearance.spacing.space100
                                                        spacing: Appearance.spacing.space75

                                                        Rectangle {
                                                            implicitWidth: 5
                                                            implicitHeight: 5
                                                            radius: Appearance.rounding.full
                                                            color: sectionButton.toggled
                                                                ? Appearance.colors.colPrimary
                                                                : Appearance.colors.colOutline
                                                        }
                                                        StyledText {
                                                            Layout.fillWidth: true
                                                            text: modelData
                                                            color: sectionButton.toggled
                                                                ? Appearance.colors.colPrimary
                                                                : Appearance.colors.colOnLayer1
                                                            font.pixelSize: Appearance.font.pixelSize.small
                                                            elide: Text.ElideRight
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            StyledText {
                                width: parent.width
                                visible: pagesRepeater.matches === 0
                                topPadding: Appearance.spacing.space100
                                text: Translation.tr("No settings match")
                                color: Appearance.colors.colSubtext
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"

                Item {
                    id: pageHost
                    anchors.fill: parent

                    Repeater {
                        id: pagesRepeater
                        model: root.pages

                        readonly property int matches: {
                            let n = 0;
                            for (let i = 0; i < root.pages.length; i++)
                                if (root.pageMatches(i, root.pages[i])) n++;
                            return n;
                        }

                        Loader {
                            id: pageLoader
                            required property var modelData
                            required property int index
                            source: modelData.component
                            asynchronous: true
                            active: Config.ready

                            anchors.fill: parent

                            readonly property bool isActive: root.currentPage === index
                            opacity: isActive ? 1 : 0
                            enabled: isActive
                            visible: isActive
                            anchors.topMargin: isActive ? 0 : Appearance.spacing.space150

                            onLoaded: {
                                if (pageLoader.isActive) {
                                    GlobalStates.currentPageInstance = item;
                                    root.selectedSection = item.currentSection || "";
                                }
                            }

                            onIsActiveChanged: {
                                if (isActive && item) {
                                    GlobalStates.currentPageInstance = item;
                                    root.selectedSection = item.currentSection || "";
                                } else if (GlobalStates.currentPageInstance === item) {
                                    GlobalStates.currentPageInstance = null;
                                }
                            }

                            Connections {
                                target: pageLoader.item
                                function onCurrentSectionChanged() {
                                    if (pageLoader.isActive)
                                        root.selectedSection = pageLoader.item.currentSection || "";
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Easing.OutCubic }
                            }
                            Behavior on anchors.topMargin {
                                NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Easing.OutCubic }
                            }
                        }
                    }
                }

                PagePlaceholder {
                    readonly property var currentLoader: pagesRepeater.itemAt(root.currentPage) ?? null
                    shown: currentLoader?.status === Loader.Error
                    icon: "error"
                    title: Translation.tr("This page failed to load")
                    description: Translation.tr("Its QML could not be built. The shell log has a 'WARN scene' line naming the file and the line that failed.")
                    descriptionHorizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
