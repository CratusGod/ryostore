.pragma library


function heroSectionHeight(sections, padding) {
    if (!sections)
        return 0;
    for (let index = 0; index < sections.length; index++) {
        const section = sections[index];
        if (!section || section.visible !== true)
            continue;
        const height = section.height;
        if (!(height > 0))
            continue;
        return height + padding * 2;
    }
    return 0;
}

function restHeight(openHeight, heroHeight, parkedSize, exiting) {
    if (!(openHeight > 0))
        return 0;
    const rest = (exiting || !(heroHeight > 0)) ? parkedSize : heroHeight;
    return Math.max(0, Math.min(rest, openHeight));
}

function cardHeight(openHeight, heroHeight, parkedSize, exiting, progress) {
    if (!(openHeight > 0))
        return 0;
    const rest = restHeight(openHeight, heroHeight, parkedSize, exiting);
    const travelled = progress > 0 ? progress : 0;
    return rest + (openHeight - rest) * travelled;
}
