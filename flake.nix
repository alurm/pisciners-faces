{
  description = "A website to display pisciners' faces and their nicknames";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, utils, nixpkgs }: let
    name = "pisciners-faces";
  in utils.lib.eachDefaultSystem (
    system: let
      pkgs = nixpkgs.legacyPackages.${system};
      inherit name;
    in {
      packages.default = pkgs.buildGoModule {
        name = "server";
        src = ./server;
        vendorHash = "sha256-Lw6Dqz+jt4lVBtX4jW3BP7wmkA4/qLib58YrRNgfAac=";
      };
    }
  ) // {
    nixosModules.default = { config, lib, pkgs, ... }: let
      cfg = config.services.pisciners-faces;
    in {
      options.services.pisciners-faces = let
        inherit (lib) mkOption types;
        inherit (types) bool str;
      in {
        enable = mkOption {
          type = bool;
          default = false;
          description = "A website to display pisciners' faces and their nicknames";
        };
        http-prefix-path = mkOption {
          type = str;
          default = "";
          description = "Path to the file containing the HTTP (path) prefix";
        };
        identity = mkOption {
          type = str;
          default = "";
          description = "TLS identity, example: example.com";
        };
        email = mkOption {
          type = str;
          default = "";
          description = "Email for the certificate authority";
        };
        port = mkOption {
          type = str;
          default = "";
          description = "Port to listen on";
        };
        tls = mkOption {
          type = bool;
          default = false;
          description = "Enable TLS";
        };
        index = mkOption {
          type = bool;
          default = false;
          description = "Whether to tell search engines to index the site";
        };
        content = mkOption {
          type = str;
          default = "";
          description = "Path to content";
        };
        certificates = mkOption {
          type = str;
          default = "";
          description = "TLS certificates path";
        };
      };

      config = lib.mkIf cfg.enable {
        users.users.pisciners-faces = {
          description = "Pisciners' faces service user";
          isSystemUser = true;
          group = "pisciners-faces";
          createHome = true;
          home = "/home/pisciners-faces";
        };

        users.groups.pisciners-faces = {};

        systemd.services.pisciners-faces = {
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
          script = ''
            cd /home/${name} &&
            ${self.packages.${pkgs.system}.default}/bin/server \
              ${if cfg.tls then "-tls" else ""} \
              ${if cfg.http-prefix-path != "" then "-http-prefix \"$(cat ${cfg.http-prefix-path})\"" else ""} \
              ${if cfg.identity != "" then "-identity ${cfg.identity}" else ""} \
              ${if cfg.email != "" then "-email ${cfg.email}" else ""} \
              ${if cfg.port != "" then "-port ${cfg.port}" else ""} \
              ${if cfg.index then "-index" else ""} \
              ${if cfg.certificates != "" then "-certificates ${cfg.certificates}" else ""} \
              ${if cfg.content != "" then "-content ${cfg.content}" else ""} \
            ;
          '';
        };
      };
    };
  };
}