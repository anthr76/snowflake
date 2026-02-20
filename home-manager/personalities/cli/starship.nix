{
  programs.starship = {
    enable = true;
    settings = {
      hostname = {
        disabled = true;
      };
      custom.fqdn = {
        command = "hostname -f";
        detect_env_vars = ["SSH_CLIENT"];
        format = "🌐 [$output]($style) ";
        style = "bold green";
      };
      kubernetes = {
        disabled = false;
        contexts = [
          {
            context_pattern = "^teleport\.[\w\.]+-(?P<cluster>[\w-]+)$";
            context_alias = "$cluster";
          }
        ];
      };
    };
  };
  catppuccin.starship.enable = true;
}
