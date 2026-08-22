# Homebrew formula TEMPLATE for the ASCII Video Chat Terminal Client.
#
# This file is never installed as-is. `packaging/homebrew/bump-tap.sh`
# renders it (substituting https://github.com/OliviaHelmuth/ascii-video-chat/archive/refs/tags/v0.1.2.tar.gz/162ac6239a88d7e4e1a3b3368013ab48ebc82744bf1ef7913aad2ac3b31f22f5/0.1.2 for a real tagged
# release) and pushes the *rendered* result to Formula/ascii-video-chat.rb
# in the separate OliviaHelmuth/homebrew-ascii-video-chat tap repo — see
# .github/workflows/bump-tap.yml, which runs the same script automatically
# on every `v*` tag push. This template is the only thing that should ever
# be hand-edited (e.g. a new `depends_on`); the tap repo's real formula is
# regenerated from it on every release, never edited directly.
#
# Previously this was a real formula, hand-copied into the tap repo on
# every bump — that's exactly the "two copies kept in sync by a human"
# shape that let the tap silently drift a full version behind (v0.1.2
# tagged and released while the tap stayed on v0.1.1, caught only by
# chance). Converting to a template + script removes the second copy
# entirely rather than just automating the copy step.
#
# Builds from source via `cargo build --release` (simplest, most portable
# shape for a Rust binary — a prebuilt-bottle download is a future
# optimization, not required by
# .scratch/browser-handoff/issues/02-homebrew-formula.md).

class AsciiVideoChat < Formula
  desc "Live ASCII-art video calls, right in your terminal"
  homepage "https://github.com/OliviaHelmuth/ascii-video-chat"
  url "https://github.com/OliviaHelmuth/ascii-video-chat/archive/refs/tags/v0.1.2.tar.gz"
  sha256 "162ac6239a88d7e4e1a3b3368013ab48ebc82744bf1ef7913aad2ac3b31f22f5"
  version "0.1.2"
  license "MIT"

  depends_on "rust" => :build
  depends_on "pkg-config" => :build
  # opus (the audio crate)'s -sys crate links a system Opus via pkg-config
  # if it finds one, otherwise vendors and builds Opus's own CMakeLists.txt
  # via CMake -- which isn't declared as a dependency here and so isn't
  # present in Homebrew's sandboxed build environment at all ("is `cmake`
  # not installed?", caught for real on a first `brew install` attempt).
  # Declaring opus directly sidesteps that vendored-build path entirely,
  # matching the same real fix applied to .github/workflows/release.yml's
  # macOS jobs.
  depends_on "opus"

  def install
    system "cargo", "install", *std_cargo_args
    # Copied into the keg (not left in buildpath, which is torn down before
    # post_install runs) so caveats below can point at a stable path.
    (prefix/"packaging/macos").install "packaging/macos/AsciiCallHandler.applescript", "packaging/macos/build-and-register.sh"
  end

  # NOT run from post_install: Homebrew sandboxes install/post_install
  # filesystem writes, and registering the asciicall:// protocol handler
  # means writing a new .app bundle to ~/Applications and calling
  # lsregister -- exactly the kind of side effect that sandbox blocks.
  # Caught for real: build-and-register.sh silently no-op'd under
  # post_install (Ruby's `system` returns false on a nonzero exit rather
  # than raising, so a bare rescue never even reported it) while the exact
  # same script worked fine run by hand outside the sandbox immediately
  # after. `caveats` is Homebrew's own idiom for "here's an optional next
  # step" and matches the same opt-in posture install.sh/install.ps1 already
  # use for Linux/Windows registration -- printed, never silently applied.
  def caveats
    <<~EOS
      To enable "click to call" links (asciicall://) from the website, run:
        #{opt_prefix}/packaging/macos/build-and-register.sh
    EOS
  end

  test do
    # --list-cameras touches no camera/terminal state and always exits 0
    # (even with zero cameras found -- see src/main.rs's list_cameras_and_exit),
    # so it's a safe, fast install-sanity check for `brew test`.
    system "#{bin}/ascii-video-chat", "--list-cameras"
  end
end
