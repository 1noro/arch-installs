#!/bin/bash
# (no funciona correctamente)
for D in */; do
    if [[ $(git -C $D fetch) ]]; then
        git -C $D pull -q
        echo -e "Package \e[92m\e[1m$D\e[0m pulled. It needs to be updated."
    else
        echo -e "Package $D no needs to be updated."
    fi
done
echo -e "Make sure \e[91m\e[1myou have the system updated\e[0m before re-compiling the packages."
