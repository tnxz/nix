{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    system = "aarch64-darwin";
    username = "zoro";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;
    homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        {
          home = {
            username = "${username}";
            homeDirectory = "/Users/${username}";
          };
        }
        ./home.nix
      ];
    };
  };
}
