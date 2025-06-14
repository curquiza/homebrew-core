class Melange < Formula
  desc "Build APKs from source code"
  homepage "https://github.com/chainguard-dev/melange"
  url "https://github.com/chainguard-dev/melange/archive/refs/tags/v0.26.9.tar.gz"
  sha256 "78d631adb59e6b16ed276ba3c21159588f8d55d8f821b5c48e2fe2058771f2a2"
  license "Apache-2.0"
  head "https://github.com/chainguard-dev/melange.git", branch: "main"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "a8bc773f6e67988ec1a04297715d76034073baae716b9eb574892f6e933b37e7"
    sha256 cellar: :any_skip_relocation, arm64_sonoma:  "4b289530d4d68367fd7434199894eb07695be606119100d90eeb4b2b8b666dbd"
    sha256 cellar: :any_skip_relocation, arm64_ventura: "11dabb710e51f59b02ba59eed8f77b1e45bd1b8a7d7023405c92d1a07922ebe9"
    sha256 cellar: :any_skip_relocation, sonoma:        "4376893d434337857abd2288904e357c53f20b07b527a06f68c00bfae16bd8ad"
    sha256 cellar: :any_skip_relocation, ventura:       "6e2c4cb63026b95f869866e98ace86884a60f96866e7cb397bba70f5103429da"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "2cace09510f720dc861dc2348ffd6e6bb80281d27aa2ffabf619b0d53aa77c33"
  end

  depends_on "go" => :build

  def install
    ldflags = %W[
      -s -w
      -X sigs.k8s.io/release-utils/version.gitVersion=#{version}
      -X sigs.k8s.io/release-utils/version.gitCommit=brew
      -X sigs.k8s.io/release-utils/version.gitTreeState=clean
      -X sigs.k8s.io/release-utils/version.buildDate=#{time.iso8601}
    ]
    system "go", "build", *std_go_args(ldflags:)

    generate_completions_from_executable(bin/"melange", "completion")
  end

  test do
    (testpath/"test.yml").write <<~YAML
      package:
        name: hello
        version: 2.12
        epoch: 0
        description: "the GNU hello world program"
        copyright:
          - paths:
            - "*"
            attestation: |
              Copyright 1992, 1995, 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2005,
              2006, 2007, 2008, 2010, 2011, 2013, 2014, 2022 Free Software Foundation,
              Inc.
            license: GPL-3.0-or-later
        dependencies:
          runtime:

      environment:
        contents:
          repositories:
            - https://dl-cdn.alpinelinux.org/alpine/edge/main
          packages:
            - alpine-baselayout-data
            - busybox
            - build-base
            - scanelf
            - ssl_client
            - ca-certificates-bundle

      pipeline:
        - uses: fetch
          with:
            uri: https://ftp.gnu.org/gnu/hello/hello-${{package.version}}.tar.gz
            expected-sha256: cf04af86dc085268c5f4470fbae49b18afbc221b78096aab842d934a76bad0ab
        - uses: autoconf/configure
        - uses: autoconf/make
        - uses: autoconf/make-install
        - uses: strip
    YAML

    assert_equal "hello-2.12-r0", shell_output("#{bin}/melange package-version #{testpath}/test.yml")

    system bin/"melange", "keygen"
    assert_path_exists testpath/"melange.rsa"

    assert_match version.to_s, shell_output(bin/"melange version 2>&1")
  end
end
