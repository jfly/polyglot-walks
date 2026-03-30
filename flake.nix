{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";

    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    import-tree.url = "github:vic/import-tree";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    systems.url = "github:nix-systems/default";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        systems = import inputs.systems;
        imports = [
          inputs.treefmt-nix.flakeModule
          inputs.git-hooks-nix.flakeModule
          ./benchmark
          ./walkers.nix
          (inputs.import-tree.filter (f: lib.hasSuffix "/flake-module.nix" f) ./.)
        ];

        perSystem.pre-commit.settings.hooks.treefmt.enable = true;

        perSystem.treefmt.programs = {
          nixfmt.enable = true;
          nixf-diagnose.enable = true;
        };
      }
    );
}
