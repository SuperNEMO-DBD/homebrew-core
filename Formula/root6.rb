class Root6 < Formula
  desc "CERN C++ Data Analysis and Persistency Libraries"
  homepage "http://root.cern.ch"
  head "http://root.cern.ch/git/root.git"

  stable do
    url "https://root.cern.ch/download/root_v6.18.04.source.tar.gz"
    version "6.18.04"
    sha256 "315a85fc8363f8eb1bffa0decbf126121258f79bd273513ed64795675485cfa4"
  end

  depends_on "cmake" => :build
  depends_on "freetype"
  depends_on "gsl"
  depends_on "libxml2" unless OS.mac? # For XML on Linux
  depends_on "lz4"
  depends_on "openssl"
  depends_on "python"
  depends_on "sqlite"
  depends_on "tbb"
  depends_on "xrootd"
  depends_on "xxhash"
  depends_on "xz" # For LZMA

  conflicts_with "root", :because => "SuperNEMO requires custom root build"

  skip_clean "bin"

  def install
    # Work around "error: no member named 'signbit' in the global namespace"
    ENV.delete("SDKROOT") if DevelopmentTools.clang_build_version >= 900
    args = *std_cmake_args
    args << "-DCMAKE_INSTALL_ELISPDIR=#{elisp}"
    # Avoid macOS case issues from "root/ROOT" paths
    args << "-DCMAKE_INSTALL_INCLUDEDIR=include/root6"

    # Disable everything that might be ON by default
    args += %w[
      -Dalien=OFF
      -Dasimage=OFF
      -Dastiff=OFF
      -Dbonjour=OFF
      -Dcastor=OFF
      -Dchirp=OFF
      -Ddavix=OFF
      -Ddcache=OFF
      -Dfitsio=OFF
      -Dfortran=OFF
      -Dgfal=OFF
      -Dglite=OFF
      -Dgviz=OFF
      -Dhdfs=OFF
      -Dkrb5=OFF
      -Dldap=OFF
      -Dmonalisa=OFF
      -Dmysql=OFF
      -Dodbc=OFF
      -Doracle=OFF
      -Dpgsql=OFF
      -Dpythia6=OFF
      -Dpythia8=OFF
      -Dpython=OFF
      -Dqt=OFF
      -Drfio=OFF
      -Dsapdb=OFF
      -Dsqlite=OFF
      -Dsrp=OFF
      -Dtmva-cpu=OFF
      -Dtmva-gpu=OFF
      -Dtmva-pymva=OFF
      -Dunuran=OFF
      -Dvdt=OFF
    ]

    # Now the core/builtin things we want
    args += %w[
      -Dcxx11=ON
      -Dgnuinstall=ON
      -Dexplicitlink=ON
      -Drpath=ON
      -Dsoversion=ON
      -Dfail-on-missing=ON
      -Dbuiltin_asimage=ON
      -Dasimage=ON
      -Dbuiltin_fftw3=ON
      -Droofit=ON
      -Dgdml=ON
      -Dminuit2=ON
    ]

    # Options that require an external
    args += %w[
      -Dsqlite=ON
      -Dssl=ON
      -Dbuiltin_openssl=OFF
      -Dmathmore=ON
      -Dxrootd=ON
      -Dbuiltin_xrootd=OFF
    ]

    # Python
    py_exe = Utils.popen_read("which python3").strip
    py_prefix = Utils.popen_read("python3 -c 'import sys;print(sys.prefix)'").chomp
    py_inc =
      Utils.popen_read("python3 -c 'from distutils import sysconfig;print(sysconfig.get_python_inc(True))'").chomp
    py_lib = Utils.popen_read("python3 -c 'from distutils import sysconfig;print(sysconfig.get_config_var(\"LDLIBRARY\"))'").chomp

    args << "-Dpython=ON"
    args << "-DPYTHON_EXECUTABLE='#{py_exe}'"
    args << "-DPYTHON_INCLUDE_DIR='#{py_inc}'"
    if OS.mac?
      args << "-DPYTHON_LIBRARY='#{py_prefix}/Python'"
    else
      args << "-DPYTHON_LIBRARY='#{py_prefix}/lib/#{py_lib}'"
    end

    mkdir "cmake-build" do
      system "cmake", "..", *args

      # Follow upstream homebrew
      # Work around superenv stripping out isysroot leading to errors with
      # libsystem_symptoms.dylib (only available on >= 10.12) and
      # libsystem_darwin.dylib (only available on >= 10.13)
      if OS.mac? && MacOS.version < :high_sierra
        system "xcrun", "make", "install"
      else
        system "make", "install"
      end

      chmod 0755, Dir[bin/"*.*sh"]
    end
  end

  def caveats; <<~EOS
    Because ROOT depends on several installation-dependent
    environment variables to function properly, you should
    add the following commands to your shell initialization
    script (.bashrc/.profile/etc.), or call them directly
    before using ROOT.
    For bash users:
      . $(brew --prefix root6)/libexec/thisroot.sh
    For zsh users:
      pushd $(brew --prefix root6) >/dev/null; . libexec/thisroot.sh; popd >/dev/null
    For csh/tcsh users:
      source `brew --prefix root6`/libexec/thisroot.csh
  EOS
  end

  test do
    (testpath/"test.C").write <<~EOS
      #include <iostream>
      void test() {
        std::cout << "Hello, world!" << std::endl;
      }
    EOS
    (testpath/"test.bash").write <<~EOS
      . #{bin}/thisroot.sh
      root -l -b -n -q test.C
    EOS
    assert_equal "\nProcessing test.C...\nHello, world!\n",
                 shell_output("/bin/bash test.bash")

    ENV["PYTHONPATH"] = "#{lib}/root"
    system "python2", "-c", "'import ROOT'"
  end
end
