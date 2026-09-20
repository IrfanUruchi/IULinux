// IULinux branded desktop wallpaper
for (const desktop of desktops()) {
    desktop.wallpaperPlugin = "org.kde.image";
    desktop.currentConfigGroup = [
        "Wallpaper",
        "org.kde.image",
        "General"
    ];

    desktop.writeConfig(
        "Image",
        "file:///usr/share/wallpapers/IULinux/contents/images/3840x2160.png"
    );
}

// IULinux workstation dock
//
// One physical Plasma panel.
//
// Performance, applications and system status remain separate
// logical sections, but share one baseline and one visibility state.

for (const oldPanel of panels()) {
    oldPanel.remove();
}

const screenWidth = screenGeometry(0).width;

const panelHeight =
    screenWidth >= 1800 ? 48 :
    screenWidth >= 1200 ? 44 :
                          40;

const panelThickness = Math.max(
    36,
    panelHeight - 4
);

const plasmaViews = new ConfigFile(
    "plasmashellrc",
    "PlasmaViews"
);

const panel = new Panel;

panel.location = "bottom";
panel.height = panelHeight;
panel.alignment = "center";
panel.lengthMode = "fit";
panel.hiding = "autohide";

const panelView = new ConfigFile(
    plasmaViews,
    "Panel " + panel.id
);

panelView.writeEntry(
    "floating",
    "1"
);

const panelDefaults = new ConfigFile(
    panelView,
    "Defaults"
);

panelDefaults.writeEntry(
    "thickness",
    panelThickness
);

function addGap() {
    const gap = panel.addWidget(
        "org.kde.plasma.panelspacer"
    );

    gap.currentConfigGroup = [
        "General"
    ];

    gap.writeConfig(
        "expanding",
        false
    );

    gap.writeConfig(
        "length",
        40
    );

    return gap;
}


// Performance
panel.addWidget(
    "com.iulinux.performance"
);

addGap();


// Applications
const launcher = panel.addWidget(
    "org.kde.plasma.kickoff"
);

launcher.writeConfig(
    "icon",
    "iulinux"
);

launcher.globalShortcut = "Alt+F1";

const tasks = panel.addWidget(
    "org.kde.plasma.icontasks"
);

tasks.currentConfigGroup = ["General"];

tasks.writeConfig(
    "launchers",
    [
        "applications:brave-browser.desktop",
        "applications:org.kde.dolphin.desktop",
        "applications:org.gnome.Ptyxis.desktop",
        "applications:com.iulinux.Settings.desktop"
    ]
);

addGap();


// System status
panel.addWidget(
    "org.kde.plasma.systemtray"
);

const clock = panel.addWidget(
    "org.kde.plasma.digitalclock"
);

clock.currentConfigGroup = [
    "Appearance"
];

clock.writeConfig(
    "showDate",
    false
);

clock.writeConfig(
    "showSeconds",
    0
);

clock.writeConfig(
    "autoFontAndSize",
    false
);

clock.writeConfig(
    "fontSize",
    9
);


// IULinux panel appearance controller.
// QML applet only; optional upstream C++ plugin is not shipped.
const colorizer = panel.addWidget(
    "luisbocanegra.panel.colorizer"
);

colorizer.currentConfigGroup = ["General"];

colorizer.writeConfig(
    "isEnabled",
    true
);

colorizer.writeConfig(
    "hideWidget",
    true
);

colorizer.writeConfig(
    "islandsEnabled",
    true
);

colorizer.writeConfig(
    "islandSeparatorWidget",
    "org.kde.plasma.panelspacer"
);

colorizer.writeConfig(
    "islandSeparatorPairing",
    false
);

colorizer.writeConfig(
    "blacklistIslandSeparator",
    true
);

colorizer.writeConfig(
    "presetAutoloading",
    JSON.stringify({
        enabled: true,
        normal: "/usr/share/plasma/plasmoids/luisbocanegra.panel.colorizer/contents/ui/presets/IULinux Dock"
    })
);
