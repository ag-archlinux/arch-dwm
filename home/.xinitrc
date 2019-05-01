#!/bin/bash

export EDITOR=nvim
export TERMINAL=st

xrdb ~/.Xresources

# start window manager
exec bspwm