.pragma library

// What the radial menu offers for a set of dragged files: DragShift's
// app.build_rings, ported so the rings appear the instant a drag enters (no
// Python start-up in the way). tests/test_menu.py checks every entry against
// the engine, so the two can never drift apart.

const IMAGE_EXTS = ["png", "jpg", "jpeg", "webp", "heic", "heif", "tif", "tiff", "avif", "bmp", "gif", "ico"];
const TEXT_EXTS = ["txt", "md", "csv", "log", "json", "xml", "html", "htm"];

const IMAGE_TARGETS = ["PNG", "JPG", "WEBP", "HEIC", "TIFF", "AVIF", "BMP", "PDF", "ICO", "GIF"];
const PDF_TARGETS = ["JPG", "PNG", "DOCX", "TXT"];
const DOCX_TARGETS = ["PDF", "TXT"];
const TEXT_TARGETS = ["PDF", "DOCX"];

const FORMAT_HINTS = {
    JPG: "Small, universal", PNG: "Lossless · transparency", WEBP: "Smallest for web",
    HEIC: "iPhone format", TIFF: "Print · archival", AVIF: "Next-gen, tiny",
    BMP: "Uncompressed", PDF: "Document", ICO: "Windows icon", GIF: "Legacy web",
    DOCX: "Editable Word", TXT: "Plain text"
};

const GLYPHS = {
    Compress: "⇲", Metadata: "ⓘ", Redact: "▮", Crop: "⌗", Edit: "☼", Annotate: "✎",
    "Add BG": "▣", Resize: "⤢", Split: "✂", Rotate: "⟳", Merge: "⧉", Protect: "⚿", Extract: "⧈"
};

const HINTS = {
    Compress: "Shrink file size", Metadata: "View · remove GPS", Redact: "Hide private info",
    Crop: "Trim to a ratio", Edit: "Light · colour · rotate", Annotate: "Arrows · text · steps",
    "Add BG": "Gradient backdrop", Resize: "Change dimensions", Split: "One PDF per page",
    Rotate: "Turn pages 90°", Merge: "Join into one PDF", Protect: "Add a password",
    Extract: "Save embedded images"
};

// label -> [kind, engine id]. "editor" opens DragShift's own window, "tool" runs at once.
const IMAGE_TOOLS = [
    ["Compress", "editor", "compress-custom"], ["Resize", "editor", "resize-custom"],
    ["Crop", "editor", "crop"], ["Edit", "editor", "edit"], ["Annotate", "editor", "annotate"],
    ["Redact", "editor", "redact"], ["Add BG", "editor", "add-bg"], ["Metadata", "editor", "metadata"]
];
const PDF_TOOLS = [
    ["Compress", "tool", "compress"], ["Split", "tool", "split"], ["Rotate", "tool", "rotate"],
    ["Protect", "editor", "protect"], ["Extract", "tool", "extract"], ["Metadata", "editor", "metadata"]
];

function ext(p) {
    const s = String(p);
    const name = s.slice(s.lastIndexOf("/") + 1);
    const dot = name.lastIndexOf(".");
    return dot > 0 ? name.slice(dot + 1).toLowerCase() : "";
}

function category(p) {
    const e = ext(p);
    if (IMAGE_EXTS.indexOf(e) !== -1) return "image";
    if (e === "pdf") return "pdf";
    if (e === "docx") return "docx";
    if (TEXT_EXTS.indexOf(e) !== -1) return "text";
    return "";
}

// convert.targets_for: every target except the format the file already is
function targetsFor(cat, srcExt, heif) {
    const same = { jpeg: "JPG", jpg: "JPG", tif: "TIFF", tiff: "TIFF", heif: "HEIC" };
    const cur = same[srcExt] || String(srcExt).toUpperCase();
    if (cat === "image")
        return IMAGE_TARGETS.filter(t => t !== cur && (heif || t !== "HEIC"));
    return ({ pdf: PDF_TARGETS, docx: DOCX_TARGETS, text: TEXT_TARGETS })[cat] || [];
}

// -> { category, files, rings: [{ name, items: [{label, glyph, hint, kind, id}] }] }
// The first supported file decides the kind; the rest of that kind come along.
function build(paths, heif) {
    const all = (paths || []).map(String);
    const first = all.find(p => category(p) !== "");
    if (!first)
        return { category: "", files: [], rings: [] };
    const cat = category(first);
    const files = all.filter(p => category(p) === cat);
    const conv = targetsFor(cat, ext(first), heif !== false).map(t => ({
        label: t, glyph: "", kind: "convert", id: t,
        hint: (cat === "image" && t === "PDF" && files.length > 1) ? files.length + " images → 1 PDF" : FORMAT_HINTS[t] || ""
    }));
    const rings = [{ name: "Convert", items: conv }];
    let tools = cat === "image" ? IMAGE_TOOLS.slice() : cat === "pdf" ? PDF_TOOLS.slice() : [];
    if (cat === "pdf" && files.length > 1)
        tools.splice(3, 0, ["Merge", "tool", "merge"]);
    if (tools.length > 0)
        rings.push({ name: "Tools", items: tools.map(t => ({ label: t[0], glyph: GLYPHS[t[0]], hint: HINTS[t[0]], kind: t[1], id: t[2] })) });
    return { category: cat, files: files, rings: rings };
}

// app.describe: "2.4 MB" for one file, "3 files" for several
function humanSize(n) {
    const units = ["B", "KB", "MB", "GB"];
    let v = Number(n) || 0;
    let i = 0;
    while (v >= 1024 && i < units.length - 1) { v /= 1024; i++; }
    return (i === 0 ? v.toFixed(0) : v.toFixed(1)) + " " + units[i];
}
