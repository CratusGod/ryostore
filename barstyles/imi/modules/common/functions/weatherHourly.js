.pragma library
.import "weatherForecast.js" as Daily


var SLOT_COUNT = 5;

var MIN_SLOTS = 2;

var MIN_FRACTION = 0.18;

var FLAT_FRACTION = 0.55;

function _pad2(value) {
    return value < 10 ? "0" + value : String(value);
}

function _reading(value) {
    if (value === null || value === undefined || value === "")
        return null;
    var number = Number(value);
    return isFinite(number) ? number : null;
}

function slotsFromOwm(list) {
    var slots = [];
    (list || []).forEach(function (entry) {
        var seconds = Number(entry && entry.dt);
        if (!isFinite(seconds) || seconds <= 0)
            return;
        var when = new Date(seconds * 1000);
        slots.push({
            ms: when.getTime(),
            date: Daily.localIsoDate(when),
            hour: when.getHours(),
            temp: _reading(entry && entry.main && entry.main.temp),
            wCode: Number(entry && entry.weather && entry.weather[0] && entry.weather[0].id) || 0
        });
    });
    return _sorted(slots);
}

function slotsFromWttr(weather, useUSCS) {
    var slots = [];
    (weather || []).forEach(function (day) {
        var date = (day && day.date) || "";
        var parts = date.split("-");
        var year = Number(parts[0]);
        var month = Number(parts[1]);
        var dayOfMonth = Number(parts[2]);
        if (!isFinite(year) || !isFinite(month) || !isFinite(dayOfMonth))
            return;
        ((day && day.hourly) || []).forEach(function (entry) {
            var raw = Number((entry && entry.time) || 0);
            if (!isFinite(raw))
                return;
            var hour = Math.floor(raw / 100);
            slots.push({
                ms: new Date(year, month - 1, dayOfMonth, hour).getTime(),
                date: date,
                hour: hour,
                temp: _reading(useUSCS ? (entry && entry.tempF) : (entry && entry.tempC)),
                wCode: Number(entry && entry.weatherCode) || 0
            });
        });
    });
    return _sorted(slots);
}

function upcoming(slots, nowMs, limit) {
    var wanted = (limit === undefined || limit === null) ? SLOT_COUNT : limit;
    var ahead = [];
    (slots || []).forEach(function (slot) {
        if (slot && isFinite(slot.ms) && slot.ms > nowMs)
            ahead.push(slot);
    });
    return ahead.slice(0, Math.max(0, wanted)).map(function (slot, index, shown) {
        return {
            ms: slot.ms,
            date: slot.date,
            hour: slot.hour,
            temp: slot.temp,
            wCode: slot.wCode,
            dayBreak: index > 0 && !!slot.date && slot.date !== shown[index - 1].date
        };
    });
}

function chartRange(slots) {
    var low = null;
    var high = null;
    (slots || []).forEach(function (slot) {
        var temp = _reading(slot && slot.temp);
        if (temp === null)
            return;
        low = (low === null) ? temp : Math.min(low, temp);
        high = (high === null) ? temp : Math.max(high, temp);
    });
    return { low: low, high: high };
}

function barFraction(temp, low, high) {
    var value = _reading(temp);
    var bottom = _reading(low);
    var top = _reading(high);
    if (value === null || bottom === null || top === null)
        return null;
    if (top === bottom)
        return FLAT_FRACTION;
    var scaled = MIN_FRACTION + (1 - MIN_FRACTION) * (value - bottom) / (top - bottom);
    return Math.max(MIN_FRACTION, Math.min(1, scaled));
}

function isRenderable(slots) {
    var withReadings = 0;
    (slots || []).forEach(function (slot) {
        if (_reading(slot && slot.temp) !== null)
            withReadings++;
    });
    return withReadings >= MIN_SLOTS;
}

function usesTwelveHourClock(timeFormat) {
    return /(^|[^a-zA-Z])(ap|AP)([^a-zA-Z]|$)/.test(String(timeFormat || ""));
}

function hourLabel(hour, twelveHour) {
    var value = Number(hour);
    if (!isFinite(value))
        return "";
    var normalized = ((Math.floor(value) % 24) + 24) % 24;
    if (!twelveHour)
        return _pad2(normalized) + ":00";
    var display = normalized % 12;
    return (display === 0 ? 12 : display) + (normalized < 12 ? " AM" : " PM");
}

function _sorted(slots) {
    return slots.sort(function (left, right) {
        return left.ms - right.ms;
    });
}
