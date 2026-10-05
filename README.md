# ScrollBack

[![Download via Homebrew](https://img.shields.io/badge/Homebrew-brew%20install--cask-black?logo=homebrew)](https://github.com/NspxMiguel/homebrew-tap)

A menu bar utility for macOS that does two things to a mouse, and nothing to
a trackpad:

- **Reverses the scroll wheel direction** — but only for an actual mouse with
  a physical wheel. Trackpads and the Magic Mouse keep whatever direction you
  already have set in System Settings.
- **Revives the side buttons** (back / forward) on mice whose 4th/5th button
  macOS's generic driver doesn't recognize. If the system already delivers
  the click natively, ScrollBack gets out of the way — it only steps in when
  the press would otherwise go nowhere.

## Why "only the mouse"

macOS's own "natural scrolling" toggle is one switch for every pointing
device. A lot of people want a mouse wheel to scroll the classic way while
keeping a trackpad on natural scrolling (or vice versa) — and there's no
built-in way to split that. ScrollBack tells the two apart using the same
signal the wheel itself reports: a physical mouse sends discrete "line"
scroll events, while trackpads and the Magic Mouse send continuous,
pixel-precise ones. Flipping only the first kind is what makes the mouse
setting independent of the trackpad one.

## Why "revive" the side buttons

Some mice ship a back/forward button pair that never turns into a usable
event on macOS — the click happens in hardware, but the generic HID driver
drops it. ScrollBack watches the raw HID report for that press. If the
system turns it into a real event on its own within a few milliseconds,
ScrollBack does nothing (so you never get a doubled navigation). If nothing
shows up, it synthesizes the button press itself, and back/forward starts
working system-wide — Finder, Safari, most browsers, and anything else that
already understands mouse button 4/5.

## Install

```bash
brew install --cask nspxmiguel/tap/scrollback
```

The cask compiles ScrollBack on your own machine (no signed binary is
distributed), which is why the first install takes about a minute.

On first launch, ScrollBack asks for two permissions in System Settings →
Privacy & Security:

- **Accessibility** — to reverse the wheel. Without it, scrolling is untouched.
- **Input Monitoring** — to see the side buttons. Without it, they stay dead.

There is no need to relaunch after granting them: the app checks every two
seconds and starts on its own.

## Menu

Click the mouse icon in the menu bar:

- **Reverse scroll (mouse only)** — toggle the wheel inversion.
- **Enable side buttons (back / forward)** — toggle the button revival.
- **Start at login**.

## How it works, for the curious

- `ScrollInverter` taps `scrollWheel` events (`CGEventTap`) and negates the
  delta fields only when `scrollWheelEventIsContinuous == 0` — the field
  that separates a physical wheel from a trackpad/Magic Mouse.
- `SideButtonReviver` watches raw HID button reports with `IOHIDManager` for
  HID button usages 4 and 5. Each press arms a ~25ms window; a second,
  listen-only event tap watches for a real `otherMouseDown` with the matching
  button number. If one arrives in time, the press is left alone. If not,
  ScrollBack posts a synthetic `otherMouseDown`/`otherMouseUp` itself.

## Build from source

```bash
git clone https://github.com/NspxMiguel/ScrollBack
cd ScrollBack
./build.sh
open build/ScrollBack.app
```

## Support

Free and open source. If it saved you time, pay what it was worth at [nspx.dev/loja](https://www.nspx.dev/loja/) — any amount, no account.

## License

MIT
