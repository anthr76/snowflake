{ config, ... }:
let
  #TODO: Make this more modular for more clusters
  controlPlaneEndpoint = "https://cluster-0.scr1.rabbito.tech:6443";
in
{

  sops.secrets = {
    etcd-client-ca = {
      sopsFile = ../secrets.sops.yaml;
      owner = config.users.users.kubernetes.name;
      group = config.users.users.kubernetes.group;
    };
    etcd-cert = {
      sopsFile = ../secrets.sops.yaml;
      owner = config.users.users.kubernetes.name;
      group = config.users.users.kubernetes.group;
    };
    etcd-cert-key = {
      sopsFile = ../secrets.sops.yaml;
      owner = config.users.users.kubernetes.name;
      group = config.users.users.kubernetes.group;
    };
    kubelet-client-cert = {
      sopsFile = ../secrets.sops.yaml;
      owner = config.users.users.kubernetes.name;
      group = config.users.users.kubernetes.group;
    };
    kubelet-client-key = {
      sopsFile = ../secrets.sops.yaml;
      owner = config.users.users.kubernetes.name;
      group = config.users.users.kubernetes.group;
    };
    proxy-client-cert = {
      sopsFile = ../secrets.sops.yaml;
      owner = config.users.users.kubernetes.name;
      group = config.users.users.kubernetes.group;
    };
    proxy-client-key = {
      sopsFile = ../secrets.sops.yaml;
      owner = config.users.users.kubernetes.name;
      group = config.users.users.kubernetes.group;
    };
    service-account-key = {
      sopsFile = ../secrets.sops.yaml;
      owner = config.users.users.kubernetes.name;
      group = config.users.users.kubernetes.group;
    };
    service-account-signing-key = {
      sopsFile = ../secrets.sops.yaml;
      owner = config.users.users.kubernetes.name;
      group = config.users.users.kubernetes.group;
    };
    apiserver-tls-cert = {
      sopsFile = ../secrets.sops.yaml;
      owner = config.users.users.kubernetes.name;
      group = config.users.users.kubernetes.group;
    };
    apiserver-tls-key = {
      sopsFile = ../secrets.sops.yaml;
      owner = config.users.users.kubernetes.name;
      group = config.users.users.kubernetes.group;
    };
    kube-apiserver-environment = {
      sopsFile = ../secrets.sops.yaml;
      owner = config.users.users.kubernetes.name;
      group = config.users.users.kubernetes.group;
    };
    oidc-client-id = {
      sopsFile = ../secrets.sops.yaml;
      owner = config.users.users.kubernetes.name;
      group = config.users.users.kubernetes.group;
    };
  };
  # systemd.services.kube-apiserver = {
  #   serviceConfig.EnvironmentFile = config.sops.secrets.kube-apiserver-environment.path;
  #   overrideStrategy = "asDropin";
  # };
  services.kubernetes.apiserver = {
    enable = true;
    allowPrivileged = true;
    apiAudiences = controlPlaneEndpoint;
    etcd = {
      caFile = config.sops.secrets.etcd-client-ca.path;
      certFile = config.sops.secrets.etcd-cert.path;
      keyFile = config.sops.secrets.etcd-cert-key.path;
    };
    kubeletClientCertFile = config.sops.secrets.kubelet-client-cert.path;
    kubeletClientKeyFile = config.sops.secrets.kubelet-client-key.path;
    preferredAddressTypes = "InternalIP,ExternalIP,Hostname";
    proxyClientCertFile = config.sops.secrets.proxy-client-cert.path;
    proxyClientKeyFile = config.sops.secrets.proxy-client-key.path;
    serviceAccountIssuer = controlPlaneEndpoint;
    serviceAccountKeyFile = config.sops.secrets.service-account-key.path;
    serviceAccountSigningKeyFile = config.sops.secrets.service-account-signing-key.path;
    serviceClusterIpRange = "10.96.0.0/12,2001:559:1104:fdb::/112";
    tlsCertFile = config.sops.secrets.apiserver-tls-cert.path;
    tlsKeyFile = config.sops.secrets.apiserver-tls-key.path;
    extraOpts = ''
      --enable-bootstrap-token-auth=true
      --oidc-client-id-file=${config.sops.secrets.oidc-client-id.path}
      --oidc-username-claim=email
      --oidc-username-prefix=oidc:
      --oidc-groups-prefix=oidc:
      --oidc-issuer-url=https://kutara-dev.us.auth0.com/
      --oidc-groups-claim=https://kutara/groups
      '';
  };
}
