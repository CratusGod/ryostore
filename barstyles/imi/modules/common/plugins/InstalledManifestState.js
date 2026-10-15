.pragma library

function reconcile(paths, current) {
    const kept = {};
    for (const path of paths) {
        if (current[path] !== undefined)
            kept[path] = current[path];
    }
    return kept;
}
