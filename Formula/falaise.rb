class Falaise < Formula
  desc "Simulation, Reconstruction and Analysis Software for SuperNEMO"
  homepage "https://github.com/supernemo-dbd/Falaise"
  url "https://github.com/SuperNEMO-DBD/Falaise/archive/Falaise-4.0.1.tar.gz"
  sha256 "d350fd83e0dbf984a4032c3115d3c3a7266c528c3bcb33eb5ea263f6313a8e5c"
  head "https://github.com/SuperNEMO-DBD/Falaise.git", :branch => "develop"

  depends_on "cmake" => :build
  depends_on "doxygen" => :build
  # Bayeux dependency pulls in all additional deps of Falaise at present
  depends_on "bayeux"

  def install
    ENV.cxx11
    mkdir "falaise.build" do
      fl_cmake_args = std_cmake_args
      fl_cmake_args << "-DCMAKE_INSTALL_LIBDIR=lib"
      fl_cmake_args << "-DFALAISE_CXX_STANDARD=11"
      fl_cmake_args << "-DFALAISE_COMPILER_ERROR_ON_WARNING=OFF"
      system "cmake", "..", *fl_cmake_args
      system "make", "install"
    end
  end

  test do
    system "#{bin}/flsimulate", "-o", "test.brio"
    system "#{bin}/flreconstruct", "-i", "test.brio", "-p", "urn:snemo:demonstrator:reconstruction:1.0.0", "-o", "test.root"
  end
end
