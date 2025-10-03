{ config, pkgs, ... }:

let
  anime-wallpaper = pkgs.writeShellScriptBin "anime-wallpaper" ''
    ANIME_DIR="$HOME/.local/share/anime"
    
    # clone if not exists
    if [ ! -d "$ANIME_DIR" ]; then
      ${pkgs.git}/bin/git clone https://github.com/ThePrimeagen/anime.git "$ANIME_DIR"
    fi
    
    # pick random video
    VIDEO=$(${pkgs.fd}/bin/fd -e mp4 -e gif . "$ANIME_DIR" | shuf -n1)
    
    # kill existing wallpaper
    pkill -f "xwinwrap.*mpv" || true
    
    # launch video wallpaper
    exec ${pkgs.xwinwrap}/bin/xwinwrap -g 1920x1080+0+0 -ov -ni -s -nf -- \
      ${pkgs.mpv}/bin/mpv -wid WID --loop --no-audio --no-osc \
      --no-osd-bar --profile=low-latency --hwdec=auto "$VIDEO"
  '';
in
{
  environment.systemPackages = [ anime-wallpaper ];
}
