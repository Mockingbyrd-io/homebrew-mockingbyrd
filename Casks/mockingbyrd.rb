cask "mockingbyrd" do
  version "1.0.366"
  sha256 "db017a9387a1d8119ef59dad14dfff7d3986e3512bf8832da2756265b480ca76"

  url "https://mockingbyrd.io/download/Mockingbyrd-#{version}.dmg"
  name "Mockingbyrd"
  desc "Measures a workstation running AI agents against one operating doctrine"
  homepage "https://mockingbyrd.io/"

  # The download page publishes a manifest beside the image, so livecheck reads the version
  # from the same file the site reads rather than scraping the page for it.
  livecheck do
    url "https://mockingbyrd.io/download/latest.json"
    strategy :json do |json|
      json["version"]
    end
  end

  # arm64 only. There is no universal binary and no Intel slice to fall back to, so this is a
  # refusal up front rather than a download that installs and then will not launch.
  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "Mockingbyrd.app"

  # An upgrade replaces the bundle, but a process that is already running keeps the copy it
  # started from -- so the gateway went on serving the previous version after every release until
  # somebody restarted it by hand. Twice in a row is a pattern, not an accident. If the agent is
  # loaded, restart it into what was just installed; if it is not loaded, this does nothing, and
  # must_succeed: false keeps a machine that never installed the gateway from failing its upgrade.
  # `postflight`, despite the deprecation notice brew prints. The stanza it points at,
  # postflight_steps, is a declarative file DSL -- mkdir, move, symlink, write -- with no way to
  # run a command, so it cannot do this. Tried: it fails with "undefined method 'system_command'".
  postflight do
    system_command "/bin/launchctl",
                   args: ["kickstart", "-k", "gui/#{Process.uid}/com.marcobuhlmann.mockingbird.gateway"],
                   must_succeed: false
  end

  # Deliberately no `auto_updates true`. The app can install an update itself -- it verifies the
  # download against the published checksum, a Developer ID signature and a notarization ticket
  # before replacing anything -- but it never does so to a copy Homebrew installed, because
  # brew's receipt would then name a version that is not on disk. For this cask brew is the only
  # route, so the stanza would be false and would make `brew upgrade` skip it.

  zap trash: [
    "~/.config/mockingbird",
    "~/Library/Application Support/Mockingbird",
    "~/Library/Preferences/com.marcobuhlmann.mockingbird.plist",
    "~/Library/Saved Application State/com.marcobuhlmann.mockingbird.savedState",
  ]

  caveats <<~EOS
    Mockingbyrd measures this machine by itself. The part that enforces anything is a
    PreToolUse hook you install from inside the app:

      ~/.claude/hooks/t0-guard

    Uninstalling the cask leaves that hook in place, and it keeps running with no app
    behind it -- so a call it would have asked you about is refused instead, because
    nothing is there to answer. Turn enforcement off in the app before you uninstall,
    or take the lot:

      brew uninstall --zap --cask mockingbyrd
  EOS
end
