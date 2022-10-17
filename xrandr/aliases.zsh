## Fix laptop monitor resolution
alias fixmon="xrandr --output eDP-1 --mode 1920x1080 --auto"

## Only shows external monitor
alias 1mon="xrandr --output DP-2 --primary --mode 5120x2160 --rate 60.00 --output eDP-1 --off"

## Both monitor active
alias 2mon="xrandr --output DP-2 --primary --mode 5120x2160 --rate 60.00 --output eDP-1  --mode 1920x1080 --auto --right-of DP-2"