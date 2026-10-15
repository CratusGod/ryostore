.pragma library

function resolve(avatarFolder, avatarPicture, home, faceExists, faceIconExists) {
    if (avatarFolder !== "" && avatarPicture !== "")
        return "file://" + avatarPicture;
    if (faceExists)
        return "file://" + home + "/.face";
    if (faceIconExists)
        return "file://" + home + "/.face.icon";
    return "";
}
