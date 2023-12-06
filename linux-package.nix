{ lib
, stdenv
, patchelf
, zip
}:

drv: bin:

let
  binPath = "${drv}/bin/${bin}";
in
  stdenv.mkDerivation {
    name = bin;
    buildInputs = [ drv patchelf zip ];
    src = ./.;
    phases = [ "installPhase" ];

    installPhase = ''
      mkdir $out/
      pushd $out/

      # Copy the binary out
      cp ${binPath} ./${bin}

      # Copy the shared objects that our binary depends on to a subfolder `lib/`.
      mkdir lib
      cp $(ldd ${binPath} | grep -F '=> /' | awk '{print $3}') $out/lib/

      # Patch the binary to point the ELF interpreter and the run-time search
      # path to the shared objects we provide. Note that these paths are location
      # independent: as long as the binary is in the same directory as the folder
      # containing our shared objects, this will work.
      chmod +w ${bin}
      patchelf --set-interpreter ./lib/ld-linux-x86-64.so.2 --set-rpath ./lib --force-rpath ${bin}
      chmod -w ${bin}
      # We also need to patch the run-time search path of the shared objects
      # we're including, as some of the shared objects may too dynamically link
      # on other shared objects.
      chmod +w ./lib/lib*
      patchelf --set-rpath ./lib --force-rpath ./lib/lib*
      chmod -w ./lib/lib*

      # Finally, we can zip up our binary and the subfolder holding our shared objects.
      # This zip file is the output artefact of this derivation and can be uploaded to AWS
      # Lambda as-is.
      zip -qr ${bin}.zip .

      rm -r lib ${bin}
      popd
    '';
  }
