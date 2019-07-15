class Bayeux < Formula
  desc "Core C++ Framework Library for SuperNEMO Experiment"
  homepage "https://github.com/supernemo-dbd/bayeux"
  head "https://github.com/SuperNEMO-DBD/Bayeux.git", :branch => "develop"
  stable do
    url "https://github.com/SuperNEMO-DBD/Bayeux/archive/3.4.1.tar.gz"
    sha256 "94785ec23c77e5b4785d39cb6a6f94fa9f0229989778bdf688ef43b7a4fead8a"
    version "3.4.1"
  end

  option "with-devtools", "Build debug tools for Bayeux developers"

  depends_on "cmake" => :build
  depends_on "doxygen" => :build
  depends_on "icu4c"
  depends_on "readline"
  depends_on "boost"
  depends_on "camp"
  depends_on "clhep"
  depends_on "geant4"
  depends_on "gsl"
  depends_on "qt5-base"
  depends_on "root6"

  def install
    ENV.cxx11
    mkdir "bayeux.build" do
      bx_cmake_args = std_cmake_args
      bx_cmake_args << "-DCMAKE_INSTALL_LIBDIR=lib"
      bx_cmake_args << "-DBAYEUX_CXX_STANDARD=11"
      bx_cmake_args << "-DBAYEUX_COMPILER_ERROR_ON_WARNING=OFF"
      bx_cmake_args << "-DBAYEUX_WITH_QT_GUI=ON"
      bx_cmake_args << "-DBAYEUX_WITH_DEVELOPER_TOOLS=OFF" if build.without? "devtools"
      bx_cmake_args << "-DBAYEUX_ENABLE_TESTING=ON" if build.devel?

      system "cmake", "..", *bx_cmake_args

      if build.devel?
        system "make"
        # Run tests, but ignore known failure for Ubuntu 16.04
        system "ctest", "-E", "datatools-test_ui_ihs"
      end

      system "make", "install"
    end
  end

  test do
    system "#{bin}/bxg4_production", "--help"
  end
end
