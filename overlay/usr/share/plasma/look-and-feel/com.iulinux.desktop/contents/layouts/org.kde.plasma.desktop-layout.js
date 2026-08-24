loadTemplate("org.kde.plasma.desktop.defaultPanel")

var desktopsArray = desktopsForActivity(currentActivity());
for( var j = 0; j < desktopsArray.length; j++) {
    desktopsArray[j].wallpaperPlugin = 'org.kde.image';
}


// ------------------------------------------------------------
// IULinux default desktop wallpaper
// ------------------------------------------------------------

var iulinuxDesktops = desktops();

for (var i = 0; i < iulinuxDesktops.length; ++i) {
    var desktop = iulinuxDesktops[i];

    desktop.wallpaperPlugin = "org.kde.image";

    desktop.currentConfigGroup = [
        "Wallpaper",
        "org.kde.image",
        "General"
    ];

    desktop.writeConfig(
        "Image",
        "file:///usr/share/wallpapers/IULinux/contents/images/1672x941.png"
    );
}
