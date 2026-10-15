pragma Singleton
import Quickshell

Singleton {
    id: root

    function getFirstDayOfWeek(date, firstDay = 1) {
        const d = new Date(date);
        const day = d.getDay();

        const diff = (day - firstDay + 7) % 7;
        d.setDate(d.getDate() - diff);
        return d;
    }

    function sameDate(d1, d2) {
        return (d1.getFullYear() === d2.getFullYear() && d1.getMonth() === d2.getMonth() && d1.getDate() === d2.getDate());
    }

    function getIthDayDateOfSameWeek(date, i, firstDay = 1) {
        const firstDayDate = root.getFirstDayOfWeek(date, firstDay);
        const targetDate = new Date(firstDayDate);
        targetDate.setDate(firstDayDate.getDate() + i);
        return targetDate;
    }
}
