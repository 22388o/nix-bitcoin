# This flake just mirrors input `nixos-search`.
# Because `nixos-search` is a dev-only dependency, we don't add
# it to the main flake.
{
  inputs.nixos-search.url = "github:nixos/nixos-search";

  outputs = { self, nixos-search }: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    inherit (nixos-search.inputs.nixpkgs) lib;
  in {
    packages = lib.genAttrs systems (system: {
      # In flake-info, Rust calls into Nix code which uses `nixpkgs` from NIX_PATH.
      # Don't set `nixpkgs` to a tarball URL, use the default value from the environment instead.
      # This allows running flake-info in an offline environment (./flake-info-sandboxed.sh).
      flake-info = nixos-search.packages.${system}.flake-info.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace src/commands/nix_flake_attrs.rs --replace-fail \
            'command.add_arg_pair("-I", "nixpkgs=https://github.com/NixOS/nixpkgs/archive/refs/heads/nixpkgs-unstable.tar.gz");' ""
        '';
      });
    });

    # Used by ./ci-test.sh
    inherit (nixos-search.inputs.nixpkgs) legacyPackages;
  };
}
