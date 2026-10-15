.pragma library


function iconFits(availableHeight, iconHeight, textHeights, spacing) {
    if (!(availableHeight > 0))
        return true;
    const text = (textHeights || []).reduce(
        (total, height) => total + height + spacing, 0);
    return availableHeight >= iconHeight + text;
}
