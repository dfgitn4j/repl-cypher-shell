# convert a gif to a looping gif
gifsicle -bl --colors 64 -O3 --lossy=80 --scale 0.8 "${1}" -o new-${1}
#gifsicle -bl --colors 64 -O3 --lossy=80 "${1}" -o new-${1}
