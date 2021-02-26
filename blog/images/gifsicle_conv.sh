# convert a gif to a looping gif
# gifsicle --colors 256 -O3 --merge cs10.gif cs20.gif cs30.gif cs40.gif cs50.gif cs60.gif -o desktop_term.gif
gifsicle  --delay=100 --loopcount *.gif > anim.gif
# gifsicle -bl --colors 64 -O3 --lossy=80 --scale 0.8 "${1}" -o new-${1}
#gifsicle -bl --colors 64 -O3 --lossy=80 "${1}" -o new-${1}
