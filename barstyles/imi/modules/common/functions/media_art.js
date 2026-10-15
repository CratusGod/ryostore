.pragma library

function youtubeId(url) {
    const m = String(url || "").match(/(?:[?&]v=|youtu\.be\/|\/shorts\/|\/embed\/)([A-Za-z0-9_-]{11})/);
    return m ? m[1] : "";
}

function resolve(artUrl, metadata) {
    if (artUrl && String(artUrl).length > 0)
        return artUrl;
    const url = metadata ? (metadata["xesam:url"] || "") : "";
    const id = youtubeId(url);
    return id ? ("https://i.ytimg.com/vi/" + id + "/hqdefault.jpg") : "";
}
