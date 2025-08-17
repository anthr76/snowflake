CRUSH.md — quick ops guide for this repo

Repo type: Nix flake (NixOS + Home Manager + custom pkgs). Focus: build, format, validate flake outputs.

Build/dev
- Enter dev shell: nix develop
- Show outputs: nix flake show
- Evaluate/lint/test: nix flake check (mirrors CI matrix locally)
- Build a package: nix build .#wayland-push-to-talk-fix
- Build installer ISO / VM: nix build .#installer-iso && nix build .#installer-vm
- Build a NixOS host: nix build .#nixosConfigurations.f80.config.system.build.toplevel
- Build a Home Manager profile: nix build .#homeConfigurations."anthony@f80".activation-script
- Switch a NixOS host: sudo nixos-rebuild switch --flake .#f80
- Switch Home Manager: home-manager switch --flake .#anthony@f80
- Run a single CI check attr (examples): nix build .#checks.x86_64-linux.{nixos-f80,home-anthony@f80,pkgs-wayland-push-to-talk-fix}

Lint/format
- Nix formatting (Alejandra): nix run nixpkgs#alejandra -- -q .
- Optional hooks (if present): pre-commit run -a

Style guidelines (Nix)
- Formatting: 2-space indent; final newline; trim trailing whitespace; run Alejandra before commits.
- Imports/attrs: Prefer explicit module lists; use inherit to pull pkgs/inputs/outputs; follow flake.nix patterns.
- Naming: lower-case, dash-separated for package names (e.g., wayland-push-to-talk-fix); host keys match nixos/hosts directory names.
- Types/modules: Use module options; prefer lib.mkEnableOption, mkIf, mkMerge; keep host logic in nixos/hosts and HM in home-manager/hosts.
- Shell snippets: use set -euo pipefail; avoid leaking secrets; manage secrets via sops-nix as configured.

AI assistant rules
- Cursor/Copilot: No .cursor/rules, .cursorrules, or .github/copilot-instructions.md found.
- Keep changes minimal and idiomatic; do not introduce new tooling without justification.
