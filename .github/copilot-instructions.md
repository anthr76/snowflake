# Copilot Instructions

This is a **Nix Flake-based system configuration** that manages both NixOS systems and Home Manager configurations across multiple machines (Linux desktops, servers, and macOS via nix-darwin).

## Architecture Overview

- **`flake.nix`**: Central entry point defining inputs, outputs, and system configurations
- **`nixos/hosts/`**: Machine-specific NixOS configurations (f80, lattice, octo, routers, etc.)
- **`home-manager/hosts/`**: User environment configurations per machine
- **`personalities/`**: Reusable configuration modules organized by purpose:
  - `base/`: Core system settings (SSH, networking, users, SOPS secrets)
  - `desktop/`: GUI applications and window managers
  - `cli/`: Terminal tools and shell configuration
  - `server/`: Server-specific configurations
- **`modules/`**: Custom NixOS/Home Manager modules for reusable functionality
- **`pkgs/`**: Custom package definitions and overrides
- **`overlays/`**: Package modifications and custom packages injection

## Key Patterns & Conventions

### Host Configuration Structure
Each host follows this pattern:
```nix
# nixos/hosts/{hostname}/default.nix
{
  imports = [
    ../../personalities/base  # Always include base personality
    ../../personalities/desktop/wayland-wm/kde  # Add specific personalities
    inputs.hardware.nixosModules.common-cpu-amd  # Hardware-specific modules
    inputs.disko.nixosModules.disko  # Disk partitioning
  ];
  networking.hostName = "hostname";
  # Host-specific overrides
}
```

### Secrets Management with SOPS
- Secrets stored in `secrets/users.yaml` encrypted with SSH host keys
- Each host automatically configures SOPS using its SSH host keys: `sops.age.sshKeyPaths = map getKeyPath keys`
- Reference secrets: `sops.secrets.secret-name = { sopsFile = ../../../secrets/users.yaml; };`
- Use secrets: `config.sops.secrets.secret-name.path`

### Disk Configuration with Disko
- Each host has a `disks.nix` file defining partitioning scheme
- LUKS encryption is standard, using SOPS-managed passwords
- BTRFS with subvolumes: `/root`, `/home`, `/nix` with compression
- Reference pattern: `disko.devices = import ./disks.nix { disks = ["/dev/disk/by-id/..."]; luksCreds = config.sops.secrets.password.path; };`

## Development Workflows

### Bootstrapping New Machines
Use the documented fish script in `README.md`:
1. Generate SSH host keys in temp directory
2. Convert SSH key to age key for SOPS: `ssh-to-age`
3. Deploy with nixos-anywhere: `nix run github:numtide/nixos-anywhere -- --extra-files "$temp" --flake ".#hostname" "root@ip"`

### Building & Testing
- **Dev shell**: `nix develop` (enables flakes, provides home-manager, git, sops)
- **Build system**: `nix build .#nixosConfigurations.hostname.config.system.build.toplevel`
- **Build home config**: `nix build .#homeConfigurations."user@hostname".activationPackage`
- **CI/CD**: Uses `nix-github-actions` to auto-generate matrix builds for all configurations

### Overlays & Package Customization
- **Custom packages**: Add to `pkgs/default.nix`, automatically available via `additions` overlay
- **Package modifications**: Use `modifications` overlay in `overlays/default.nix`
- **Flake inputs access**: Use `inputs.flake-name.packages.${system}.package-name` pattern

## Integration Points

### Multi-System Support
- `systems = ["x86_64-linux" "aarch64-linux"]` with `forEachSystem` helper
- Platform-specific imports: `lib.optionals pkgs.stdenv.isLinux`
- Shared personalities between NixOS and Home Manager where applicable

### External Dependencies
- **Chaotic Nyx**: Gaming-optimized packages via `chaotic.nixosModules.default`
- **Hardware**: `nixos-hardware` modules for common hardware configurations
- **Catppuccin**: Theme consistency across applications
- **SOPS-nix**: Centralized secrets management
- **Disko**: Declarative disk partitioning

### Home Manager Integration
- User configs in `home-manager/users/{username}/` with platform-specific imports
- Personalities shared between system and user level where logical
- Home configs reference system-level decisions (e.g., wayland vs X11)

## Special Considerations

- **Router configurations**: Custom modules in `modules/nixos/router.nix` with specialized networking
- **Gaming systems**: Use Chaotic Nyx overlay, custom kernel modules, GPU-specific optimizations
- **macOS support**: Limited via nix-darwin in `nix-darwin/` directory
- **Secrets**: Never commit unencrypted secrets; always use SOPS with proper key management
- **Firmware**: Enable `hardware.enableRedistributableFirmware` for most systems, custom firmware overlays when needed
