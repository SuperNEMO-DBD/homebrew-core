class Qt5Base < Formula
  desc "Qt5 Core Libraries"
  homepage "http://qt-project.org/"
  url "http://download.qt.io/official_releases/qt/5.12/5.12.6/submodules/qtbase-everywhere-src-5.12.6.tar.xz"
  sha256 "6ab52649d74d7c1728cf4a6cf335d1142b3bf617d476e2857eb7961ef43f9f27"

  keg_only "qt5 is very picky about install locations, so keep it isolated"

  depends_on "pkg-config" => :build
  depends_on :xcode => :build if OS.mac?

  unless OS.mac?
    depends_on "icu4c"
    depends_on "fontconfig"
    depends_on "freetype"
  end

  conflicts_with "qt5", :because => "Core homebrew ships a complete Qt5 install"

  # try submodules as resources
  resource "qtsvg" do
    url "http://download.qt.io/official_releases/qt/5.12/5.12.6/submodules/qtsvg-everywhere-src-5.12.6.tar.xz"
    sha256 "46243e6c425827ab4e91fbe31567f683ff14cb01d12f9f7543a83a571228ef8f"
  end

  def install
    unless OS.mac?
      # Only way to get Qt to look for system GL/Xlibs
      sys_pkgconf_path = Utils.popen_read("/usr/bin/pkg-config --variable pc_path pkg-config").chomp
      ENV.append_path "PKG_CONFIG_PATH", "#{sys_pkgconf_path}"
    end

    args = %W[
      -verbose
      -prefix #{prefix}
      -release
      -opensource -confirm-license
      -qt-zlib
      -qt-libpng
      -qt-libjpeg
      -qt-freetype
      -qt-pcre
      -nomake tests
      -nomake examples
      -pkg-config
      -no-openssl
      -no-avx
      -no-avx2
      -no-sql-mysql
      -no-sql-psql
      -c++std c++14
    ]

    unless OS.mac?
      # Minimizes X11 dependencies
      # See
      # https://github.com/Linuxbrew/homebrew-core/pull/1062
      args << "-qt-xcb"

      # Ensure GUI can display fonts, fontconfig option
      # must be used with system-freetype. Dependence on
      # brewed fontconfig on Linux should pull both in
      args << "-fontconfig"
      args << "-system-freetype"

      # Need to use -R as qt5 seemingly ignores LDFLAGS, and doesn't
      # use -L paths provided by pkg-config. Configure can have odd
      # effects depending on what system provides.
      # Qt5 is keg-only, so add its own libdir
      args << "-R#{lib}"
      # If we depend on anything from brew, then need the core path
      args << "-R#{HOMEBREW_PREFIX}/lib"
      # If we end up depending on any keg_only Formulae, add extra
      # -R lines for each of them below here.

      # Portable binaries for kernels < 3.17 cannot be created without
      # these flags. In particular, they are required to allow modern
      # containers to run on older systems.
      args << "-no-feature-renameat2"
      args << "-no-feature-getentropy"
    end

    system "./configure", *args

    # Cannot parellize build os OSX
    system "make"
    system "make", "install"

    resource("qtsvg").stage do
      system "#{bin}/qmake"
      system "make", "install"
    end
  end

  def caveats; <<~EOS
    We agreed to the Qt opensource license for you.
    If this is unacceptable you should uninstall.
  EOS
  end

  test do
    (testpath/"hello.pro").write <<~EOS
      QT       += core
      QT       -= gui
      TARGET = hello
      CONFIG   += console
      CONFIG   -= app_bundle
      TEMPLATE = app
      SOURCES += main.cpp
    EOS

    (testpath/"main.cpp").write <<~EOS
      #include <QCoreApplication>
      #include <QDebug>
      int main(int argc, char *argv[])
      {
        QCoreApplication a(argc, argv);
        qDebug() << "Hello World!";
        return 0;
      }
    EOS

    system bin/"qmake", testpath/"hello.pro"
    system "make"
    assert_predicate testpath/"hello", :exist?
    assert_predicate testpath/"main.o", :exist?
    system "./hello"
  end
end
