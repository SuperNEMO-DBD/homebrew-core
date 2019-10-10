class Tbb < Formula
  desc "Rich and complete approach to parallelism in C++"
  homepage "https://www.threadingbuildingblocks.org/"
  url "https://github.com/01org/tbb/archive/2019_U3.tar.gz"
  version "2019_U3"
  sha256 "b2244147bc8159cdd8f06a38afeb42f3237d3fc822555499d7ccfbd4b86f8ece"
  revision 2

  # Patch for cmakeConfig, from spack
  patch :p0, :DATA

  depends_on "cmake" => :build

  def install
    # In addition to patch, need an inreplace for tbb_root
    inreplace "cmake/templates/TBBConfig.cmake.in",
      "get_filename_component(_tbb_root \"${_tbb_root}\" PATH)",
      "get_filename_component(_tbb_root \"${_tbb_root}/../../..\" ABSOLUTE)"

    compiler = (ENV.compiler == :clang) ? "clang" : "gcc"
    args = %W[tbb_build_prefix=BUILDPREFIX compiler=#{compiler} stdver=c++11]

    # Fix /usr/bin/ld: cannot find -lirml by building rml
    system "make", "rml", *args unless OS.mac?

    system "make", *args
    if OS.mac?
      lib.install Dir["build/BUILDPREFIX_release/*.dylib"]
      lib.install Dir["build/BUILDPREFIX_debug/*.dylib"]
    else
      lib.install Dir["build/BUILDPREFIX_release/*.so*"]
      lib.install Dir["build/BUILDPREFIX_debug/*.so*"]
    end

    # Build and install static libraries
    system "make", "tbb_build_prefix=BUILDPREFIX", "compiler=#{compiler}",
                   "stdver=c++11", "extra_inc=big_iron.inc"
    lib.install Dir["build/BUILDPREFIX_release/*.a"]
    include.install "include/tbb"

    if OS.mac?
      tbb_os = "Darwin"
    else
      tbb_os = "Linux"
    end

    system "cmake", "-DTBB_ROOT=#{prefix}",
                    "-DTBB_OS=#{tbb_os}",
                    "-DSAVE_TO=lib/cmake/TBB",
                    "-P", "cmake/tbb_config_generator.cmake"
    (lib/"cmake"/"TBB").install Dir["lib/cmake/TBB/*.cmake"]
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include <tbb/task_scheduler_init.h>
      #include <iostream>

      int main()
      {
        std::cout << tbb::task_scheduler_init::default_num_threads();
        return 0;
      }
    EOS
    system ENV.cxx, "test.cpp", "-L#{lib}", "-ltbb", "-o", "test"
    system "./test"
  end
end

__END__
--- cmake/templates/TBBConfig.cmake.in~	2018-03-30 10:55:05.000000000 -0500
+++ cmake/templates/TBBConfig.cmake.in	2018-05-25 10:25:52.498708945 -0500
@@ -52,7 +52,7 @@

 @TBB_CHOOSE_COMPILER_SUBDIR@

-get_filename_component(_tbb_lib_path "${_tbb_root}/@TBB_SHARED_LIB_DIR@/${_tbb_arch_subdir}/${_tbb_compiler_subdir}" ABSOLUTE)
+get_filename_component(_tbb_lib_path "${_tbb_root}/@TBB_SHARED_LIB_DIR@" ABSOLUTE)

 foreach (_tbb_component ${TBB_FIND_COMPONENTS})
     set(_tbb_release_lib "${_tbb_lib_path}/@TBB_LIB_PREFIX@${_tbb_component}.@TBB_LIB_EXT@")
