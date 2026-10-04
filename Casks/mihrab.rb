cask "mihrab" do
  version "2.28.1"
  sha256 "8eebd5732c5be89c25ea87273049f7188b24624d4aac95c27af35fb1c43cb71d"

  url "https://github.com/MihrabHQ/Mihrab/releases/download/v#{version}/Mihrab-macOS-#{version}.zip"
  name "Mihrab"
  desc "Prayer times, Quran, and daily worship tools - private by design"
  homepage "https://github.com/MihrabHQ/Mihrab"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :monterey

  app "Mihrab.app"

  # Two things at the one moment code runs while the app is being replaced:
  # re-register the widget extension, then restart the widget daemon. They
  # fix two different failures and neither one covers the other.
  #
  # ── 1. RE-REGISTER THE EXTENSION, or the widgets are REMOVED ─────────
  #
  # Replacing the app deletes the bundle the widget extension lived in, and
  # PlugInKit's record goes with it — records are keyed by bundle
  # identifier, so the copy staged a moment later is not what comes back,
  # and nothing re-registers it. Measured on 2026-08-29 straight after a
  # `brew upgrade` to 2.13.3:
  #
  #   pluginkit -mAvvv | grep -i prayerwidget          → nothing
  #   lsregister -dump | grep -c PrayerWidgetExtension → 0
  #
  # `lsregister -f /Applications/Mihrab.app` does NOT bring it back — tried,
  # and the extension stayed unregistered. Neither does clearing the
  # quarantine flag. Only launching the app does, because launching is what
  # registers an app's own extensions.
  #
  # WidgetKit with no registered provider does not draw a stale card, it
  # drops the widget: every placed Mihrab widget is REMOVED from
  # Notification Center and Mihrab leaves the gallery too. So every macOS
  # upgrade cost the user their widgets until they happened to open the app
  # — which is not a thing an app that runs in the background gets opened
  # for. `pluginkit -a` performs the same registration without a launch,
  # and was verified to work on the quarantined copy Homebrew installs
  # (Homebrew quarantines casks by default, so that mattered).
  #
  # ── 2. RESTART THE WIDGET DAEMON, or the widgets FREEZE ──────────────
  #
  # WidgetKit archives each widget's timeline AND its gallery preview to
  # disk, and chronod validates those archives against the bundle they were
  # produced by. Replacing the app in place invalidates that check: every
  # reload then fails with
  #
  #   bundleStubNotSupported("Bundle version did not match;
  #                           LaunchServices DB may need to be rebuilt")
  #
  # and it does not recover — retries were observed being pushed out an
  # hour, then a full day, while every card kept drawing the last archive
  # that validated. Measured on 2026-08-28: widgets and previews frozen at
  # the moment of the previous upgrade, still frozen a day later.
  #
  # `lsregister -f -R` was tried and does NOT clear it, despite what the
  # message suggests. Restarting chronod does, immediately. It is a per-user
  # launchd agent, comes straight back, and the only visible effect is the
  # widgets redrawing — which is the point.
  #
  # ── WHY THE REGISTRATION IS A LOOP AND NOT ONE COMMAND ───────────────
  #
  # A single `pluginkit -a` here does not survive. Timed on 2026-08-29,
  # polling once a second across a `brew reinstall`:
  #
  #   13:09:07  registered=1   ← the postflight's pluginkit -a
  #   13:09:08  registered=0   ← gone, one second later
  #   13:10:23  registered=0   ← and still gone 75s on
  #
  # The uninstall step deletes the old bundle and macOS processes that
  # delete asynchronously, after the postflight has already run. PlugInKit
  # records are keyed by bundle identifier, so the late event drops the
  # record the postflight had just created — the new bundle sitting at the
  # same path does not save it.
  #
  # So register, wait, and check that it STAYED; repeat until it does. It
  # normally takes two or three passes. The loop asserts its own outcome
  # rather than assuming it, because "ran the right command" and "the
  # extension is registered" came apart here by one second.
  #
  # Registration first, then the daemon — chronod has to come back to a
  # provider that already exists, or it comes back to nothing to draw.
  postflight do
    ext = "#{appdir}/Mihrab.app/Contents/PlugIns/PrayerWidgetExtension.appex"
    id = "maccatalyst.com.hassan.prayerapp.PrayerWidgetExtension"
    system_command "/bin/sh",
                   args:         ["-c", <<~SH],
                     for _ in 1 2 3 4 5 6 7 8 9 10; do
                       /usr/bin/pluginkit -a "#{ext}" >/dev/null 2>&1
                       sleep 3
                       if /usr/bin/pluginkit -m -i "#{id}" 2>/dev/null | grep -q .; then
                         exit 0
                       fi
                     done
                     exit 0
                   SH
                   must_succeed: false
    system_command "/usr/bin/killall",
                   args:         ["chronod"],
                   must_succeed: false
  end

  zap trash: "~/Library/Containers/maccatalyst.com.hassan.prayerapp"

  # No Gatekeeper caveat any more. It used to say "if the release is not
  # notarized yet, macOS may block the first launch - right-click Mihrab.app
  # and choose Open once", which was true of 2.11.0 through 2.13.3 and is
  # not true of anything shipped since: notarization happens inside
  # build-catalyst.sh, and both release.sh and verify-release.sh refuse a
  # build whose zip has no stapled ticket.
  caveats <<~EOS
    Mihrab for Mac is the same app as the iPad version, built with Mac
    Catalyst.
  EOS
end
