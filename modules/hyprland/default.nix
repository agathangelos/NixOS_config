{ ... }:

{
  imports = [ ../programs/waybar.nix ];

  programs.hyprland.enable = true;

  security.pam.services.swaylock = {
    text = ''
      auth include login
    '';
  };
}
