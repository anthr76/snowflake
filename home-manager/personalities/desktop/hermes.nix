{inputs, ...}: {
  imports = [inputs.hermes-agent.homeManagerModules.default];

  programs.hermes-agent.desktop.enable = true;
}
