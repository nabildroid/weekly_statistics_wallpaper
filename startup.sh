#!/bin/bash



cd server

npm run start &

cd ../

export DISPLAY=:1
Xvfb :1 -screen 0 1024x768x16 &
sleep 10


./flutter/weekly_statistics_wallpaper

