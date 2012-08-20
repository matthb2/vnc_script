#!/bin/bash

ps -U $( whoami ) f | grep Xvnc | cut -f 3 -d ':' | cut -f 1 -d ' '
