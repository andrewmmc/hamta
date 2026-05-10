class Hamta < Formula
  desc "Run commands through a configurable proxy environment"
  homepage "https://github.com/andrewmmc/hamta"
  url "https://github.com/andrewmmc/hamta/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "ec10c51e14cc63ca95f888d15299f4dbebe23c740e6dd5f49bdda652ca95f3c6"
  license "MIT"
  head "https://github.com/andrewmmc/hamta.git", branch: "master"

  depends_on "curl"
  depends_on "jq"

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
    assert_match "hamta #{version}", shell_output("#{bin}/hamta --version")
  end
end
