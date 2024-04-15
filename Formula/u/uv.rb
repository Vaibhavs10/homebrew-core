class Uv < Formula
  desc "Extremely fast Python package installer and resolver, written in Rust"
  homepage "https://github.com/astral-sh/uv"
  url "https://github.com/astral-sh/uv/archive/refs/tags/0.1.32.tar.gz"
  sha256 "17d6b5ffd6fc068c534aacef55b16ae53fb33fc8c7b735f4c920de000af2a4c5"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/astral-sh/uv.git", branch: "main"

  bottle do
    sha256 cellar: :any,                 arm64_sonoma:   "03b7164040d81ec17f181083bcd6f4517aa3fdfa6c6dd34d335479505a051d6d"
    sha256 cellar: :any,                 arm64_ventura:  "cdd7500dc8f04f3d27de3791857841c7f1017fb54f7098b8a3221425f23f7075"
    sha256 cellar: :any,                 arm64_monterey: "95a49c52077614ea72d2988b5e23176c086c65a793194a7f5d5d14cedb9b2bac"
    sha256 cellar: :any,                 sonoma:         "0df9c926e29b2da44259b91a707d86c900982f80074725bd1b5fb2490ddbe702"
    sha256 cellar: :any,                 ventura:        "a54bacbded3cb0ff85c17effcede185e539802b5ad7f59d14ed7d30e17dc6c95"
    sha256 cellar: :any,                 monterey:       "6b4b023ea55ebf8ddd191433b85f3b6acdaf03fc6fa67b61eada151fad29d708"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "053e810e3314fd7fa2265da59038681641494dbf84b7c6d95a8da53bfd39bed1"
  end

  depends_on "pkg-config" => :build
  depends_on "rust" => :build
  depends_on "libgit2"
  depends_on "openssl@3"

  uses_from_macos "python" => :test

  def install
    ENV["LIBGIT2_NO_VENDOR"] = "1"

    # Ensure that the `openssl` crate picks up the intended library.
    ENV["OPENSSL_DIR"] = Formula["openssl@3"].opt_prefix
    ENV["OPENSSL_NO_VENDOR"] = "1"

    system "cargo", "install", "--no-default-features", *std_cargo_args(path: "crates/uv")
    generate_completions_from_executable(bin/"uv", "generate-shell-completion")
  end

  def check_binary_linkage(binary, library)
    binary.dynamically_linked_libraries.any? do |dll|
      next false unless dll.start_with?(HOMEBREW_PREFIX.to_s)

      File.realpath(dll) == File.realpath(library)
    end
  end

  test do
    (testpath/"requirements.in").write <<~EOS
      requests
    EOS

    compiled = shell_output("#{bin}/uv pip compile -q requirements.in")
    assert_match "This file was autogenerated by uv", compiled
    assert_match "# via requests", compiled

    [
      Formula["libgit2"].opt_lib/shared_library("libgit2"),
      Formula["openssl@3"].opt_lib/shared_library("libssl"),
      Formula["openssl@3"].opt_lib/shared_library("libcrypto"),
    ].each do |library|
      assert check_binary_linkage(bin/"uv", library),
             "No linkage with #{library.basename}! Cargo is likely using a vendored version."
    end
  end
end
