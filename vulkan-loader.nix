{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, libX11, libxcb
, libXrandr, wayland, moltenvk, vulkan-headers, addOpenGLRunpath, python311 }:

stdenv.mkDerivation rec {
  pname = "vulkan-loader";
  version = "1.3.261";

  src = fetchFromGitHub {
    owner = "KhronosGroup";
    repo = "Vulkan-Loader";
    rev = "v${version}";
    hash = "sha256-5QCVHfvjE98EnL2Dr7g9fdrJAg+np1Q6hgqcuZCWReQ=";
  };

  patches = [ ./fix-pkgconfig.patch ];

  nativeBuildInputs = [ cmake pkg-config ]
    ++ lib.optionals (stdenv.hostPlatform.isWindows) [ python311 ];
  buildInputs = [ vulkan-headers ]
    ++ lib.optionals (stdenv.isLinux) [ libX11 libxcb libXrandr wayland ]
    ++ lib.optionals (stdenv.hostPlatform.isWindows) [ python311 ];

  cmakeFlags = [ "-DCMAKE_INSTALL_INCLUDEDIR=${vulkan-headers}/include" ]
    ++ lib.optional stdenv.isDarwin "-DSYSCONFDIR=${moltenvk}/share"
    ++ lib.optional stdenv.isLinux "-DSYSCONFDIR=${addOpenGLRunpath.driverLink}/share"
    ++ lib.optional (stdenv.buildPlatform != stdenv.hostPlatform) "-DUSE_GAS=OFF"
    ++ lib.optional ((stdenv.buildPlatform != stdenv.hostPlatform) && stdenv.hostPlatform.isWindows) "-DUSE_MASM=OFF";

  outputs = [ "out" "dev" ];

  doInstallCheck = true;

  installCheckPhase = ''
    grep -q "${vulkan-headers}/include" $dev/lib/pkgconfig/vulkan.pc || {
      echo vulkan-headers include directory not found in pkg-config file
      exit 1
    }
  '';

  meta = with lib; {
    description = "LunarG Vulkan loader";
    homepage    = "https://www.lunarg.com";
    platforms   = platforms.unix ++ platforms.windows;
    license     = licenses.asl20;
    maintainers = [ maintainers.ralith ];
    broken = (version != vulkan-headers.version);
  };
}
