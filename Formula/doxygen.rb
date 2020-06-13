class Doxygen < Formula
  desc "Generate documentation for several programming languages"
  homepage "http://www.doxygen.org/"

  url "https://github.com/doxygen/doxygen/archive/Release_1_8_15.tar.gz"
  sha256 "cc5492b3e2d1801ae823c88e0e7a38caee61a42303587e987142fe9b68a43078"
  head "https://github.com/doxygen/doxygen.git"

  bottle do
    cellar :any_skip_relocation
    rebuild 2
    sha256 "e3144ca8ebdb1abd668cb4eee36feb3bb5d545bc3d056f207109d2ae57013f5c" => :mojave
    sha256 "b6b7234f2644de37a48d7459f3b360127c4e92df8bb56d48b9a4128f58eaf90b" => :high_sierra
    sha256 "305156f3d060deeee197759c5ce6ea8a1da36ad52f8104b42cd7ccbb2b20c0e7" => :sierra
    sha256 "c1020caeac6ba8cf1b338c66f7c4b38fd185a42d2a439556b291ab6b7c3ee826" => :x86_64_linux
  end

  depends_on "cmake" => :build
  unless OS.mac?
    depends_on "bison"
    depends_on "flex"
  end

  # Fix build breakage for 1.8.15 and CMake 3.13
  # https://github.com/Homebrew/homebrew-core/issues/35815
  patch do
    url "https://github.com/doxygen/doxygen/commit/889eab308b564c4deba4ef58a3f134a309e3e9d1.diff?full_index=1"
    sha256 "ba4f9251e2057aa4da3ae025f8c5f97ea11bf26065a3f0e3b313b9acdad0b938"
  end

  def install
    args = std_cmake_args + %W[
      -DCMAKE_OSX_DEPLOYMENT_TARGET:STRING=#{MacOS.version}
    ]

    mkdir "build" do
      system "cmake", "..", *args
      system "make"
    end
    bin.install Dir["build/bin/*"]
    man1.install Dir["doc/*.1"]
  end

  test do
    system "#{bin}/doxygen", "-g"
    system "#{bin}/doxygen", "Doxyfile"
  end
end
