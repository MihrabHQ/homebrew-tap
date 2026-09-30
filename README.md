# Mihrab on Homebrew

A Homebrew tap for **Mihrab** — a free, open-source prayer times app for macOS,
with no ads, no analytics and no tracking.

```sh
brew install --cask mihrabhq/tap/mihrab
```

That one command installs and updates the app; `brew upgrade` keeps it current,
and every Mihrab release updates this cask the same day.

It needs macOS 12.1 (Monterey) or later, on Apple silicon or Intel; the
widgets need macOS 14 (Sonoma).

## What you get

The macOS build is the iPad app through Mac Catalyst, so it is the whole app,
not a companion:

- **Prayer times and adhan reminders** — from AlAdhan, PrayerTimes.dev,
  Islamiska Förbundet, or calculated on the device once a location is set.
- **Notification Centre widgets** — next prayer, the day's times, the prayer
  log, ayah of the day. The cask restarts `chronod` after installing, because
  macOS otherwise keeps showing the previous version's widget data forever.
- **The full Madinah mushaf** — the printed KFGQPC page, with recitation,
  word-by-word timing, tafsir and translations.
- **Duas, tasbih, and a fasting and prayer journal.**

No ads, no analytics SDK, no crash reporter, no account, and nothing to buy.
The app is [AGPL-3.0-or-later](https://github.com/MihrabHQ/Mihrab/blob/main/LICENSE)
and builds from one public repository.

## Elsewhere

Android and iOS ship the same app from the same `main` branch:

- [Website](https://mihrab.elghamri.se/)
- [Source](https://github.com/MihrabHQ/Mihrab) · [Releases](https://github.com/MihrabHQ/Mihrab/releases)
- [F-Droid](https://f-droid.org/packages/com.prayer_times/) — built and signed by
  F-Droid, with no Google Play Services
- [Google Play](https://play.google.com/store/apps/details?id=com.prayer_times) ·
  [App Store](https://apps.apple.com/us/app/prayer-salah-times-qibla/id6762085256)

## Uninstalling

```sh
brew uninstall --cask mihrab
```

Problems with the app itself belong in the
[Mihrab issue tracker](https://github.com/MihrabHQ/Mihrab/issues); problems
with the cask can go here.
