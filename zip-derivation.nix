{ lib
, stdenv
, zip
}:

drv:

stdenv.mkDerivation {
  name = drv.name;
  buildInputs = [ drv zip ];
  phases = [ "installPhase" ];

  installPhase = ''
    mkdir $out/

    pushd ${drv}
    zip -r $out/${drv.name}.zip ./*
    popd
  '';
}
