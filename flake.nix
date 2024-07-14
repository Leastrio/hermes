{
  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem
    (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };

        erlangVersion = "erlang_26";
        elixirVersion = "elixir_1_16";

        elixir = pkgs.beam.packages.${erlangVersion}.${elixirVersion};
        erlang = pkgs.beam.interpreters.${erlangVersion};
      in rec {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            elixir
            erlang
            pkgs.gcc14
            pkgs.gnumake
            pkgs.clang-tools
            pkgs.bear
          ];
          ERL_AFLAGS = "-kernel shell_history enabled";
          ERL_INCLUDE_PATH = "${erlang}/lib/erlang/usr/include";
        };
      }
    );
}
