--tell application "iTunes" to play
--This is optional; if you want to play music when you are in the proximity of your computer, it will play ur music. Just delete the 2 minus signs in front of '--tell application "iTunes" to play'

tell application "System Events"
tell security preferences
set require password to wake to false
end tell
end tell

tell application "ScreenSaverEngine" to quit
