# Worker-01 - Kubernetes Worker Node

## Overview

This is a Kubernetes worker node configured to run on bkp1 hardware with:
- Impermanence (ephemeral root filesystem)
- LUKS encryption
- TLS bootstrapping for Kubernetes
- Containerd runtime

## Prerequisites

1. Ensure the host is accessible via SSH
2. Update `disks.nix` with the correct disk ID
3. Generate SSH host keys for SOPS encryption
4. Configure SOPS secrets for:
   - LUKS password
   - Kubernetes bootstrap token

## SOPS Configuration

Add the following secrets to `secrets/users.yaml`:

```yaml
worker-01-password: <LUKS_PASSWORD>
worker-01-k8s-bootstrap-token: <BOOTSTRAP_TOKEN>
```

Then update the `.sops.yaml` to include worker-01's age key.

## Deployment

### Initial Bootstrap

```fish
# Set variables
set temp (mktemp -d)
set host "worker-01"
set target_ip "TARGET_IP_HERE"

# Generate SSH keys for the host
ssh-keygen -t ed25519 -f "$temp/ssh_host_ed25519_key" -N ""

# Convert SSH key to age key for SOPS
nix shell nixpkgs#ssh-to-age --command sh -c "cat $temp/ssh_host_ed25519_key.pub | ssh-to-age"

# Update .sops.yaml with the age key, then encrypt secrets
cd ~/dev/snowflake
sops updatekeys secrets/users.yaml

# Deploy with nixos-anywhere
nix run github:numtide/nixos-anywhere -- \
  --extra-files "$temp" \
  --flake ".#$host" \
  "root@$target_ip"
```

### Kubernetes Bootstrap

After deployment, the node will need the bootstrap kubeconfig at:
`/var/lib/kubernetes/bootstrap-kubeconfig`

This should be managed via SOPS and deployed through the host configuration.

## Example Bootstrap Kubeconfig

```yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: /var/lib/kubernetes/pki/ca.crt
    server: https://api.k8s.nwk2.rabbito.tech:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubelet-bootstrap
  name: default
current-context: default
users:
- name: kubelet-bootstrap
  user:
    token: <BOOTSTRAP_TOKEN>
```

## Firewall Configuration

The worker node opens:
- TCP 10250 (kubelet API)
- TCP 30000-32767 (NodePort services)

Ensure your network firewall allows:
- Outbound to API server (6443)
- Inbound from control plane nodes to 10250
- Inbound from anywhere to NodePort range (if using NodePort services)

## Impermanence

The following directories persist across reboots:
- `/var/lib/kubernetes` - Kubernetes certificates and configuration
- `/var/lib/kubelet` - Kubelet state
- `/var/lib/containerd` - Container images and state
- `/etc/cni` and `/opt/cni` - CNI configuration
- `/var/log` - System logs
- `/etc/machine-id` - Stable node identity

Everything else in `/` is wiped on reboot.

## Monitoring

The node is configured with Vector for log shipping to your observability platform.
Labels:
- `site: nwk2`
- `role: k8s-worker`

## Maintenance

### Updating

```fish
cd ~/dev/snowflake
nix flake update
nixos-rebuild switch --flake ".#worker-01" --target-host "worker-01.nwk2.rabbito.tech" --use-remote-sudo
```

### Debugging

SSH to the node and check:
```bash
systemctl status kubelet
systemctl status containerd
journalctl -u kubelet -f
```
