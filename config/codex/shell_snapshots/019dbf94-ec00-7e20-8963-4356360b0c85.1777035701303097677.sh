# Snapshot file
# Unset all aliases to avoid conflicts with functions
# Functions

# setopts 3
set -o braceexpand
set -o hashall
set -o interactive-comments

# aliases 0

# exports 42
declare -x DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus"
declare -x EDITOR="nano"
declare -x GTK_A11Y="none"
declare -x GTK_PATH="/home/pablo/.nix-profile/lib/gtk-2.0:/home/pablo/.nix-profile/lib/gtk-3.0:/home/pablo/.nix-profile/lib/gtk-4.0:/nix/profile/lib/gtk-2.0:/nix/profile/lib/gtk-3.0:/nix/profile/lib/gtk-4.0:/home/pablo/.local/state/nix/profile/lib/gtk-2.0:/home/pablo/.local/state/nix/profile/lib/gtk-3.0:/home/pablo/.local/state/nix/profile/lib/gtk-4.0:/etc/profiles/per-user/pablo/lib/gtk-2.0:/etc/profiles/per-user/pablo/lib/gtk-3.0:/etc/profiles/per-user/pablo/lib/gtk-4.0:/nix/var/nix/profiles/default/lib/gtk-2.0:/nix/var/nix/profiles/default/lib/gtk-3.0:/nix/var/nix/profiles/default/lib/gtk-4.0:/run/current-system/sw/lib/gtk-2.0:/run/current-system/sw/lib/gtk-3.0:/run/current-system/sw/lib/gtk-4.0"
declare -x HOME="/home/pablo"
declare -x INFOPATH="/home/pablo/.nix-profile/info:/home/pablo/.nix-profile/share/info:/nix/profile/info:/nix/profile/share/info:/home/pablo/.local/state/nix/profile/info:/home/pablo/.local/state/nix/profile/share/info:/etc/profiles/per-user/pablo/info:/etc/profiles/per-user/pablo/share/info:/nix/var/nix/profiles/default/info:/nix/var/nix/profiles/default/share/info:/run/current-system/sw/info:/run/current-system/sw/share/info"
declare -x LANG="en_US.UTF-8"
declare -x LESSKEYIN_SYSTEM="/nix/store/gk8wmxf0x2garvvznr619wagr0iv87pj-lessconfig"
declare -x LIBEXEC_PATH="/home/pablo/.nix-profile/libexec:/nix/profile/libexec:/home/pablo/.local/state/nix/profile/libexec:/etc/profiles/per-user/pablo/libexec:/nix/var/nix/profiles/default/libexec:/run/current-system/sw/libexec"
declare -x LOCALE_ARCHIVE="/run/current-system/sw/lib/locale/locale-archive"
declare -x LOCALE_ARCHIVE_2_27="/nix/store/c12k1c5c5w4yl2kndaijdhzza47h4vcg-glibc-locales-2.40-218/lib/locale/locale-archive"
declare -x LOGNAME="pablo"
declare -x LS_COLORS="rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=00:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.7z=01;31:*.ace=01;31:*.alz=01;31:*.apk=01;31:*.arc=01;31:*.arj=01;31:*.bz=01;31:*.bz2=01;31:*.cab=01;31:*.cpio=01;31:*.crate=01;31:*.deb=01;31:*.drpm=01;31:*.dwm=01;31:*.dz=01;31:*.ear=01;31:*.egg=01;31:*.esd=01;31:*.gz=01;31:*.jar=01;31:*.lha=01;31:*.lrz=01;31:*.lz=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.lzo=01;31:*.pyz=01;31:*.rar=01;31:*.rpm=01;31:*.rz=01;31:*.sar=01;31:*.swm=01;31:*.t7z=01;31:*.tar=01;31:*.taz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tgz=01;31:*.tlz=01;31:*.txz=01;31:*.tz=01;31:*.tzo=01;31:*.tzst=01;31:*.udeb=01;31:*.war=01;31:*.whl=01;31:*.wim=01;31:*.xz=01;31:*.z=01;31:*.zip=01;31:*.zoo=01;31:*.zst=01;31:*.avif=01;35:*.jpg=01;35:*.jpeg=01;35:*.jxl=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.webp=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:*~=00;90:*#=00;90:*.bak=00;90:*.crdownload=00;90:*.dpkg-dist=00;90:*.dpkg-new=00;90:*.dpkg-old=00;90:*.dpkg-tmp=00;90:*.old=00;90:*.orig=00;90:*.part=00;90:*.rej=00;90:*.rpmnew=00;90:*.rpmorig=00;90:*.rpmsave=00;90:*.swp=00;90:*.tmp=00;90:*.ucf-dist=00;90:*.ucf-new=00;90:*.ucf-old=00;90:"
declare -x NIXPKGS_CONFIG="/etc/nix/nixpkgs-config.nix"
declare -x NIX_PATH="nixpkgs=flake:nixpkgs:/nix/var/nix/profiles/per-user/root/channels"
declare -x NIX_PROFILES="/run/current-system/sw /nix/var/nix/profiles/default /etc/profiles/per-user/pablo /home/pablo/.local/state/nix/profile /nix/profile /home/pablo/.nix-profile"
declare -x NIX_USER_PROFILE_DIR="/nix/var/nix/profiles/per-user/pablo"
declare -x NO_AT_BRIDGE="1"
declare -x PAGER="less"
declare -x PATH="/home/pablo/.codex/tmp/arg0/codex-arg09nifVe:/run/wrappers/bin:/home/pablo/.nix-profile/bin:/nix/profile/bin:/home/pablo/.local/state/nix/profile/bin:/etc/profiles/per-user/pablo/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
declare -x QTWEBKIT_PLUGIN_PATH="/home/pablo/.nix-profile/lib/mozilla/plugins/:/nix/profile/lib/mozilla/plugins/:/home/pablo/.local/state/nix/profile/lib/mozilla/plugins/:/etc/profiles/per-user/pablo/lib/mozilla/plugins/:/nix/var/nix/profiles/default/lib/mozilla/plugins/:/run/current-system/sw/lib/mozilla/plugins/"
declare -x SHELL="/run/current-system/sw/bin/bash"
declare -x SHLVL="2"
declare -x SSH_ASKPASS="/nix/store/fznmvk733r37r1v05mc4791k54avxma8-x11-ssh-askpass-1.2.4.1/libexec/x11-ssh-askpass"
declare -x SSH_AUTH_SOCK="/run/user/1000/ssh-agent"
declare -x SSH_CLIENT="192.168.122.1 47382 22"
declare -x SSH_CONNECTION="192.168.122.1 47382 192.168.122.167 22"
declare -x SSH_TTY="/dev/pts/0"
declare -x TERM="xterm-256color"
declare -x TERMINFO_DIRS="/home/pablo/.nix-profile/share/terminfo:/nix/profile/share/terminfo:/home/pablo/.local/state/nix/profile/share/terminfo:/etc/profiles/per-user/pablo/share/terminfo:/nix/var/nix/profiles/default/share/terminfo:/run/current-system/sw/share/terminfo"
declare -x TZDIR="/etc/zoneinfo"
declare -x USER="pablo"
declare -x XCURSOR_PATH="/home/pablo/.icons:/home/pablo/.local/share/icons:/home/pablo/.nix-profile/share/icons:/home/pablo/.nix-profile/share/pixmaps:/nix/profile/share/icons:/nix/profile/share/pixmaps:/home/pablo/.local/state/nix/profile/share/icons:/home/pablo/.local/state/nix/profile/share/pixmaps:/etc/profiles/per-user/pablo/share/icons:/etc/profiles/per-user/pablo/share/pixmaps:/nix/var/nix/profiles/default/share/icons:/nix/var/nix/profiles/default/share/pixmaps:/run/current-system/sw/share/icons:/run/current-system/sw/share/pixmaps"
declare -x XDG_CONFIG_DIRS="/etc/xdg:/home/pablo/.nix-profile/etc/xdg:/nix/profile/etc/xdg:/home/pablo/.local/state/nix/profile/etc/xdg:/etc/profiles/per-user/pablo/etc/xdg:/nix/var/nix/profiles/default/etc/xdg:/run/current-system/sw/etc/xdg"
declare -x XDG_DATA_DIRS="/nix/store/89c59k6w414nny60p90k6i6hlc06aax0-desktops/share:/home/pablo/.nix-profile/share:/nix/profile/share:/home/pablo/.local/state/nix/profile/share:/etc/profiles/per-user/pablo/share:/nix/var/nix/profiles/default/share:/run/current-system/sw/share"
declare -x XDG_RUNTIME_DIR="/run/user/1000"
declare -x XDG_SESSION_CLASS="user"
declare -x XDG_SESSION_ID="1"
declare -x XDG_SESSION_TYPE="tty"
declare -x __ETC_PROFILE_DONE="1"
declare -x __HM_SESS_VARS_SOURCED="1"
declare -x __NIXOS_SET_ENVIRONMENT_DONE="1"
