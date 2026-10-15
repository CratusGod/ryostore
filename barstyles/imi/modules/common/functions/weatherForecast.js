.pragma library


const MAX_DAYS = 4;

const ICON_HOUR = 12;

function localIsoDate(date) {
    const pad = (value) => (value < 10 ? "0" + value : String(value));
    return date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-" + pad(date.getDate());
}

function isToday(isoDate, todayIsoDate) {
    return !!isoDate && isoDate === todayIsoDate;
}

function shortDayName(isoDate, locale) {
    if (!isoDate)
        return "";
    const parsed = new Date(isoDate + "T12:00:00");
    if (isNaN(parsed.getTime()))
        return "";
    return parsed.toLocaleDateString(locale, "ddd");
}

function dailyFromOwm(list) {
    const byDate = {};
    (list || []).forEach(entry => {
        const stamp = entry && entry.dt_txt;
        if (typeof stamp !== "string" || stamp.length < 13)
            return;
        const date = stamp.slice(0, 10);
        if (!byDate[date])
            byDate[date] = { date: date, wCode: 0, high: null, low: null, iconDistance: Infinity };
        const day = byDate[date];

        const high = Number(entry && entry.main && entry.main.temp_max);
        const low = Number(entry && entry.main && entry.main.temp_min);
        if (isFinite(high))
            day.high = (day.high === null) ? high : Math.max(day.high, high);
        if (isFinite(low))
            day.low = (day.low === null) ? low : Math.min(day.low, low);

        const distance = Math.abs(Number(stamp.slice(11, 13)) - ICON_HOUR);
        if (isFinite(distance) && distance < day.iconDistance) {
            day.iconDistance = distance;
            day.wCode = Number(entry && entry.weather && entry.weather[0] && entry.weather[0].id) || 0;
        }
    });
    return Object.keys(byDate).sort().slice(0, MAX_DAYS).map(date => _round(byDate[date]));
}

function dailyFromWttr(weather, useUSCS) {
    return (weather || []).slice(0, MAX_DAYS).map(day => {
        const entry = { date: (day && day.date) || "", wCode: 0, high: null, low: null };
        let iconDistance = Infinity;
        ((day && day.hourly) || []).forEach(hour => {
            const distance = Math.abs(Math.floor(Number((hour && hour.time) || 0) / 100) - ICON_HOUR);
            if (isFinite(distance) && distance < iconDistance) {
                iconDistance = distance;
                entry.wCode = Number(hour && hour.weatherCode) || 0;
            }
        });
        const high = Number(useUSCS ? (day && day.maxtempF) : (day && day.maxtempC));
        const low = Number(useUSCS ? (day && day.mintempF) : (day && day.mintempC));
        entry.high = isFinite(high) ? high : null;
        entry.low = isFinite(low) ? low : null;
        return _round(entry);
    });
}

function _round(day) {
    return {
        date: day.date,
        wCode: day.wCode,
        high: day.high === null ? null : Math.round(day.high),
        low: day.low === null ? null : Math.round(day.low)
    };
}
