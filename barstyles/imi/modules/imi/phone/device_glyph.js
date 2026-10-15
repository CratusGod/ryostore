.pragma library

function forType(type) {
    switch (type ?? "") {
    case "phone": return "smartphone";
    case "tablet": return "tablet";
    case "laptop": return "laptop";
    case "desktop": return "computer";
    case "tv": return "tv";
    case "": return "mobile_off";
    default: return "devices";
    }
}
