class Xrootd < Formula
  desc "High performance, scalable, fault-tolerant access to data"
  homepage "http://xrootd.org"
  url "http://xrootd.org/download/v4.12.1/xrootd-4.12.1.tar.gz"
  sha256 "7350d9196a26d17719b839fd242849e3995692fda25f242e67ac6ec907218d13"
  head "https://github.com/xrootd/xrootd.git"

  depends_on "cmake" => :build
  depends_on "libxml2"
  depends_on "openssl"
  depends_on "python"
  depends_on "readline"
  depends_on "zlib"

  def install
    ENV.cxx11
    mkdir "build" do
      # Python requires some care...
      # PYTHON_EXECUTABLE appears to doo all that is needed,
      # but xrootd will pick up unrelated python libs, even
      # if it does not end up using these.
      py_exe = Utils.popen_read("which python3").strip
      py_ver = Language::Python.major_minor_version(py_exe)
      py_prefix = Utils.popen_read("#{py_exe} -c 'import sys;print(sys.prefix)'").chomp
      py_incdir = Utils.popen_read("#{py_exe} -c 'from distutils import sysconfig;print(sysconfig.get_python_inc(True))'").chomp
      # Framework or shared lib?
      dylib = OS.mac? ? "dylib" : "so"
      if File.exist? "#{py_prefix}/Python"
        py_lib = "#{py_prefix}/Python"
      elsif File.exist? "#{py_prefix}/lib/libpython#{py_ver}m.#{dylib}"
        py_lib = "#{py_prefix}/lib/libpython#{py_ver}m.#{dylib}"
      else
        odie "No Python Framework or libpython#{py_ver}.#{dylib} found!"
      end

      args = *std_cmake_args
      args << "-DCMAKE_INSTALL_LIBDIR=#{lib}"
      args << "-DPYTHON_EXECUTABLE='#{py_exe}'"
      args << "-DPYTHON_INCLUDE_DIR='#{py_incdir}'"
      args << "-DPYTHON_LIBRARY='#{py_lib}'"
      args << "-DENABLE_FUSE=OFF"
      args << "-DENABLE_KRB5=OFF"

      system "cmake", "..", *args
      system "make", "install"
    end
  end

  test do
    system "#{bin}/xrootd", "-H"
  end
end
