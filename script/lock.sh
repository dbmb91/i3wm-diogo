#!/bin/bash

#i3lock -B 20 

##SCREEN_RESOLUTION="$(xdpyinfo | grep dimensions | cut -d' ' -f7)"
##BGCOLOR="0,0,0"
##convert "~/Imagens/Wallpapers/Skull-18.png" -gravity Center -background $BGCOLOR -extent "$SCREEN_RESOLUTION" RGB:- | i3lock --raw "$SCREEN_RESOLUTION":rgb -c $BGCOLOR -i /dev/stdin

## Buscando imagem para tela de bloqueio do i3lock
i3lock -i ~/Imagens/Wallpapers/Skull-23.png