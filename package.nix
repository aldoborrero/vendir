{
  buildGoApplication,
  lib,
}:
buildGoApplication {
  pname = "vendir";
  version = "0.42.2";

  src = lib.cleanSource ./.;

  modules = ./gomod2nix.toml;

  ldflags = [
    "-s"
    "-w"
  ];

  subPackages = ["cmd/vendir"];

  meta = {
    mainProgram = "vendir";
  };
}
