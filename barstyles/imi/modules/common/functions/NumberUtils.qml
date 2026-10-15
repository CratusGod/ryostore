pragma Singleton
import Quickshell

Singleton {
    id: root

    function roundToEven(num) {
        return Math.round(num / 2) * 2;
    }
}
