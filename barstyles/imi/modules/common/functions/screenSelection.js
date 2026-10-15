.pragma library


function toggle(screenList, allNames, name, checked) {
    const selected = (screenList.length === 0) ? allNames.slice() : screenList.slice();
    let next;
    if (checked) {
        next = selected.includes(name) ? selected.slice() : selected.concat([name]);
    } else {
        next = selected.filter(entry => entry !== name);
    }
    if (next.length === 0)
        return { list: screenList, accepted: false };
    return { list: next.length === allNames.length ? [] : next, accepted: true };
}

function includes(screenList, name) {
    return screenList.length === 0 || screenList.includes(name);
}
