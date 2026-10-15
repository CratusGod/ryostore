.pragma library


var REST = "rest";
var HOVERED = "hovered";
var PRESSED = "pressed";
var DISABLED = "disabled";

function stateOf(flags) {
    if (flags && flags.enabled === false) return DISABLED;
    if (flags && flags.down) return PRESSED;
    if (flags && flags.hovered) return HOVERED;
    return REST;
}

function targetsFor(state, tokens) {
    switch (state) {
    case PRESSED:
        return { scale: tokens.pressScale, radiusScale: tokens.pressRadiusScale,
                 hover: 1, press: 1, opacity: 1 };
    case HOVERED:
        return { scale: tokens.hoverScale, radiusScale: 1,
                 hover: 1, press: 0, opacity: 1 };
    case DISABLED:
        return { scale: 1, radiusScale: 1, hover: 0, press: 0,
                 opacity: tokens.disabledOpacity };
    default:
        return { scale: 1, radiusScale: 1, hover: 0, press: 0, opacity: 1 };
    }
}

function transitionFor(fromState, toState, tiers) {
    if (fromState === toState) return tiers.hold;
    if (fromState === DISABLED || toState === DISABLED) return tiers.instant;
    if (toState === PRESSED) return tiers.press;
    if (fromState === PRESSED) return tiers.release;
    if (toState === HOVERED) return tiers.hoverIn;
    return tiers.hoverOut;
}

function isMotionless(transition) {
    return transition.duration === 0;
}
