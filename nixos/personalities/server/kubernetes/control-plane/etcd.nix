{ config, ... }:
let
  fqdn = "${config.networking.hostName}.${config.networking.domain}";
in
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
    advertiseClientUrls = [ "https://${fqdn}:2379" ];
    certFile = config.sops.secrets.etcd-client-cert.path;
    clientCertAuth = true;
    keyFile = config.sops.secrets.etcd-client-key.path;
    listenClientUrls = [ "https://[::]:2379" ];
    listenPeerUrls = [ "https://[::]:2380" ];
    peerCertFile = config.sops.secrets.etcd-peer-cert.path;
    peerClientCertAuth = true;
    peerKeyFile = config.sops.secrets.etcd-peer-key.path;
    trustedCaFile = config.sops.secrets.etcd-trusted-ca.path;
    peerTrustedCaFile = config.sops.secrets.etcd-peer-trusted-ca.path;
    extraConf = {
      ETCD_AUTO_TLS = "false";
      ETCD_EXPERIMENTAL_INITIAL_CORRUPT_CHECK = "true";
      EXPERIMENTAL_WATCH_PROGRESS_NOTIFY_INTERVAL = "5s";

    };
  };
}
