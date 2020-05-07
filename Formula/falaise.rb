class Falaise < Formula
  desc "Simulation, Reconstruction and Analysis Software for SuperNEMO"
  homepage "https://github.com/supernemo-dbd/Falaise"
  url "https://github.com/SuperNEMO-DBD/Falaise/archive/v4.0.3.tar.gz"
  sha256 "9ba7b35578f22c39f033818039b43be261bc99edffd3091e26aade16a7cd0715"
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
