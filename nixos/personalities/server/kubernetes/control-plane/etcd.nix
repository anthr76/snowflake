{ config, ... }:
{
  sops.secrets = {
    etcd-client-cert = {
      sopsFile = ../secrets.sops.yaml;
      owner = config.users.users.etcd.name;
      group = config.users.users.etcd.group;
    };
    etcd-client-key = {
      sopsFile = ../secrets.sops.yaml;
      owner = config.users.users.etcd.name;
      group = config.users.users.etcd.group;
    };
    etcd-peer-cert = {
      sopsFile = ../secrets.sops.yaml;
      owner = config.users.users.etcd.name;
      group = config.users.users.etcd.group;
    };
    etcd-peer-key = {
      sopsFile = ../secrets.sops.yaml;
      owner = config.users.users.etcd.name;
      group = config.users.users.etcd.group;
    };
    etcd-trusted-ca = {
      sopsFile = ../secrets.sops.yaml;
      owner = config.users.users.etcd.name;
      group = config.users.users.etcd.group;
    };
  };
  services.etcd = {
    enable = true;
    certFile = config.sops.secrets.etcd-client-cert.path;
    clientCertAuth = true;
    keyFile = config.sops.secrets.etcd-client-key.path;
    listenPeerUrls = [ "https://[::]:2380" ];
    peerCertFile = config.sops.secrets.etcd-peer-cert.path;
    peerClientCertAuth = true;
    peerKeyFile = config.sops.secrets.etcd-peer-key.path;
    trustedCaFile = config.sops.secrets.etcd-trusted-ca.path;
  };
}
