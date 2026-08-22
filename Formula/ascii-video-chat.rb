# Homebrew formula for the ASCII Video Chat Terminal Client.
#
# Lives at Formula/ascii-video-chat.rb in the OliviaHelmuth/homebrew-ascii-video-chat
# tap repo (also mirrored here at packaging/homebrew/ in the main repo, kept
# in sync by hand on each bump). Builds from source via `cargo build
# --release` (simplest, most portable shape for a Rust binary — a
# prebuilt-bottle download is a future optimization, not required by
# .scratch/browser-handoff/issues/02-homebrew-formula.md).
#
# --- Bumping to a new release (repeatable, manual today) -----------------
# 1. Tag and push a new version (triggers .github/workflows/release.yml).
# 2. url = "https://github.com/OliviaHelmuth/ascii-video-chat/archive/refs/tags/vX.Y.Z.tar.gz"
# 3. sha256 = `curl -fsSL <that url> -o t.tar.gz && shasum -a 256 t.tar.gz`
#    (the *source* tarball's hash, not any of the release.yml binaries —
#    Homebrew verifies what it downloads to build from, and this formula
#    builds from source).
# 4. version "X.Y.Z"
# 5. Copy this file to Formula/ascii-video-chat.rb in the tap repo and push.
# ---------------------------------------------------------------------------

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
