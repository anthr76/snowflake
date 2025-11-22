# Justfile for NixOS deployment automation

# Deploy a new machine with nixos-anywhere
# Usage: just deploy-new MACHINE IP
deploy-new MACHINE IP:
    #!/usr/bin/env bash
    set -euo pipefail
    temp=$(mktemp -d)
    # Generate keys in /persist/etc/ssh for impermanent systems
    # Also create /etc/ssh as a fallback for non-impermanent systems
    install -d -m755 "$temp/persist/etc/ssh"
    install -d -m755 "$temp/etc/ssh"
    ssh-keygen -t ed25519 -C "root@{{MACHINE}}" -f "$temp/persist/etc/ssh/ssh_host_ed25519_key" -N ""
    ssh-keygen -t rsa -C "root@{{MACHINE}}" -f "$temp/persist/etc/ssh/ssh_host_rsa_key" -N ""
    chmod 600 "$temp/persist/etc/ssh/ssh_host_ed25519_key"
    chmod 644 "$temp/persist/etc/ssh/ssh_host_ed25519_key.pub"
    chmod 600 "$temp/persist/etc/ssh/ssh_host_rsa_key"
    chmod 644 "$temp/persist/etc/ssh/ssh_host_rsa_key.pub"
    # Also copy to /etc/ssh for non-impermanent systems
    cp "$temp/persist/etc/ssh/ssh_host_ed25519_key"* "$temp/etc/ssh/"
    cp "$temp/persist/etc/ssh/ssh_host_rsa_key"* "$temp/etc/ssh/"
    echo "Generated SSH keys in $temp/persist/etc/ssh and $temp/etc/ssh"
    echo ""
    # Copy public key to host directory for knownHosts configuration
    mkdir -p "nixos/hosts/{{MACHINE}}"
    cp "$temp/persist/etc/ssh/ssh_host_ed25519_key.pub" "nixos/hosts/{{MACHINE}}/ssh_host_ed25519_key.pub"
    git add "nixos/hosts/{{MACHINE}}/ssh_host_ed25519_key.pub"
    echo "Copied public key to nixos/hosts/{{MACHINE}}/ssh_host_ed25519_key.pub"
    echo ""
    age_key=$(nix shell nixpkgs#ssh-to-age -c sh -c "cat $temp/persist/etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age")
    echo "Age key for SOPS: $age_key"
    echo ""
    echo "Updating .sops.yaml with new age key for {{MACHINE}}..."
    # Add key with comment to creation_rules using yq
    nix shell nixpkgs#yq-go -c yq -i ".creation_rules[0].key_groups[0].age += [\"$age_key\"] | .creation_rules[0].key_groups[0].age[-1] line_comment = \"{{MACHINE}}\"" .sops.yaml
    echo "Rekeying secrets/users.yaml..."
    nix shell nixpkgs#sops -c sops updatekeys secrets/users.yaml
    echo ""
    read -p "Press Enter to continue with deployment (Ctrl+C to cancel)..."
    nix run github:numtide/nixos-anywhere -- --extra-files "$temp" --flake ".#{{MACHINE}}" "root@{{IP}}"

# List available NixOS configurations
list-hosts:
    @echo "NixOS configurations:"
    @nix eval .#nixosConfigurations --apply builtins.attrNames --json | jq -r '.[]'

# List available Home Manager configurations
list-home:
    @echo "Home Manager configurations:"
    @nix eval .#homeConfigurations --apply builtins.attrNames --json | jq -r '.[]'

# Build a NixOS configuration
# Usage: just build-nixos MACHINE
build-nixos MACHINE:
    nix build .#nixosConfigurations.{{MACHINE}}.config.system.build.toplevel

# Build a Home Manager configuration
# Usage: just build-home USER@MACHINE
build-home CONFIG:
    nix build .#homeConfigurations."{{CONFIG}}".activationPackage

# Deploy to Kubernetes worker nodes
# Usage: just deploy-workers switch  OR  just deploy-workers boot
deploy-workers ACTION="switch":
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ "{{ACTION}}" != "switch" && "{{ACTION}}" != "boot" ]]; then
        echo "Error: ACTION must be 'switch' or 'boot'"
        exit 1
    fi

    workers=("worker-1" "worker-2" "worker-3" "worker-4" "worker-5")

    for worker in "${workers[@]}"; do
        echo "======================================"
        echo "Deploying $worker (nixos-rebuild {{ACTION}})..."
        echo "======================================"
        env NIX_SSHOPTS="-A" nixos-rebuild {{ACTION}} -L \
            --flake ".#$worker" \
            --option builders '' \
            --sudo \
            --use-remote-sudo \
            --target-host "anthony@${worker}.scr1.rabbito.tech" || {
            echo "ERROR: Failed to deploy $worker"
            read -p "Continue with remaining workers? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        }
        echo ""
    done

    echo "======================================"
    echo "Deployment complete!"
    echo "======================================"

# Deploy to a single Kubernetes worker
# Usage: just deploy-worker worker-1 switch
deploy-worker WORKER ACTION="switch":
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ "{{ACTION}}" != "switch" && "{{ACTION}}" != "boot" ]]; then
        echo "Error: ACTION must be 'switch' or 'boot'"
        exit 1
    fi

    echo "Deploying {{WORKER}} (nixos-rebuild {{ACTION}})..."
    env NIX_SSHOPTS="-A" nixos-rebuild {{ACTION}} -L \
        --flake ".#{{WORKER}}" \
        --option builders '' \
        --sudo \
        --use-remote-sudo \
        --target-host "anthony@{{WORKER}}.scr1.rabbito.tech"
