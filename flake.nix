{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    nativeBuildInputs = with pkgs; [
      vala
      meson
      ninja
      pkg-config
      wrapGAppsHook4
      blueprint-compiler
      desktop-file-utils
      gobject-introspection
    ];

    buildInputs = with pkgs; [
      gtk4
      glib
      gxml
      libsoup_3
      json-glib
      libadwaita
    ];
  in {
    devShells.${system}.default = pkgs.mkShell {
      inherit nativeBuildInputs buildInputs;
      packages = with pkgs; [
        vala-language-server
        vala-lint
        gdb
      ];
    };

    packages.${system}.default = pkgs.stdenv.mkDerivation {
      name = "vanana";
      version = "0.1";
      src = ./.;
      inherit nativeBuildInputs buildInputs;
    };
  };
}
