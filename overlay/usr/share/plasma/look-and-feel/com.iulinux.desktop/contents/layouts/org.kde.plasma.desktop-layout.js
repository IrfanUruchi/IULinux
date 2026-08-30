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

// IULinux Premium Workstation Layout
// Plasma 6

// The IULinux global theme owns the initial panel layout.
for (const oldPanel of panels()) {
    oldPanel.remove();
}

const panel = new Panel;

panel.location = "bottom";
panel.height = 44;
panel.alignment = "center";
panel.hiding = "none";
panel.lengthMode = "custom";

const geometry = screenGeometry(0);
panel.length = Math.min(
    Math.round(geometry.width * 0.92),
    1600
);

panel.minimumLength = Math.min(640, geometry.width);
panel.maximumLength = Math.min(1600, geometry.width);

// Plasma stores floating-view behavior in plasmashellrc.
const plasmaViews = new ConfigFile(
    "plasmashellrc",
    "PlasmaViews"
);

const panelView = new ConfigFile(
    plasmaViews,
    "Panel " + panel.id
);

panelView.writeEntry("floating", "1");

const panelDefaults = new ConfigFile(
    panelView,
    "Defaults"
);

panelDefaults.writeEntry("thickness", "44");


// ---------------------------------------------------------
// IU launcher
// ---------------------------------------------------------

const launcher = panel.addWidget(
    "org.kde.plasma.kickoff"
);

launcher.writeConfig(
    "icon",
    "iulinux"
);

launcher.globalShortcut = "Alt+F1";


// ---------------------------------------------------------
// Application / task area
// ---------------------------------------------------------

const tasks = panel.addWidget(
    "org.kde.plasma.icontasks"
);

tasks.writeConfig(
    "launchers",
    [
        "applications:brave-browser.desktop",
        "applications:org.kde.dolphin.desktop",
        "applications:org.kde.konsole.desktop",
        "applications:systemsettings.desktop"
    ]
);


// ---------------------------------------------------------
// Flexible visual separation
// ---------------------------------------------------------

panel.addWidget(
    "org.kde.plasma.panelspacer"
);


// ---------------------------------------------------------
// System status
// ---------------------------------------------------------

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
    "true"
);

clock.writeConfig(
    "showSeconds",
    "false"
);
