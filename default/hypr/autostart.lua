require("default.hypr.startup-cursor")

hl.on("hyprland.start", function()
  -- sddm only deactivated Plymouth, which kept its frame on screen until
  -- Hyprland committed a buffer of its own to every output it enabled at
  -- startup. This event comes as Hyprland starts rendering, after those
  -- commits, so Plymouth can quit. See etc/systemd/system/sddm.service.d/.
  hl.exec_cmd("sudo -n /usr/bin/systemctl start --no-block omarchy-plymouth-quit.service")

  -- Applications inherit the user's cursor; only the compositor starts blank.
  if omarchy_startup_cursor_pending then
    hl.env("XCURSOR_PATH", omarchy_startup_cursor.path)
    hl.env("XCURSOR_THEME", omarchy_startup_cursor.xcursor)
  end

  -- Slow app launch fix -- set systemd and D-Bus activation vars before
  -- starting session services.
  hl.exec_cmd("dbus-update-activation-environment --systemd --all")

  hl.exec_cmd("omarchy-launch-shell")
  hl.exec_cmd("omarchy-provision-first-run")
  hl.exec_cmd("omarchy-powerprofiles-init")
  hl.exec_cmd(o.launch("omarchy-hyprland-monitor-watch"))
  hl.exec_cmd(o.launch("udiskie --automount --no-notify --no-tray"))

  -- Start the herdr server inside the graphical session so its panes inherit
  -- WAYLAND_DISPLAY. Otherwise the first SSH login from a remote herdr starts
  -- it with a tty environment, and agents in its panes can't read the clipboard.
  hl.exec_cmd(o.launch("herdr server"))

  -- Run post-boot hooks after startup config has loaded.
  hl.exec_cmd("sleep 2 && omarchy-hook post-boot")
end)
