# RFC 2136 Support for External-DNS

This document explains how to use the RFC 2136 support for external-dns that has been added to the router module.

## Overview

The router module now supports RFC 2136 dynamic DNS updates, specifically designed to work with [external-dns](https://kubernetes-sigs.github.io/external-dns/) in Kubernetes clusters. This allows external-dns to automatically create, update, and delete DNS records in your BIND DNS server based on Kubernetes resources like Ingresses and Services.

## Configuration

### Basic Setup

Add the RFC 2136 configuration to your router service configuration:

```nix
services.router = {
  enable = true;
  domain = "scr1.rabbito.tech";

  # ... other router configuration ...

  # RFC 2136 / external-dns support
  rfc2136 = {
    enable = true;
    externalDnsZones = ["scr1.rabbito.tech" "kutara.io"];
    defaultTtl = 300; # 5 minutes
  };
};
```

### Configuration Options

- `enable`: Enable RFC 2136 support for external-dns
- `externalDnsZones`: List of DNS zones that external-dns should manage
- `bindAddress`: IP address for external-dns to connect to (defaults to management VLAN router IP)
- `port`: Port for external-dns to connect to (default: 53)
- `defaultTtl`: Default TTL for external-dns managed records (default: 300)

**Note**: This implementation always uses the existing DHCP TSIG key (`dhcp-update-key`) for simplicity and to avoid configuration conflicts.

### Zone Handling

- If a zone in `externalDnsZones` matches your main router domain (e.g., `scr1.rabbito.tech`), external-dns will be able to update the existing zone
- Additional zones (like `kutara.io`) will be created as separate zones specifically for external-dns management
- All zones use the same TSIG key for authentication

## Kubernetes Setup

### 1. Get Configuration Information

After rebuilding your system, the router will generate configuration information:

```bash
# View the generated external-dns configuration
cat /var/lib/external-dns-config/config.yaml

# Use the helper script to create the Kubernetes secret
/var/lib/external-dns-config/create-secret.sh
```

### 2. Create External-DNS Secret Manually

If you prefer to create the secret manually:

```bash
# Create external-dns namespace
kubectl create namespace external-dns

# Create the TSIG secret
kubectl create secret generic external-dns-tsig-key \
  --from-literal=secret="$(cat /run/secrets/ddns-tsig-key)" \
  --namespace=external-dns
```

### 3. Deploy External-DNS

Here's a sample external-dns deployment for your cluster:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-dns
  namespace: external-dns
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: external-dns
rules:
- apiGroups: [""]
  resources: ["services","endpoints","pods","nodes"]
  verbs: ["get","watch","list"]
- apiGroups: ["extensions","networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["get","watch","list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: external-dns-viewer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: external-dns
subjects:
- kind: ServiceAccount
  name: external-dns
  namespace: external-dns
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns
  namespace: external-dns
spec:
  selector:
    matchLabels:
      app: external-dns
  template:
    metadata:
      labels:
        app: external-dns
    spec:
      serviceAccountName: external-dns
      containers:
      - name: external-dns
        image: registry.k8s.io/external-dns/external-dns:v0.13.2
        args:
        - --registry=txt
        - --txt-prefix=external-dns-
        - --txt-owner-id=k8s
        - --provider=rfc2136
        - --rfc2136-host=192.168.8.1  # Your router's IP on the kubernetes VLAN
        - --rfc2136-port=53
        - --rfc2136-zone=scr1.rabbito.tech
        - --rfc2136-zone=kutara.io
        - --rfc2136-tsig-secret-alg=hmac-sha256
        - --rfc2136-tsig-keyname=dhcp-update-key
        - --rfc2136-tsig-axfr
        - --source=ingress
        - --source=service
        - --domain-filter=scr1.rabbito.tech
        - --domain-filter=kutara.io
        - --rfc2136-min-ttl=300s
        env:
        - name: RFC2136_TSIG_SECRET
          valueFrom:
            secretKeyRef:
              name: external-dns-tsig-key
              key: secret
        args:
        - --rfc2136-tsig-secret=$(RFC2136_TSIG_SECRET)
```

## Usage Examples

### Service with LoadBalancer

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  annotations:
    external-dns.alpha.kubernetes.io/hostname: myapp.scr1.rabbito.tech
    external-dns.alpha.kubernetes.io/ttl: "300"
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: my-app
```

### Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    external-dns.alpha.kubernetes.io/ttl: "300"
spec:
  rules:
  - host: myapp.scr1.rabbito.tech
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-service
            port:
              number: 80
```

## Network Configuration

Make sure your Kubernetes cluster can reach the router's BIND server:

- The router listens on the management VLAN (typically `10.20.99.1` for VLAN 99)
- External-DNS pods need network access to this IP on port 53
- Consider network policies if they're restrictive in your cluster

## Troubleshooting

### Check BIND Logs

```bash
journalctl -u bind -f
```

### Check Zone Files

```bash
ls -la /var/lib/bind/
# Look for journal files (.jnl) and zone files
```

### Test DNS Updates

```bash
# Test TSIG key authentication
nsupdate -k /run/secrets/ddns-tsig-key
> server 192.168.8.1
> zone scr1.rabbito.tech
> update add test.scr1.rabbito.tech 300 A 1.2.3.4
> send
> quit
```

### Check External-DNS Logs

```bash
kubectl logs -n external-dns deployment/external-dns -f
```

## Security Considerations

1. **TSIG Key Security**: The TSIG key allows DNS updates, so protect it carefully
2. **Network Access**: Limit which hosts can reach your BIND server on port 53
3. **Zone Restrictions**: Only configure zones you want external-dns to manage
4. **Firewall Rules**: Ensure appropriate firewall rules are in place

## Integration with Existing Setup

This RFC 2136 support integrates seamlessly with your existing router setup:

- Existing DHCP dynamic DNS updates continue to work
- Static DNS records are preserved
- The same TSIG key can be used for both DHCP and external-dns updates
- Zone serial numbers are automatically updated
