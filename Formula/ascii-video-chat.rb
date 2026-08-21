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
  url "https://github.com/OliviaHelmuth/ascii-video-chat/archive/refs/tags/v0.1.1.tar.gz"
  sha256 "d73101460036f258c01775738b56dcc792447bb4d6dcb64da7c24ed8c783751f"
  version "0.1.1"
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
  end

  def post_install
    # Registers the asciicall:// protocol handler (ticket 05,
    # .scratch/browser-handoff/issues/05-protocol-handler.md) so "click to
    # call" links from the Landing Page open straight into a call. A bare
    # CLI binary has no app bundle for Launch Services to route a URL scheme
    # to, so this builds a minimal one -- see build-and-register.sh's own
    # doc comment for what that mechanism actually does and what's been
    # smoke-tested vs. not. Best-effort: a failure here doesn't fail the
    # install, since the CLI itself works fine without it.
    system buildpath/"packaging/macos/build-and-register.sh"
  rescue => e
    opoo "asciicall:// protocol handler registration failed (call handoff links won't work): #{e}"
  end

  test do
    # --list-cameras touches no camera/terminal state and always exits 0
    # (even with zero cameras found -- see src/main.rs's list_cameras_and_exit),
    # so it's a safe, fast install-sanity check for `brew test`.
    system "#{bin}/ascii-video-chat", "--list-cameras"
  end
end
