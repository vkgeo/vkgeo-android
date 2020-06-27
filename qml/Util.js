function dp(dpi, size) {
    if (dpi >= 640) {
        return Math.floor(size * 4);
    } else if (dpi >= 480) {
        return Math.floor(size * 3);
    } else if (dpi >= 320) {
        return Math.floor(size * 2);
    } else if (dpi >= 240) {
        return Math.floor(size * 1.5);
    } else {
        return Math.floor(size);
    }
}

function formatSharedKey(key) {
    var result = "";

    for (var i = 0; i < key.length; i++) {
        if (i > 0 && i % 4 === 0) {
            result = result + " ";
        }

        result = result + key[i];
    }

    return result;
}

function concatSharedKey(formatted_key) {
    return formatted_key.trim().split(/\s+/).join("");
}
