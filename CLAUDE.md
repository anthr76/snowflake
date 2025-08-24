# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a comprehensive Nix flake repository containing NixOS system configurations, Home Manager profiles, custom packages, and modules. The repository manages multiple machines (both desktop and server configurations) using a modular architecture.

## Development Commands

### Essential Commands
- Enter development shell: `nix develop`
- Show all available outputs: `nix flake show`
- Run full validation (mirrors CI): `nix flake check`
- Format Nix code: `nix run nixpkgs#alejandra -- -q .`

### Building
- Build custom packages: `nix build .#<package-name>` (e.g., `nix build .#wayland-push-to-talk-fix`)
- Build installer ISO: `nix build .#installer-iso`
- Build installer VM: `nix build .#installer-vm`
- Build NixOS configuration: `nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel`
- Build Home Manager profile: `nix build .#homeConfigurations."<user>@<host>".activation-script`

### Deployment
- Switch NixOS host: `sudo nixos-rebuild switch --flake .#<hostname>`
- Switch Home Manager: `home-manager switch --flake .#<user>@<host>`

### Testing Individual CI Checks
- Run specific check: `nix build .#checks.x86_64-linux.{nixos-<host>,home-<user>@<host>,pkgs-<package>}`

## Architecture

### Directory Structure
- `nixos/hosts/` - NixOS system configurations for specific machines
- `home-manager/hosts/` - Home Manager configurations per user@host
- `nixos/personalities/` - Reusable NixOS configuration modules (base, desktop, server, physical)
- `home-manager/personalities/` - Reusable Home Manager modules (cli, desktop, global)
- `modules/` - Custom NixOS and Home Manager modules
- `pkgs/` - Custom package definitions
- `overlays/` - Nixpkgs overlays for package modifications
- `secrets/` - SOPS-encrypted secrets

### Key Hosts
- `f80`, `lattice` - Desktop machines with gaming/desktop personalities
- `bkp1`, `octo`, `cdgc` - Server/workstation machines
- `fw1-*` - Network infrastructure (routers)

### Personalities System
The configuration uses a "personalities" pattern where common functionality is grouped:
- **Base**: Core system settings, networking, users, nix configuration
- **Desktop**: GUI applications, audio, gaming, window managers
- **Server**: Server-specific services, networking, router functionality
- **Physical**: Hardware-specific settings (TPM, YubiKey, etc.)

## Code Style Guidelines

### Nix Formatting
- Use 2-space indentation
- Always include final newline
- Trim trailing whitespace
- Run Alejandra formatter before commits: `nix run nixpkgs#alejandra -- -q .`

### Module Patterns
- Use explicit module lists in imports
- Prefer `inherit` to pull `pkgs`, `inputs`, `outputs` into scope
- Use `lib.mkEnableOption`, `lib.mkIf`, `lib.mkMerge` for conditional logic
- Keep host-specific logic in `nixos/hosts/` and `home-manager/hosts/`
- Use lower-case, dash-separated naming for packages

### Security
- All secrets managed via sops-nix
- Shell scripts should use `set -euo pipefail`
- Never leak secrets in build outputs or logs

## Custom Packages

Available custom packages in `pkgs/`:
- `wayland-push-to-talk-fix` - Wayland push-to-talk functionality
- `discover-overlay` - Gaming overlay application
- `yuki-iptv` - IPTV application
- `rpc-bridge` - RPC bridge utility
- `udpbroadcastrelay` - UDP broadcast relay service

## Machine Provisioning

For new machines, use the nixos-anywhere workflow documented in README.md:
1. Generate SSH host keys
2. Convert to age keys for sops
3. Update `.sops.yaml` and rekey secrets
4. Deploy with `nix run github:numtide/nixos-anywhere`

## Important Notes

- All machines use the chaotic-cx/nyx overlay for additional packages
- Desktop machines include Catppuccin theming
- Gaming machines have specific kernel patches and gamescope modifications
- Router configurations include custom networking modules
- Framework laptop (lattice) includes hardware-specific modules