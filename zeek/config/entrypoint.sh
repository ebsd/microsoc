#!/bin/bash
zeekctl deploy
# infinite loop to prevent container from exiting
while :; do sleep 1s; done
