// Tatami's pure libraries: the launcher.json checks and the shelf's ordering.
// Run with: node --test tests/tatami-launcher.test.mjs
import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";
import vm from "node:vm";

const lib = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "launchers", "tatami", "lib");

// The libraries are `.pragma library` QML scripts: drop the pragma, run as plain JS
// in a fresh context and read the functions back.
function load(file, names) {
  const src = readFileSync(path.join(lib, file), "utf8").replace(/^\.pragma library\s*$/m, "");
  const sandbox = {};
  vm.runInNewContext(`${src}\nthis.exports = { ${names.join(", ")} };`, sandbox, { filename: file });
  // results cross a realm boundary; copy them so they compare as plain values
  const copy = value => (value === undefined ? value : JSON.parse(JSON.stringify(value)));
  return Object.fromEntries(
    names.map(name => [name, (...args) => copy(sandbox.exports[name](...args))]),
  );
}

const { clean } = load("config.js", ["clean"]);
const { collect, filter, sections } = load("shelf.js", ["collect", "filter", "sections"]);

const DEFAULTS = {
  hiddenApps: [], pinnedApps: [], sectionOrder: [], hiddenSections: [],
  overlayOpacity: 0.94, bgBlur: 0, columns: 8, matWidth: 144,
};

test("a missing or empty config is the defaults", () => {
  assert.deepEqual(clean(undefined), DEFAULTS);
  assert.deepEqual(clean(null), DEFAULTS);
  assert.deepEqual(clean({}), DEFAULTS);
});

test("values Settings can save pass through unchanged", () => {
  const saved = {
    hiddenApps: ["mpv", "yazi"], pinnedApps: ["zen"], sectionOrder: ["media", "internet"],
    hiddenSections: ["games"], overlayOpacity: 0.3, bgBlur: 25, columns: 9, matWidth: 202,
  };
  assert.deepEqual(clean(saved), saved);
});

test("a list that is not a list becomes an empty one", () => {
  for (const bad of ["mpv", 7, true, { length: "2" }, {}, null]) {
    const out = clean({ hiddenApps: bad, pinnedApps: bad, sectionOrder: bad, hiddenSections: bad });
    assert.deepEqual(out.hiddenApps, [], String(bad));
    assert.deepEqual(out.pinnedApps, []);
    assert.deepEqual(out.sectionOrder, []);
    assert.deepEqual(out.hiddenSections, []);
  }
});

test("list entries that are not ids are dropped", () => {
  const out = clean({ hiddenApps: ["mpv", 3, null, "", "  ", { id: "x" }, ["y"], " yazi ", "mpv"] });
  assert.deepEqual(out.hiddenApps, ["mpv", "yazi"]);
});

test("a QML-style list (array-like, not an Array) is read", () => {
  const qml = { length: 2, 0: "zen", 1: "mpv" };
  assert.deepEqual(clean({ pinnedApps: qml }).pinnedApps, ["zen", "mpv"]);
});

test("an array-like length cannot make config loading scan without bound", () => {
  const values = { length: 2501, 0: "zen", 2500: "must-not-be-read" };
  assert.deepEqual(clean({ pinnedApps: values }).pinnedApps, ["zen"]);
});

test("numbers that are not numbers fall back to the default", () => {
  for (const bad of ["8", NaN, Infinity, -Infinity, null, undefined, {}, [], true]) {
    const out = clean({ overlayOpacity: bad, bgBlur: bad, columns: bad, matWidth: bad });
    assert.equal(out.overlayOpacity, 0.94, String(bad));
    assert.equal(out.bgBlur, 0);
    assert.equal(out.columns, 8);
    assert.equal(out.matWidth, 144);
  }
});

test("numbers outside Settings' range are clamped, and whole ones rounded", () => {
  assert.equal(clean({ overlayOpacity: 0 }).overlayOpacity, 0.3);
  assert.equal(clean({ overlayOpacity: 5 }).overlayOpacity, 1);
  assert.equal(clean({ bgBlur: -4 }).bgBlur, 0);
  assert.equal(clean({ bgBlur: 999 }).bgBlur, 30);
  assert.equal(clean({ bgBlur: 12.6 }).bgBlur, 13);
  assert.equal(clean({ columns: 0 }).columns, 3);
  assert.equal(clean({ columns: 1e9 }).columns, 16);
  assert.equal(clean({ matWidth: 10 }).matWidth, 90);
  assert.equal(clean({ matWidth: 5000 }).matWidth, 240);
});

test("odd config never throws on the way into the shelf", () => {
  const cfg = clean({ pinnedApps: "zen", sectionOrder: 4, hiddenSections: { a: 1 } });
  const shelf = collect([{ id: "a", name: "Alpha", categories: ["Utility"] }], cfg.pinnedApps);
  assert.deepEqual(sections(shelf, cfg.sectionOrder, cfg.hiddenSections).map(s => s.id), ["all", "utility"]);
});

function entry(id, name, extra) {
  return Object.assign({ id, name, categories: ["Utility"] }, extra);
}

test("favorites lead their section", () => {
  const shelf = collect([entry("a", "Alpha"), entry("b", "Bravo"), entry("c", "Charlie")], ["c"]);
  assert.deepEqual(filter(shelf, "all", "").map(i => i.entry.id), ["c", "a", "b"]);
  assert.deepEqual(filter(shelf, "utility", "").map(i => i.entry.id), ["c", "a", "b"]);
});

test("favorites lead a search, best match first within each group", () => {
  const shelf = collect([
    entry("wf", "Wire Fire"),              // a later word starts with it: rank 1
    entry("fm", "Files"),                  // the name starts with it: rank 0
    entry("xf", "Xfig Notes"),             // the query is inside the name: rank 2, a favorite
    entry("ff", "Firefox"),                // rank 0, a favorite
    entry("ot", "Other", { comment: "like fi" }),   // only in the comment: rank 3
  ], ["xf", "ff"]);
  const ids = filter(shelf, "all", "fi").map(i => i.entry.id);
  assert.deepEqual(ids, ["ff", "xf", "fm", "wf", "ot"]);
});

test("a favorite that does not match the query stays out", () => {
  const shelf = collect([entry("a", "Alpha"), entry("z", "Zebra")], ["z"]);
  assert.deepEqual(filter(shelf, "all", "alp").map(i => i.entry.id), ["a"]);
});
