pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "."
import "functions"
import "../../services/MprisSelection.js" as MprisSelection

Singleton {
    id: root
    property string filePath: Directories.shellConfigPath
    property alias options: configOptionsJsonAdapter
    property bool ready: false
    property int readWriteDelay: 50

    property bool blockWrites: false

    readonly property var desktopWidgetPluginIds: ({
            "clock": "clock",
            "calendar": "calendar",
            "worldClock": "world-clock",
            "userCard": "user-card",
            "images": "image-converter",
            "visualizer": "visualizer",
            "customImage": "custom-image",
            "resources": "nandoroid_system_monitor",
            "media": "nandoroid_media",
            "weather": "nandoroid_weather",
            "notes": "notes"
        })

    function migrateDeadParallaxSwitches() {
        if (root.options.background.parallax.migratedFromDeadCode)
            return;
        root.setNestedValue("background.parallax.enable", true);
        root.setNestedValue("background.parallax.enableWorkspace", true);
        root.setNestedValue("background.parallax.enableSidebar", true);
        root.setNestedValue("background.parallax.enableWidgets", true);
        root.setNestedValue("background.parallax.migratedFromDeadCode", true);
    }

    function migratePreferredPlayerToBusId() {
        const stored = root.options.bar.media.preferredPlayer;
        const normalized = MprisSelection.normalizePreferredPlayer(stored);
        if (normalized !== stored)
            root.options.bar.media.preferredPlayer = normalized;
    }

    function migrateSplitCheatsheetButtons() {
        if (root.options.cheatsheet.migratedSplitButtons)
            return;
        root.setNestedValue("cheatsheet.splitButtons", true);
        root.setNestedValue("cheatsheet.migratedSplitButtons", true);
    }

    function migrateDesktopWidgetsToPlugins() {
        if (root.options.plugins.migratedDesktopWidgets)
            return;
        const widgets = root.options.background.widgets;
        const enabled = [];
        for (let i = 0; i < root.options.plugins.enabled.length; i++)
            enabled.push(root.options.plugins.enabled[i]);
        for (const key in root.desktopWidgetPluginIds) {
            const id = root.desktopWidgetPluginIds[key];
            if (widgets[key]?.enable && !enabled.includes(id))
                enabled.push(id);
        }
        root.setNestedValue("plugins.enabled", enabled);
        root.setNestedValue("plugins.migratedDesktopWidgets", true);
    }

    readonly property var desktopClockOptionKeys: ({
            "showOnlyWhenLocked": "showOnlyWhenLocked",
            "style": "style",
            "styleLocked": "styleLocked",
            "color": "color",
            "cookie.aiStyling": "cookieAiStyling",
            "cookie.sides": "cookieSides",
            "cookie.dialNumberStyle": "cookieDialNumberStyle",
            "cookie.hourHandStyle": "cookieHourHandStyle",
            "cookie.minuteHandStyle": "cookieMinuteHandStyle",
            "cookie.secondHandStyle": "cookieSecondHandStyle",
            "cookie.dateStyle": "cookieDateStyle",
            "cookie.timeIndicators": "cookieTimeIndicators",
            "cookie.hourMarks": "cookieHourMarks",
            "cookie.dateInClock": "cookieDateInClock",
            "cookie.constantlyRotate": "cookieConstantlyRotate",
            "cookie.useSineCookie": "cookieUseSineCookie",
            "digital.adaptiveAlignment": "digitalAdaptiveAlignment",
            "digital.showDate": "digitalShowDate",
            "digital.animateChange": "digitalAnimateChange",
            "digital.vertical": "digitalVertical",
            "digital.font.family": "digitalFontFamily",
            "digital.font.weight": "digitalFontWeight",
            "digital.font.width": "digitalFontWidth",
            "digital.font.size": "digitalFontSize",
            "digital.font.roundness": "digitalFontRoundness",
            "pixel.orientation": "pixelOrientation",
            "quote.enable": "quoteEnable",
            "quote.text": "quoteText",
            "quote.followClock": "quoteFollowClock"
        })

    property var pendingPluginOptions: ({})

    property var pendingPluginPositions: ({})

    function migrateDesktopWidgetOptionsToPlugins() {
        const options = {};
        const positions = {};

        if (!root.options.plugins.migratedDesktopWidgetOptions) {
            const clock = root.options.background.widgets.clock;
            if (clock) {
                positions["clock"] = {
                    x: clock.x,
                    y: clock.y,
                    placementStrategy: clock.placementStrategy
                };
                const values = {};
                for (const path in root.desktopClockOptionKeys) {
                    const parts = path.split(".");
                    let node = clock;
                    for (let i = 0; i < parts.length; i++) {
                        if (node === undefined || node === null)
                            break;
                        node = node[parts[i]];
                    }
                    if (node === undefined || node === null)
                        continue;
                    values[root.desktopClockOptionKeys[path]] = node;
                }
                options["clock"] = values;
            }
        }

        if (!root.options.plugins.migratedWorldClockTimezones) {
            const legacy = root.options.background.widgets.worldClock?.timezones;
            if (legacy && legacy.length > 0) {
                const zones = [];
                for (let i = 0; i < legacy.length; i++)
                    zones.push(legacy[i]);
                options["world-clock"] = { "timezones": zones };
            }
        }

        root.pendingPluginPositions = positions;
        root.pendingPluginOptions = options;
    }

    function planUpstreamKeyMigration(legacy) {
        const plan = {};
        if (!legacy || typeof legacy !== "object")
            return plan;

        if (legacy.panelFamily === "ii" || legacy.panelFamily === "waffle")
            plan["panelFamily"] = "imi";

        const legacyBar = legacy.bar;
        if (legacyBar && typeof legacyBar.floatStyleShadow === "boolean")
            plan["bar.shadow"] = legacyBar.floatStyleShadow && legacyBar.cornerStyle === 1;

        return plan;
    }

    function migrateUpstreamKeys(rawConfigText) {
        if (root.options.migratedUpstreamSchema)
            return;
        let legacy;
        try {
            legacy = JSON.parse(rawConfigText);
        } catch (e) {
            return;
        }
        const plan = root.planUpstreamKeyMigration(legacy);
        for (const key in plan)
            root.setNestedValue(key, plan[key]);
        root.setNestedValue("migratedUpstreamSchema", true);
    }

    function setNestedValue(nestedKey, value) {
        let keys = nestedKey.split(".");
        let obj = root.options;
        let parents = [obj];

        for (let i = 0; i < keys.length - 1; ++i) {
            if (!obj[keys[i]] || typeof obj[keys[i]] !== "object") {
                obj[keys[i]] = {};
            }
            obj = obj[keys[i]];
            parents.push(obj);
        }

        let convertedValue = value;
        if (typeof value === "string") {
            let trimmed = value.trim();
            if (trimmed === "true" || trimmed === "false" || !isNaN(Number(trimmed))) {
                try {
                    convertedValue = JSON.parse(trimmed);
                } catch (e) {
                    convertedValue = value;
                }
            }
        }

        obj[keys[keys.length - 1]] = convertedValue;
    }

    property bool configDirTimedOut: false
    readonly property bool configDirReady: Directories.configDirReady || root.configDirTimedOut

    Timer {
        id: configDirWatchdog
        interval: 10000
        running: !Directories.configDirReady
        onTriggered: {
            root.configDirTimedOut = true;
        }
    }

    Timer {
        id: fileReloadTimer
        interval: root.readWriteDelay
        repeat: false
        onTriggered: {
            configFileView.reload()
        }
    }

    Timer {
        id: fileWriteTimer
        interval: root.readWriteDelay
        repeat: false
        onTriggered: {
            if (root.configDirTimedOut)
                return;
            configFileView.writeAdapter()
        }
    }

    FileView {
        id: configFileView
        path: root.configDirReady ? root.filePath : ""
        watchChanges: true
        blockWrites: root.blockWrites
        onFileChanged: fileReloadTimer.restart()
        onAdapterUpdated: fileWriteTimer.restart()
        onLoaded: {
            root.migrateUpstreamKeys(text());
            root.ready = true;
            root.migratePreferredPlayerToBusId();
            root.migrateDeadParallaxSwitches();
            root.migrateSplitCheatsheetButtons();
            root.migrateDesktopWidgetsToPlugins();
            root.migrateDesktopWidgetOptionsToPlugins();
        }
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                if (!root.configDirTimedOut)
                    writeAdapter();
                else
                    root.ready = true;
                return;
            }
            root.ready = true;
        }

        JsonAdapter {
            id: configOptionsJsonAdapter

            property string panelFamily: "imi"

            property bool migratedUpstreamSchema: false

            property JsonObject plugins: JsonObject {
                property list<string> enabled: []
                property bool storeEnabled: false
                property real blurOpacity: 0.1
                property string frostMode: "blur"
                property bool migratedDesktopWidgets: false
                property bool migratedDesktopWidgetOptions: false
                property bool migratedWorldClockTimezones: false
            }

            property JsonObject policies: JsonObject {
                property int ai: 1
                property int weeb: 1
            }

            property JsonObject ai: JsonObject {
                property string systemPrompt: "## Style\n- Use casual tone, don't be formal!\n- Always be brief and to the point, unless asked otherwise\n- Don't repeat the user's question\n- Be approachable: Avoid using overly complicated, domain-specific terms and provide analogies when asked to explain a concept\n\n## Context (ignore when irrelevant)\n- You are a helpful and inspiring sidebar assistant on a {DISTRO} Linux system\n- Desktop environment: {DE}\n- Current date & time: {DATETIME}\n- Focused app: {WINDOWCLASS}\n\n## Presentation\n- Use Markdown features in your response: \n  - **Bold** text to **highlight keywords** in your response\n  - **Split long information into small sections** with h2 headers and a relevant emoji at the start of it (for example `## 🐧 Linux`). Bullet points are preferred over long paragraphs, unless you're offering writing support or instructed otherwise by the user.\n- Asked to compare different options? You should firstly use a table to compare the main aspects, then elaborate or include relevant comments from online forums *after* the table. Make sure to provide a final recommendation for the user's use case!\n- Use LaTeX formatting for mathematical and scientific notations whenever appropriate. Enclose all LaTeX '$$' delimiters. NEVER generate LaTeX code in a latex block unless the user explicitly asks for it. DO NOT use LaTeX for regular documents (resumes, letters, essays, CVs, etc.).\n\nThanks!\n"
                property string tool: "functions"
                property string persona: ""
                property list<var> personas: []
                property JsonObject documents: JsonObject {
                    property list<string> folders: []
                    property string embedder: "lexical"
                    property int topK: 6
                    property bool alwaysAttach: false
                }
                property list<var> customProviders: [
                    {
                        "enabled": false,
                        "name": "OpenRouter",
                        "baseUrl": "https://openrouter.ai/api/v1"
                    }
                ]
                property list<var> extraModels: [
                    {
                        "api_format": "openai",
                        "description": "This is a custom model. Edit the config to add more! | Anyway, this is DeepSeek R1 Distill LLaMA 70B",
                        "endpoint": "https://openrouter.ai/api/v1/chat/completions",
                        "homepage": "https://openrouter.ai/deepseek/deepseek-r1-distill-llama-70b:free",
                        "icon": "spark-symbolic",
                        "key_get_link": "https://openrouter.ai/settings/keys",
                        "key_id": "openrouter",
                        "model": "deepseek/deepseek-r1-distill-llama-70b:free",
                        "name": "Custom: DS R1 Dstl. LLaMA 70B",
                        "requires_key": true
                    }
                ]
            }

            property JsonObject appearance: JsonObject {
                property string iconTheme: ""
                property bool extraBackgroundTint: true
                property int fakeScreenRounding: 2
                property JsonObject autoTheme: JsonObject {
                    property string mode: "off"
                    property string lightTime: "07:00"
                    property string darkTime: "19:00"
                }
                property JsonObject fonts: JsonObject {
                    property string main: "Google Sans Flex"
                    property string numbers: "Google Sans Flex"
                    property string title: "Google Sans Flex"
                    property string iconNerd: "JetBrains Mono NF"
                    property string monospace: "JetBrains Mono NF"
                    property string reading: "Readex Pro"
                    property string expressive: "Space Grotesk"
                }
                property JsonObject motion: JsonObject {
                    property real multiplier: 1.0
                    property bool reduceMotion: false
                }
                property JsonObject transparency: JsonObject {
                    property bool enable: false
                    property bool automatic: true
                    property real backgroundTransparency: 0.11
                    property real contentTransparency: 0.57
                }
                property JsonObject terminal: JsonObject {
                    property JsonObject background: JsonObject {
                        property bool enabled: false
                        property string imagePath: ""
                        property string layout: "tiled"
                        property real opacity: 0.18
                    }
                }
                property JsonObject wallpaperTheming: JsonObject {
                    property bool enableAppsAndShell: true
                    property bool enableQtApps: true
                    property bool enableTerminal: true
                    property JsonObject terminalGenerationProps: JsonObject {
                        property real harmony: 0.6
                        property real harmonizeThreshold: 100
                        property real termFgBoost: 0.35
                        property bool forceDarkMode: false
                    }
                }
                property JsonObject openrgb: JsonObject {
                    property bool enable: false
                    property list<string> excludedDevices: []
                    property string colorSource: "accent"
                    property bool monitorFullscreenOnly: true
                    property int monitorPollInterval: 200
                    property int monitorColorDelta: 12
                    property bool monitorSmooth: true
                    property list<string> monitorExcludedTypes: ["GPU"]
                }
                property JsonObject palette: JsonObject {
                    property string type: "auto"
                    property string accentColor: ""
                }
                property JsonObject clockFonts: JsonObject {
                    property string desktopTimeFont: "Google Sans Flex"
                    property string lockscreenTimeFont: "Google Sans Flex"
                }
                property JsonObject clock: JsonObject {
                    property string style: "digital"
                    property string styleLocked: "digital"
                    property bool showOnDesktop: true
                    property bool showDesktopDate: true
                    property bool showLockscreenDate: true
                    property bool useSameStyle: true
                    property int offsetX: 0
                    property int offsetY: -50
                    property JsonObject digital: JsonObject { property bool isVertical: false; property string colorStyle: "primary"; property int fontSize: 84; property int dateFontSize: 24; property int dateGap: 4; property bool hideAmPm: false; property string alignment: "center" }
                    property JsonObject digitalLocked: JsonObject { property bool isVertical: false; property string colorStyle: "primary"; property int fontSize: 84; property int dateFontSize: 24; property int dateGap: 4; property bool hideAmPm: false; property string alignment: "center" }
                    property JsonObject analog: JsonObject { property bool constantlyRotate: false; property string backgroundStyle: "shape"; property int sides: 12; property string backgroundShape: "Circle"; property string shape: "Circle"; property bool showMarks: true; property bool hourMarks: false; property bool timeIndicators: false; property string dateStyle: "bubble"; property string handStyle: "modern"; property string hourHandStyle: "fill"; property string minuteHandStyle: "bold"; property string secondHandStyle: "dot"; property string dialStyle: "dots"; property int size: 240 }
                    property JsonObject analogLocked: JsonObject { property bool constantlyRotate: false; property string backgroundStyle: "shape"; property int sides: 12; property string backgroundShape: "Circle"; property string shape: "Circle"; property bool showMarks: true; property bool hourMarks: false; property bool timeIndicators: false; property string dateStyle: "bubble"; property string handStyle: "modern"; property string hourHandStyle: "fill"; property string minuteHandStyle: "bold"; property string secondHandStyle: "dot"; property string dialStyle: "dots"; property int size: 240 }
                    property JsonObject code: JsonObject { property string valueColorStyle: "primary"; property string keywordColorStyle: "tertiary"; property string blockColorStyle: "primary"; property int fontSize: 18; property string blockType: "js"; property string fontFamily: "JetBrains Mono NF" }
                    property JsonObject codeLocked: JsonObject { property string valueColorStyle: "primary"; property string keywordColorStyle: "tertiary"; property string blockColorStyle: "primary"; property int fontSize: 18; property string blockType: "js"; property string fontFamily: "JetBrains Mono NF" }
                    property JsonObject text: JsonObject { property int fontSize: 42; property int dateFontSize: 18; property string alignment: "center"; property string timeColorStyle: "onSurface"; property string dateColorStyle: "primary" }
                    property JsonObject textLocked: JsonObject { property int fontSize: 42; property int dateFontSize: 18; property string alignment: "center"; property string timeColorStyle: "onSurface"; property string dateColorStyle: "primary" }
                    property JsonObject pill: JsonObject { property int size: 120; property bool isVertical: false; property bool showBackground: true; property string timeColorStyle: "onLayer0"; property string dateColorStyle: "primary"; property string pillColorStyle: "surfaceContainerHigh" }
                    property JsonObject pillLocked: JsonObject { property int size: 120; property bool isVertical: false; property bool showBackground: true; property string timeColorStyle: "onLayer0"; property string dateColorStyle: "primary"; property string pillColorStyle: "surfaceContainerHigh" }
                }
                property JsonObject atAGlance: JsonObject { property bool showGreeting: true; property bool showDate: true; property bool showEvents: true; property bool showQuote: true; property real customWidth: 0; property string alignment: "left"; property string fontFamily: ""; property int fontSize: 24; property string greetingColorStyle: "primary"; property string dateColorStyle: "onLayer1"; property string quoteColorStyle: "onLayer1"; property bool locked: false }
                property JsonObject mediaWidget: JsonObject { property bool locked: false; property bool showLyrics: false }
                property JsonObject systemMonitor: JsonObject { property bool locked: false; property bool vertical: false; property int updateInterval: 3000 }
                property JsonObject weatherWidget: JsonObject { property bool locked: false; property string sizeMode: "3x1" }
                property JsonObject currencyWidget: JsonObject { property bool locked: false; property string sizeMode: "2x1"; property string baseCurrency: "USD"; property string quote1: "EUR"; property string quote2: "GBP"; property string quote3: "JPY"; property string quote4: "CAD" }
                property JsonObject lyrics: JsonObject { property bool showFloatingLyrics: false; property bool lyricsUseRomaji: false }
            }

            property JsonObject audio: JsonObject {
                property JsonObject protection: JsonObject {
                    property bool enable: false
                    property real maxAllowedIncrease: 10
                    property real maxAllowed: 99
                }
            }

            property JsonObject profile: JsonObject {
                property string avatarPath: ""
                property string avatarPicture: ""
                property string descriptionText: "::distro::"
                property string displayName: ""

            }

            property JsonObject hyprland: JsonObject {
                property JsonObject animations: JsonObject {
                    property string animation: "normal"
                    property bool enable: true
                }
                property JsonObject autostartApps: JsonObject {
                    property bool enable: false
                    property list<var> apps: []
                }
                property JsonObject decoration: JsonObject {
                    property int rounding: 22
                    property real activeOpacity: 1.0
                    property real inactiveOpacity: 0.9
                    property JsonObject blur: JsonObject {
                        property bool enabled: true
                        property int size: 1
                        property int passes: 3
                        property bool ignoreOpacity: true
                        property bool newOptimizations: true
                        property bool xray: false
                        property real noise: 0.05
                        property real contrast: 0.89
                        property real brightness: 1.0
                        property real vibrancy: 0.0
                        property real vibrancyDarkness: 0.5
                        property bool special: true
                        property bool popups: false
                        property real popupsIgnorealpha: 0.6
                        property bool inputMethods: true
                        property real inputMethodsIgnorealpha: 0.8
                    }
                    property JsonObject shadow: JsonObject {
                        property bool enabled: true
                        property int range: 4
                    }
                }
                property JsonObject cursor: JsonObject {
                    property string theme: "Bibata-Modern-Classic"
                    property int size: 24
                    property real zoomFactor: 1.0
                    property int inactiveTimeout: 0
                }
                property JsonObject general: JsonObject {
                    property int borderSize: 1
                    property int gapsIn: 2
                    property int gapsOut: 5
                    property string layout: "dwindle"
                }
                property JsonObject input: JsonObject {
                    property string kbLayout: "us"
                    property string kbOptions: ""
                    property bool numlock: true
                    property int repeatDelay: 250
                    property int repeatRate: 35
                    property int followMouse: 1
                    property JsonObject touchpad: JsonObject {
                        property bool naturalScroll: false
                        property bool disableWhileTyping: true
                        property bool clickfingerBehavior: false
                        property real scrollFactor: 0.7
                    }
                }
            }

            property JsonObject apps: JsonObject {
                property string bluetooth: "kcmshell6 kcm_bluetooth"
                property string changePassword: "kitty -1 --hold=yes fish -i -c 'passwd'"
                property string network: "kcmshell6 kcm_networkmanagement"
                property string manageUser: "kcmshell6 kcm_users"
                property string networkEthernet: "kcmshell6 kcm_networkmanagement"
                property string taskManager: "plasma-systemmonitor --page-name Processes"
                property string terminal: "kitty -1"
                property string update: "kitty -1 --hold=yes ryoku update --system"
                property string volumeMixer: `~/.config/hypr/hyprland/scripts/launch_first_available.sh "pavucontrol-qt" "pavucontrol"`
            }

            property JsonObject cheatsheet: JsonObject {
                property string superKey: ""
                property bool useMacSymbol: false
                property bool splitButtons: true
                property bool migratedSplitButtons: false
                property bool useMouseSymbol: false
                property bool useFnSymbol: false
                property JsonObject fontSize: JsonObject {
                    property int key: Appearance.font.pixelSize.smaller
                    property int comment: Appearance.font.pixelSize.smaller
                }
            }

            property JsonObject background: JsonObject {
                property string lockWall: ""
                property string lockWallEngine: ""
                property bool widgetsLocked: false
                property bool showGrid: true
                property bool showSnapLines: true
                property JsonObject widgets: JsonObject {
                    property JsonObject clock: JsonObject {
                        property bool enable: true
                        property bool showOnlyWhenLocked: false
                        property string placementStrategy: "leastBusy"
                        property real x: 100
                        property real y: 100
                        property string style: "cookie"
                        property string color: ""
                        property string styleLocked: "cookie"
                        property JsonObject cookie: JsonObject {
                            property bool aiStyling: false
                            property int sides: 14
                            property string dialNumberStyle: "full"
                            property string hourHandStyle: "fill"
                            property string minuteHandStyle: "medium"
                            property string secondHandStyle: "dot"
                            property string dateStyle: "bubble"
                            property bool timeIndicators: true
                            property bool hourMarks: false
                            property bool dateInClock: true
                            property bool constantlyRotate: false
                            property bool useSineCookie: false
                        }
                        property JsonObject digital: JsonObject {
                            property bool adaptiveAlignment: true
                            property bool showDate: true
                            property bool animateChange: true
                            property bool vertical: false
                            property JsonObject font: JsonObject {
                                property string family: "Google Sans Flex"
                                property real weight: 350
                                property real width: 100
                                property real size: 90
                                property real roundness: 0
                            }
                        }
                        property JsonObject pixel: JsonObject {
                            property string orientation: "vertical"
                        }
                        property JsonObject quote: JsonObject {
                            property bool enable: false
                            property string text: ""
                            property bool followClock: false
                        }
                    }
                    property JsonObject weather: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                        property string sizeMode: "1x3"
                    }

                    property JsonObject calendar: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                        property string sizeMode: "2x2"
                    }
                    property JsonObject worldClock: JsonObject {
                        property bool enable: false
                        property list<string> timezones: ["Australia/Sydney", "Asia/Tokyo", "Europe/London", "America/New_York"]
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                        property string sizeMode: "2x2" 
                    }

                    property JsonObject notes: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                    }

                    property JsonObject userCard: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                    }

                    property JsonObject images: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                    }

                    property JsonObject visualizer: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 0
                        property real y: 0
                    }

                    property JsonObject customImage: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                        property string path: ""
                        property string shape: "Cookie4Sided"
                        property real size: 200
                    }

                    property JsonObject resources: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free"
                        property real x: 400
                        property real y: 100
                        property bool vertical: false
                    }

                    property JsonObject media: JsonObject {
                        property bool enable: false
                        property bool showControls: true
                        property bool showLyrics: false
                        property bool showTitles: true
                        property string backgroundShape: "Cookie4Sided"
                        property string placementStrategy: "free"
                        property real x: 800
                        property real y: 500
                    }
                }
                property list<string> screenList: [] 
                property string wallpaperPath: ""
                property bool centeredWallpaper: false
                property string centeredWallpaperShape: "Cookie7Sided"
                property int centeredWallpaperSize: 400
                property string centeredWallpaperColor: "primaryContainer"
                property bool centeredWallpaperOnlyWhenLocked: false
                property string wallpaperAnimation: "magic"
                property bool enableWallpaperPreview: false
                property string thumbnailPath: ""
                property bool hideWhenFullscreen: true
                property JsonObject parallax: JsonObject {
                    property bool enable: true
                    property bool vertical: false
                    property bool autoVertical: true
                    property bool enableWorkspace: true
                    property real workspaceZoom: 1.1
                    property bool enableSidebar: true
                    property bool enableWidgets: true
                    property real widgetsFactor: 1.2
                    property bool migratedFromDeadCode: false
                }
                property JsonObject clockDepth: JsonObject {
                    property bool enable: false
                }
            }

            property JsonObject bar: JsonObject {
                property JsonObject autoHide: JsonObject {
                    property bool enable: false
                    property int hoverRegionWidth: 2
                    property bool pushWindows: false
                    property bool dismissPopups: true
                    property JsonObject showWhenPressingSuper: JsonObject {
                        property bool enable: true
                        property int delay: 140
                    }
                }
                property bool bottom: false
                property int cornerStyle: 3
                property bool shadow: false
                property string borderless: "pills"
                property string topLeftIcon: "spark"
                property bool showBackground: true
                property real backgroundOpacity: 1.0
                property bool verbose: true
                property bool vertical: false
                property JsonObject resources: JsonObject {
                    property string style: "outline"
                    property bool showValue: false
                    property bool alwaysShowSwap: false
                    property bool alwaysShowCpu: true
                    property bool alwaysShowCpuTemp: false
                    property bool alwaysShowDisk: true
                    property bool alwaysShowRam: true
                    property bool alwaysShowGpu: false
                    property bool alwaysShowGpuTemp: false
                    property bool alwaysShowVram: false
                    property int memoryWarningThreshold: 95
                    property int swapWarningThreshold: 85
                    property int cpuWarningThreshold: 90
                    property int gpuWarningThreshold: 90
                    property int vramWarningThreshold: 95
                }
                property JsonObject divider: JsonObject {
                    property string style: "rect"
                    property int spacing: 20
                }

                property JsonObject layouts: JsonObject {
                    property list<string> leftLayout: ["leftSidebarButton", "activeWindow"]
                    property list<string> middleLayout: ["visualizer", "media", "resources", "workspaces", "utilButtons", "clockWidget", "weatherBar", "visualizer"]
                    property list<string> rightLayout: ["submapIndicator", "sysTray", "hyprlandXkbIndicator", "rightSidebarButton", "systemIcons"]
                }
                
                property list<string> screenList: []
                property JsonObject utilButtons: JsonObject {
                    property bool showScreenSnip: true
                    property bool showColorPicker: false
                    property bool showMicToggle: false
                    property bool showKeyboardToggle: true
                    property bool showWallpaperToggle: false
                    property bool showDarkModeToggle: true
                    property bool showPerformanceProfileToggle: false
                    property bool showScreenRecord: false       
                    property bool showSettingsButton: true
                    property bool isRecording: false
                }

                property JsonObject workspaces: JsonObject {
                    property bool monochromeIcons: true
                    property int shown: 10
                    property bool showAppIcons: true
                    property bool showAllMonitors: true
                    property string indicatorStyle: "dot"
                    property bool alwaysShowNumbers: false
                    property int showNumberDelay: 300
                    property list<string> numberMap: ["1", "2"]
                    property bool useNerdFont: false
                }
                property JsonObject weather: JsonObject {
                    property bool enable: false
                    property bool enableGPS: true
                    property string city: ""
                    property bool useUSCS: false
                    property int fetchInterval: 10
                    property string provider: "owm"
                    property string apiKey: ""
                }
                property JsonObject privacyIndicator: JsonObject {
                    property bool enable: true
                    property int pollInterval: 2000
                    property bool showMic: true
                    property bool showCamera: true
                    property bool showScreencast: true
                    property bool ignoreAmbientCapture: true
                    property bool allowForceStop: false
                }
                property JsonObject indicators: JsonObject {
                    property JsonObject notifications: JsonObject {
                        property bool showUnreadCount: false
                    }
                }
                property JsonObject tooltips: JsonObject {
                    property bool clickToShow: false
                }
                property JsonObject media: JsonObject {
                    property string preferredPlayer: ""
                    property bool alwaysVisible: false
                    property bool onlyTitle: false
                    property int maxWidth: 280
                    property int minWidth: 100
                }
            }

            property JsonObject battery: JsonObject {
                property int low: 20
                property int critical: 5
                property int full: 101
                property bool automaticSuspend: true
                property int suspend: 3
            }

            property JsonObject calendar: JsonObject {
                property string locale: "en-GB"
                property int firstDayOfWeek: 1
                property JsonObject ics: JsonObject {
                    property list<string> files: []
                    property list<string> urls: []
                    property int refreshInterval: 30
                }
            }

            property JsonObject conflictKiller: JsonObject {
                property bool autoKillNotificationDaemons: false
                property bool autoKillTrays: false
            }

            property JsonObject crosshair: JsonObject {
                property string code: "0;P;d;1;0l;10;0o;2;1b;0"
            }

            property JsonObject dock: JsonObject {
                property bool enable: false
                property bool showBackground: true
                property bool showPinButton: true
                property bool showAppsButton: true
                property bool showMedia: true
                property bool monochromeIcons: true
                property real height: 60
                property string edge: "bottom"
                property real hoverRegionHeight: 2
                property bool pinnedOnStartup: false
                property bool hoverToReveal: true
                property list<string> pinnedApps: [
                    "org.kde.dolphin", "kitty",]
                property list<string> ignoredAppRegexes: []
            }

            property JsonObject dropShelf: JsonObject {
                property bool dragToBarReveal: true
                property bool shakeToSummon: false
                property real shakeSensitivity: 1.0
                property int autoDismissSeconds: 5
                property bool blurBackground: true
                property real backgroundOpacity: 0.5
            }

            property JsonObject interactions: JsonObject {
                property JsonObject scrolling: JsonObject {
                    property bool fasterTouchpadScroll: false
                    property int mouseScrollDeltaThreshold: 120
                    property int mouseScrollFactor: 120
                    property int touchpadScrollFactor: 450
                }
                property JsonObject deadPixelWorkaround: JsonObject {
                    property bool enable: false
                }
            }

            property JsonObject language: JsonObject {
                property string ui: "auto"
                property JsonObject translator: JsonObject {
                    property string engine: "auto"
                    property string targetLanguage: "auto"
                    property string sourceLanguage: "auto"
                }
            }

            property JsonObject launcher: JsonObject {
                property list<string> pinnedApps: [ "org.kde.dolphin", "kitty", "cmake-gui"]
            }

            property JsonObject light: JsonObject {
                property JsonObject night: JsonObject {
                    property bool automatic: true
                    property string from: "19:00"
                    property string to: "06:30"
                    property int colorTemperature: 5000
                }
                property JsonObject antiFlashbang: JsonObject {
                    property bool enable: false
                }
                property JsonObject clight: JsonObject {
                    property bool enable: true
                }
            }

            property JsonObject lock: JsonObject {
                property bool useHyprlock: false
                property bool launchOnStartup: false
                property bool showWidgets: false
                property bool showMedia: true
                property bool showToolbars: true
                property JsonObject blur: JsonObject {
                    property bool enable: true
                    property real radius: 100
                    property real extraZoom: 1.1
                    property int size: 20
                }
                property bool centerClock: true
                property bool showLockedText: true
                property JsonObject security: JsonObject {
                    property bool unlockKeyring: true
                    property bool requirePasswordToPower: false
                }
                property bool materialShapeChars: true
                property JsonObject islands: JsonObject {
                    property list<string> main: ["fingerprint", "password", "confirm"]
                    property list<string> left: ["username", "media", "keyboardLayout", "fcitx"]
                    property list<string> right: ["battery", "sleep", "power", "reboot"]
                }
            }

            property JsonObject media: JsonObject {
                property bool filterDuplicatePlayers: true
            }

            property JsonObject networking: JsonObject {
                property string userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
                property JsonObject vpn: JsonObject {
                    property bool enable: true
                    property int pollInterval: 5000
                }
                property JsonObject tailscale: JsonObject {
                    property bool enable: true
                    property int pollInterval: 5000
                }
                property JsonObject phoneConnect: JsonObject {
                    property bool enable: true
                    property int pollInterval: 10000
                }
            }

            property JsonObject phone: JsonObject {
                property bool showPeripheralCards: true
                property JsonObject contacts: JsonObject {
                    property bool enabled: true
                    property list<string> favoriteIds: []
                    property string sortBy: "first"
                    property bool hideUnnamed: true
                }
                property JsonObject scrcpy: JsonObject {
                    property bool stayAwake: false
                    property bool turnScreenOff: false
                    property bool noPowerOn: false
                    property bool noAudio: false
                    property bool showTouches: false
                    property bool fullscreen: false
                    property bool alwaysOnTop: false
                    property int maxFps: 0
                    property string bitRate: "8M"
                    property int maxSize: 0
                    property int videoBuffer: 0
                    property bool useWireless: false
                    property bool autoWirelessIp: true
                    property string wirelessIp: ""
                    property string wirelessPort: "5555"
                    property JsonObject appMode: JsonObject {
                        property bool enabled: true
                        property bool flexDisplay: true
                        property int displayWidth: 1280
                        property int displayHeight: 960
                        property int density: 160
                        property bool keepActive: true
                        property bool systemDecorations: true
                        property list<string> favoritePackages: []
                    }
                }
                property JsonObject webcam: JsonObject {
                    property string cameraFacing: "front"
                    property string resolution: "1280x720"
                    property bool mirrorHorizontally: false
                    property int rotateDegrees: 0
                    property string connection: "wifi"
                    property string wifiIp: ""
                    property int port: 4747
                }
                property JsonObject microphone: JsonObject {
                    property string connection: "wifi"
                    property string wifiIp: ""
                    property int port: 4748
                    property int micGain: 100
                    property bool setAsDefault: false
                }
            }

            property JsonObject idleInhibitor: JsonObject {
                property bool autoOnExternalMonitor: false
            }

            property JsonObject screensaver: JsonObject {
                property bool enable: false
                property string mode: "black"
                property int timeout: 240
            }

            property JsonObject notes: JsonObject {
                property bool importedLegacyStore: false
            }

            property JsonObject notifications: JsonObject {
                property int timeout: 7000
                property string position: "top_right"
            }

            property JsonObject osd: JsonObject {
                property int timeout: 1000
                property bool lockKeys: true
            }

            property JsonObject osk: JsonObject {
                property string layout: "qwerty_full"
                property bool pinnedOnStartup: false
                property bool showPhysicalKeys: true
            }

            property JsonObject overlay: JsonObject {
                property bool openingZoomAnimation: true
                property bool darkenScreen: true
                property real clickthroughOpacity: 0.8
                property JsonObject floatingImage: JsonObject {
                    property string imageSource: "https://media.tenor.com/H5U5bJzj3oAAAAAi/kukuru.gif"
                    property real scale: 0.5
                }
            }

            property JsonObject overview: JsonObject {
                property bool enable: true
                property string style: "default"
                property real scale: 0.18
                property real rows: 2
                property real columns: 5
                property bool orderRightLeft: false
                property bool orderBottomUp: false
                property bool centerIcons: true
            }

            property JsonObject regionSelector: JsonObject {
                property JsonObject targetRegions: JsonObject {
                    property bool windows: true
                    property bool layers: false
                    property bool content: true
                    property bool showLabel: false
                    property real opacity: 0.3
                    property real contentRegionOpacity: 0.8
                    property int selectionPadding: 5
                }
                property JsonObject magnifier: JsonObject {
                    property bool enable: true
                    property real zoom: 6
                }
                property JsonObject rect: JsonObject {
                    property bool showAimLines: true
                }
                property JsonObject circle: JsonObject {
                    property int strokeWidth: 6
                    property int padding: 10
                }
                property JsonObject annotation: JsonObject {
                    property bool useSatty: false
                }
            }

            property JsonObject resources: JsonObject {
                property int updateInterval: 3000
                property int historyLength: 60
            }

            property JsonObject tray: JsonObject {
                property bool monochromeIcons: true
                property bool showItemId: false
                property bool invertPinnedItems: true
                property list<var> pinnedItems: [ "Fcitx" ]
                property bool filterPassive: true
            }

            property JsonObject musicRecognition: JsonObject {
                property int timeout: 16
                property int interval: 4
            }

            property JsonObject search: JsonObject {
                property int nonAppResultDelay: 30
                property string engineBaseUrl: "https://www.google.com/search?q="
                property list<string> excludedSites: ["quora.com", "facebook.com"]
                property bool sloppy: false
                property JsonObject prefix: JsonObject {
                    property bool showDefaultActionsWithoutPrefix: true
                    property string action: "/"
                    property string app: ">"
                    property string clipboard: ";"
                    property string emojis: ":"
                    property string keybinds: "<"
                    property string symbols: "."
                    property string math: "="
                    property string shellCommand: "$"
                    property string webSearch: "?"
                    property string file: "~"
                    property string prism: "%"
                }
                property JsonObject fileSearch: JsonObject {
                    property bool enable: true
                    property string root: ""
                    property int maxResults: 20
                    property int delay: 150
                }
                property JsonObject imageSearch: JsonObject {
                    property string imageSearchEngineBaseUrl: "https://lens.google.com/uploadbyurl?url="
                    property bool useCircleSelection: false
                }
            }

            property JsonObject sidebar: JsonObject {
                property bool banner: false
                property bool mediaPlayer: false
                property string bannerImage: ""
                property bool keepRightSidebarLoaded: true
                property JsonObject translator: JsonObject {
                    property bool enable: true
                    property int delay: 300
                }
                property JsonObject media: JsonObject {
                    property bool enable: true
                    property bool artColors: false
                }
                property JsonObject phone: JsonObject {
                    property bool enable: true
                }
                
                property JsonObject ai: JsonObject {
                    property bool textFadeIn: false
                    property string greeting: ""
                }
                property JsonObject booru: JsonObject {
                    property bool allowNsfw: false
                    property string defaultProvider: "yandere"
                    property int limit: 20
                    property JsonObject zerochan: JsonObject {
                        property string username: "[unset]"
                    }
                }
                property JsonObject cornerOpen: JsonObject {
                    property bool enable: true
                    property bool bottom: false
                    property bool valueScroll: true
                    property bool clickless: false
                    property int cornerRegionWidth: 250
                    property int cornerRegionHeight: 5
                    property bool visualize: false
                    property bool clicklessCornerEnd: true
                    property int clicklessCornerVerticalOffset: 1
                }

                property JsonObject quickToggles: JsonObject {
                    property string style: "android"
                    property JsonObject android: JsonObject {
                        property list<var> pages: []
                        property int columns: 5
                        property list<var> toggles: [
                            { "size": 2, "type": "network" },
                            { "size": 2, "type": "bluetooth"  },
                            { "size": 1, "type": "idleInhibitor" },
                            { "size": 1, "type": "mic" },
                            { "size": 2, "type": "audio" },
                            { "size": 2, "type": "nightLight" }
                        ]
                    }
                }

                property JsonObject quickSliders: JsonObject {
                    property bool enable: false
                    property bool showMic: false
                    property bool showVolume: true
                    property bool showBrightness: true
                }
            }

            property JsonObject custom: JsonObject {
                property string distroIcon: ""
                property bool colorizeIcon: true
            }

            property JsonObject screenRecord: JsonObject {
                property string savePath: Directories.videos ? Directories.videos.replace("file://","") : ""
                property int fps: 60
                property string quality: "very_high"
                property string codec: "auto"
                property string audioCodec: "opus"
                property bool recordAudio: true
                property bool recordMic: false
                property bool showCursor: true
                property string framerateMode: "vfr"
                property bool tonemapSdr: false
                property JsonObject replay: JsonObject {
                    property bool enable: false
                    property int duration: 120
                    property string savePath: ""
                    property string monitor: ""
                    property string storage: "ram"
                    property bool restartOnSave: false
                }
            }

            property JsonObject screenSnip: JsonObject {
                property string savePath: ""
            }

            property JsonObject screenshotResult: JsonObject {
                property bool enable: true
                property int timeoutMs: 6000
                property list<string> editorCommand: []
            }

            property JsonObject sounds: JsonObject {
                property bool battery: false
                property bool pomodoro: false
                property string theme: "freedesktop"
            }

            property JsonObject time: JsonObject {
                property string format: "hh:mm"
                property string shortDateFormat: "dd/MM"
                property string dateWithYearFormat: "dd/MM/yyyy"
                property string dateFormat: "ddd, dd/MM"
                property JsonObject pomodoro: JsonObject {
                    property int breakTime: 300
                    property int cyclesBeforeLongBreak: 4
                    property int focus: 1500
                    property int longBreak: 900
                }
                property bool secondPrecision: false
            }

            property JsonObject updates: JsonObject {
                property bool enableCheck: true
                property int checkInterval: 120
                property int adviseUpdateThreshold: 75
                property int stronglyAdviseUpdateThreshold: 200
            }
            
            property JsonObject wallpaperSelector: JsonObject {
                property bool useSystemFileDialog: false
                property bool showBlurBackground: false
                property bool showHomePath: true
                property string userPath: ""
                property string liveWallpapersPath: ""
                property bool showSearchbar: true
                property int columns: 4
                property bool closeAfterSelection: true
                property int changeInterval: 0 
                property JsonObject wallpaperEngine: JsonObject {
                    property string libraryPath: ""
                    property string activeProject: ""
                    property string activePath: ""
                    property string activePreview: ""
                    property string activeType: ""
                    property int fps: 30
                    property string scaling: "fill"
                    property bool silent: true
                }
            }

            property JsonObject windows: JsonObject {
                property bool showTitlebar: true
                property bool centerTitle: true
            }

            property JsonObject hacks: JsonObject {
                property int arbitraryRaceConditionDelay: 20
            }

            property JsonObject workSafety: JsonObject {
                property JsonObject enable: JsonObject {
                    property bool wallpaper: false
                    property bool clipboard: false
                }
                property JsonObject triggerCondition: JsonObject {
                    property list<string> networkNameKeywords: ["airport", "cafe", "college", "company", "eduroam", "free", "guest", "public", "school", "university"]
                    property list<string> fileKeywords: ["anime", "booru", "ecchi", "hentai", "yande.re", "konachan", "breast", "nipples", "pussy", "nsfw", "spoiler", "girl"]
                    property list<string> linkKeywords: ["hentai", "porn", "sukebei", "hitomi.la", "rule34", "gelbooru", "fanbox", "dlsite"]
                }
            }
        }
    }
}
