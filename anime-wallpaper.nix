{ config, pkgs, ... }:
let
  anime-wallpaper = pkgs.writeShellScriptBin "anime-wallpaper" ''
    ANIME_DIR="$HOME/.local/share/anime"
    if [ ! -d "$ANIME_DIR" ]; then
      ${pkgs.git}/bin/git clone https://github.com/ThePrimeagen/anime.git "$ANIME_DIR"
    fi
    VIDEO=$(${pkgs.fd}/bin/fd -e mp4 -e gif . "$ANIME_DIR" | shuf -n1)
    pkill -f "xwinwrap.*mpv" || true
    # get actual screen resolution
    RESOLUTION=$(${pkgs.xorg.xrandr}/bin/xrandr | grep '*' | awk '{print $1}' | head -1)
    exec ${pkgs.xwinwrap}/bin/xwinwrap -g "''${RESOLUTION}+0+0" -ov -ni -s -nf -- \
      ${pkgs.mpv}/bin/mpv -wid WID --loop --no-audio --no-osc \
      --no-osd-bar --profile=low-latency --hwdec=auto \
      --video-unscaled=no --panscan=1.0 "$VIDEO"
  '';
in
{
  environment.systemPackages = [ anime-wallpaper ];
}
