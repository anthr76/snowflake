# Nix Configuration
This repository is home to the nix code that builds my systems (mostly linux rarely mac).

# New Machines

In the future a script should be written to take care of this but but in the meantime:

```fish
set temp $(mktemp -d)
install -d -m755 "$temp/etc/ssh"
ssh-keygen -t ed25519 -C "root@master-04" -f $temp/etc/ssh/ssh_host_ed25519_key
ssh-keygen  -t rsa -C "root@master-04" -f $temp/etc/ssh/ssh_host_rsa_key
chmod 600 "$temp/etc/ssh/ssh_host_ed25519_key"
chmod 644 "$temp/etc/ssh/ssh_host_ed25519_key.pub"
chmod 600 "$temp/etc/ssh/ssh_host_rsa_key"
chmod 644 "$temp/etc/ssh/ssh_host_rsa_key.pub"
nix shell nixpkgs#ssh-to-age -c sh -c "cat $temp/etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age"
# Add to .sops.yaml rekey secrets
# nix run github:numtide/nixos-anywhere -- --extra-files "$temp" --flake ".#${MACHINE}" "root@${IP}" --no-reboot
nix run github:numtide/nixos-anywhere -- --extra-files "$temp" --flake ".$MACHINE" "root@$IP"
```

Note: If bootstrapping a LUKs machine make sure to `echo -n` the password or ensure there's no new-line.
