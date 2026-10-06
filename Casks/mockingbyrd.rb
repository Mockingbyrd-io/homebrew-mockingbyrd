cask "mockingbyrd" do
  version "1.0.240"
  sha256 "150687d1f9bff13c2f8491fe517a58ec4b273d95eb0593bd1a8d1b999114149f"

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

  # Deliberately no `auto_updates true`. That stanza means the app replaces itself and tells
  # Homebrew to leave it alone -- and this one does not. Its update check fetches a static
  # file, compares two version numbers and offers a link; it installs nothing. Claiming
  # otherwise would make `brew upgrade` skip this cask and strand people on what they first got.

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
