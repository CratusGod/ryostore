.pragma library


var MAIN_DEFAULT = ["fingerprint", "password", "confirm"];
var LEFT_DEFAULT = ["username", "media", "keyboardLayout", "fcitx"];
var RIGHT_DEFAULT = ["battery", "sleep", "power", "reboot"];

function reorderable(island, id) {
    return !(island === "main" && id === "password");
}

function orderedItems(stored, defaults) {
    var order = [];
    var count = stored && typeof stored.length === "number" ? stored.length : 0;
    for (var i = 0; i < count; i++) {
        var id = stored[i];
        if (defaults.indexOf(id) !== -1 && order.indexOf(id) === -1)
            order.push(id);
    }
    for (var d = 0; d < defaults.length; d++) {
        if (order.indexOf(defaults[d]) !== -1)
            continue;
        var at = 0;
        for (var p = d - 1; p >= 0; p--) {
            var prev = order.indexOf(defaults[p]);
            if (prev !== -1) {
                at = prev + 1;
                break;
            }
        }
        order.splice(at, 0, defaults[d]);
    }
    return order;
}

function storedOrder(moved, stored, defaults) {
    var result = moved.slice();
    var count = stored && typeof stored.length === "number" ? stored.length : 0;
    for (var i = 0; i < count; i++) {
        if (defaults.indexOf(stored[i]) === -1 && result.indexOf(stored[i]) === -1)
            result.push(stored[i]);
    }
    return result;
}
