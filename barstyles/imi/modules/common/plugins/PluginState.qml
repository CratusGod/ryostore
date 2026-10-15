pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../../.."
import ".."
import "gridSizes.js" as GridSizes
import "layout_surfaces.js" as Surfaces

Singleton {
    id: root

    readonly property int schemaVersion: 2
    readonly property string filePath: `${Directories.shellConfig}/plugin-state.json`
    property var state: root.emptyState()
    property bool ready: false

    function emptyState() {
        return {
            version: root.schemaVersion,
            desktopPositions: {},
            lockPositions: {},
            lockPresence: null,
            pluginOptions: {},
            presetPersist: {},
            migrations: {}
        };
    }

    function defaultPosition() {
        return {
            x: 100,
            y: 100,
            placementStrategy: "free"
        };
    }

    function validNumber(value, fallback) {
        return typeof value === "number" && Number.isFinite(value) ? value : fallback;
    }

    function normalizedPosition(value) {
        const fallback = root.defaultPosition();
        if (!value || typeof value !== "object" || Array.isArray(value)) return fallback;
        return {
            x: root.validNumber(value.x, fallback.x),
            y: root.validNumber(value.y, fallback.y),
            placementStrategy: typeof value.placementStrategy === "string"
                ? value.placementStrategy
                : fallback.placementStrategy
        };
    }

    readonly property string currentSurface: GlobalStates.lockLookActive
        ? Surfaces.LOCK : Surfaces.DESKTOP
    readonly property string lockSurface: Surfaces.LOCK
    readonly property string desktopSurface: Surfaces.DESKTOP

    function lockLayoutForked(screenName) {
        return Surfaces.isForked(root.state, screenName);
    }

    function rawPosition(pluginId, screenName, surface) {
        return Surfaces.rawPosition(root.state, surface ?? root.currentSurface,
            screenName, pluginId);
    }

    function position(pluginId, screenName, surface) {
        return root.normalizedPosition(root.rawPosition(pluginId, screenName, surface));
    }

    function setPosition(pluginId, screenName, value, surface) {
        if (!pluginId || !screenName) return;
        const nextState = Surfaces.withPosition(root.state, surface ?? root.currentSurface,
            screenName, pluginId, root.normalizedPosition(value));
        nextState.version = root.schemaVersion;
        root.state = nextState;
        writeTimer.restart();
    }

    function gridSize(pluginId, screenName, surface) {
        return Surfaces.rawGridSize(root.state, surface ?? root.currentSurface,
            screenName, pluginId);
    }

    function setGridSize(pluginId, screenName, value, surface) {
        if (!pluginId) return;
        const nextState = Surfaces.withGridSize(root.state, surface ?? root.currentSurface,
            screenName, pluginId, value);
        nextState.version = root.schemaVersion;
        root.state = nextState;
        writeTimer.restart();
    }

    function lockRecords(screenName) {
        return Object.assign({}, root.state?.lockPositions?.[screenName] ?? {});
    }

    function restoreLockRecords(screenName, records) {
        if (!screenName || !records) return;
        const nextState = Object.assign({}, root.state);
        const store = Object.assign({}, nextState.lockPositions || {});
        store[screenName] = Object.assign({}, records);
        nextState.lockPositions = store;
        nextState.version = root.schemaVersion;
        root.state = nextState;
        writeTimer.restart();
    }

    function lockPresenceForked() {
        return Surfaces.isPresenceForked(root.state);
    }

    function lockWidgetEnabled(pluginId) {
        return Surfaces.lockPresent(root.state, Config.options.plugins.enabled, pluginId);
    }

    function setLockWidgetEnabled(pluginId, enabled) {
        if (!pluginId) return;
        const nextState = Surfaces.withLockPresence(root.state,
            Config.options.plugins.enabled, pluginId, enabled === true);
        nextState.version = root.schemaVersion;
        root.state = nextState;
        writeTimer.restart();
    }

    function lockPresenceRecords() {
        return Surfaces.isPresenceForked(root.state)
            ? Object.assign({}, root.state.lockPresence)
            : null;
    }

    function restoreLockPresence(records) {
        const nextState = Object.assign({}, root.state);
        nextState.lockPresence = records ? Object.assign({}, records) : null;
        nextState.version = root.schemaVersion;
        root.state = nextState;
        writeTimer.restart();
    }

    function resetLockPresence() {
        const nextState = Surfaces.withoutLockPresence(root.state);
        if (nextState === root.state) return;
        nextState.version = root.schemaVersion;
        root.state = nextState;
        writeTimer.restart();
    }

    function resetLockLayout(screenName) {
        const nextState = Surfaces.withoutLockLayout(root.state, screenName);
        if (nextState === root.state) return;
        nextState.version = root.schemaVersion;
        root.state = nextState;
        writeTimer.restart();
    }

    function option(pluginId, key, fallback) {
        const value = root.state?.pluginOptions?.[pluginId]?.[key];
        return value === undefined ? fallback : value;
    }

    function resolveBackgroundOpacity(baseOpacity, transparencyEnabled, keepTranslucent) {
        return (transparencyEnabled || keepTranslucent) ? baseOpacity : 1;
    }

    function effectiveBackgroundOpacity(pluginId, baseOpacity, keepTranslucentDefault) {
        return root.resolveBackgroundOpacity(
            baseOpacity === undefined ? Config.options.plugins.blurOpacity : baseOpacity,
            Config.options.appearance.transparency.enable,
            root.option(pluginId, "keepTranslucent", keepTranslucentDefault === true));
    }

    readonly property string sizeModeMarker: "migratedSizeMode"

    function migrationRan(name) {
        return root.state?.migrations?.[name] === true;
    }

    function stateWithSizeModesMigrated(state, manifests) {
        const nextOptions = Object.assign({}, state?.pluginOptions || {});
        for (const manifest of manifests) {
            if (!manifest || !manifest.id) continue;
            const migrated = GridSizes.migrateSizeMode(nextOptions[manifest.id], manifest.grid);
            if (!migrated) continue;
            nextOptions[manifest.id] = migrated;
        }

        const nextMigrations = Object.assign({}, state?.migrations || {});
        nextMigrations[root.sizeModeMarker] = true;

        const nextState = Object.assign({}, state);
        nextState.version = root.schemaVersion;
        nextState.pluginOptions = nextOptions;
        nextState.migrations = nextMigrations;
        return nextState;
    }

    function migrateSizeModes(manifests) {
        if (!root.ready) return;
        if (root.migrationRan(root.sizeModeMarker)) return;
        if (!Array.isArray(manifests) || manifests.length === 0) return;

        root.state = root.stateWithSizeModesMigrated(root.state, manifests);
        writeTimer.restart();
    }

    function presetPersisted(pluginId) {
        return root.state?.presetPersist?.[pluginId] === true;
    }

    function setPresetPersist(pluginId, persisted) {
        if (!pluginId) return;
        const nextState = Object.assign({}, root.state);
        const nextPersist = Object.assign({}, nextState.presetPersist || {});
        if (persisted) nextPersist[pluginId] = true;
        else delete nextPersist[pluginId];
        nextState.version = root.schemaVersion;
        nextState.presetPersist = nextPersist;
        root.state = nextState;
        writeTimer.restart();
    }

    function setOption(pluginId, key, value) {
        if (!pluginId || !key) return;

        const nextState = Object.assign({}, root.state);
        const nextOptions = Object.assign({}, nextState.pluginOptions || {});
        const nextPlugin = Object.assign({}, nextOptions[pluginId] || {});
        if (value === null || value === undefined) delete nextPlugin[key];
        else nextPlugin[key] = value;
        nextOptions[pluginId] = nextPlugin;
        nextState.version = root.schemaVersion;
        nextState.pluginOptions = nextOptions;
        root.state = nextState;
        writeTimer.restart();
    }

    property bool drainingConfigOptions: false

    function drainPendingConfigOptions() {
        if (root.drainingConfigOptions)
            return;
        if (!root.ready || !Config.ready)
            return;
        if (Config.options.plugins.migratedDesktopWidgetOptions
            && Config.options.plugins.migratedWorldClockTimezones)
            return;
        const pending = Config.pendingPluginOptions;
        if (!pending || typeof pending !== "object")
            return;

        root.drainingConfigOptions = true;

        const nextState = Object.assign({}, root.state);
        const nextOptions = Object.assign({}, nextState.pluginOptions || {});
        for (const pluginId in pending) {
            const incoming = pending[pluginId];
            if (!incoming || typeof incoming !== "object")
                continue;
            const nextPlugin = Object.assign({}, nextOptions[pluginId] || {});
            for (const key in incoming) {
                if (nextPlugin[key] !== undefined)
                    continue;
                nextPlugin[key] = incoming[key];
            }
            nextOptions[pluginId] = nextPlugin;
        }

        const pendingPositions = Config.pendingPluginPositions || {};
        const nextScreens = Object.assign({}, nextState.desktopPositions || {});
        for (const screen of Quickshell.screens) {
            const nextScreen = Object.assign({}, nextScreens[screen.name] || {});
            let touched = false;
            for (const pluginId in pendingPositions) {
                if (nextScreen[pluginId] !== undefined)
                    continue;
                nextScreen[pluginId] = root.normalizedPosition(pendingPositions[pluginId]);
                touched = true;
            }
            if (touched)
                nextScreens[screen.name] = nextScreen;
        }

        nextState.version = root.schemaVersion;
        nextState.pluginOptions = nextOptions;
        nextState.desktopPositions = nextScreens;
        root.state = nextState;
        writeTimer.restart();

        Config.pendingPluginOptions = ({});
        Config.pendingPluginPositions = ({});
        Config.options.plugins.migratedDesktopWidgetOptions = true;
        Config.options.plugins.migratedWorldClockTimezones = true;
        root.drainingConfigOptions = false;
    }

    Connections {
        target: Config
        function onPendingPluginOptionsChanged() { root.drainPendingConfigOptions() }
        function onReadyChanged() { root.drainPendingConfigOptions() }
    }

    onReadyChanged: root.drainPendingConfigOptions()

    function snapshot() {
        return JSON.stringify(root.state);
    }

    function replaceSnapshot(text) {
        writeTimer.stop();
        reloadTimer.stop();
        root.loadText(text);
        stateFile.setText(JSON.stringify(root.state, null, 2));
    }

    function loadText(text) {
        try {
            const parsed = JSON.parse(text);
            if (!parsed || typeof parsed !== "object" || Array.isArray(parsed))
                throw new Error("root value must be an object");

            root.state = {
                version: root.schemaVersion,
                desktopPositions: parsed.desktopPositions
                    && typeof parsed.desktopPositions === "object"
                    && !Array.isArray(parsed.desktopPositions)
                    ? parsed.desktopPositions
                    : {},
                lockPositions: parsed.lockPositions
                    && typeof parsed.lockPositions === "object"
                    && !Array.isArray(parsed.lockPositions)
                    ? parsed.lockPositions
                    : {},
                lockPresence: parsed.lockPresence
                    && typeof parsed.lockPresence === "object"
                    && !Array.isArray(parsed.lockPresence)
                    ? parsed.lockPresence
                    : null,
                pluginOptions: parsed.pluginOptions
                    && typeof parsed.pluginOptions === "object"
                    && !Array.isArray(parsed.pluginOptions)
                    ? parsed.pluginOptions
                    : {},
                presetPersist: parsed.presetPersist
                    && typeof parsed.presetPersist === "object"
                    && !Array.isArray(parsed.presetPersist)
                    ? parsed.presetPersist
                    : {},
                migrations: parsed.migrations
                    && typeof parsed.migrations === "object"
                    && !Array.isArray(parsed.migrations)
                    ? parsed.migrations
                    : {}
            };
        } catch (error) {
            console.warn("[PluginState] Ignoring invalid state file: " + error);
            root.state = root.emptyState();
        }
        root.ready = true;
    }

    Timer {
        id: reloadTimer
        interval: 100
        onTriggered: stateFile.reload()
    }

    Timer {
        id: writeTimer
        interval: 100
        onTriggered: stateFile.setText(JSON.stringify(root.state, null, 2))
    }

    FileView {
        id: stateFile
        path: root.filePath
        watchChanges: true
        onFileChanged: reloadTimer.restart()
        onLoaded: root.loadText(stateFile.text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.state = root.emptyState();
                root.ready = true;
                writeTimer.restart();
            } else {
                console.warn("[PluginState] Failed to load state file: " + error);
            }
        }
    }


    IpcHandler {
        target: "pluginState"

        function snapshot(): string {
            return root.snapshot();
        }

        function replace(serialized: string): void {
            root.replaceSnapshot(serialized);
        }
    }
}
