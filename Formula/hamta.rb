class Hamta < Formula
  desc "Run commands through a configurable proxy environment"
  homepage "https://github.com/andrewmmc/hamta"
  head "https://github.com/andrewmmc/hamta.git", branch: "master"
  license "MIT"

  depends_on "jq"
  depends_on "curl"

  def install
    bin.install "bin/hamta"
    (share/"hamta").install "share/hamta/config.json"
  end

  def caveats
    <<~EOS
      Run `hamta init` to create your initial config at ~/.config/hamta/config.json.
      Edit that file to set your proxy URL and expected country.
    EOS
  end

  test do
    system "#{bin}/hamta", "--version"
  end
end
