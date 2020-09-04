class Bxdecay0 < Formula
  desc "Decay0/GENBB C++ Double Beta Decay Signal/Background Event Generator"
  homepage "https://github.com/BxCppDev/bxdecay0"
  url "https://github.com/BxCppDev/bxdecay0/archive/1.0.5.tar.gz"
  sha256 "9f65e92b9eec807b5e1c034018dff42dc178514656b1ff370ee1bacf7356f719"
  head "https://github.com/BxCppDev/bxdecay0.git", :branch => "develop"

  depends_on "cmake" => :build
  depends_on "gsl"

  def install
    mkdir "bxdecay0.build" do
      cmake_args = std_cmake_args
      cmake_args << "-DCMAKE_INSTALL_LIBDIR=lib"
      system "cmake", "..", *cmake_args
      system "make", "install"
    end
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      // Copyright 2017 François Mauger <mauger@lpccaen.in2p3.fr>
      #include <iostream>
      #include <bxdecay0/std_random.h>
      #include <bxdecay0/event.h>
      #include <bxdecay0/decay0_generator.h>

      int main()
      {
        unsigned int seed = 314159;
        std::default_random_engine generator(seed);
        bxdecay0::std_random prng(generator);
        bxdecay0::decay0_generator decay0;
        decay0.set_decay_category(bxdecay0::decay0_generator::DECAY_CATEGORY_DBD);
        decay0.set_decay_isotope("Mo100");
        decay0.set_decay_dbd_level(0);
        decay0.set_decay_dbd_mode(bxdecay0::DBDMODE_1);
        decay0.initialize(prng);

        for (std::size_t ievent = 0; ievent < 10; ++ievent) {
          bxdecay0::event gendecay;
          decay0.shoot(prng, gendecay);
          gendecay.store(std::cout);
        }

        decay0.reset();
        return 0;
       }
    EOS
    system ENV.cxx, "test.cpp", "-std=c++11", "-I#{include}", "-L#{lib}", "-lBxDecay0", "-o", "test"
    system "./test"
  end
end
