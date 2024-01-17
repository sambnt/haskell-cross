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

    # Copy the derivation here
    cp -r ${drv} ./

    zip -qr $out/${drv.name}.zip .
  '';
}
