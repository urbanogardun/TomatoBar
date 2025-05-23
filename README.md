<p align="center">
<img src="https://raw.githubusercontent.com/ivoronin/TomatoBar/main/TomatoBar/Assets.xcassets/AppIcon.appiconset/icon_128x128%402x.png" width="128" height="128"/>
<p>
 
<h1 align="center">TomatoBar fork</h1>
<p align="center">
<img src="https://img.shields.io/github/actions/workflow/status/ivoronin/TomatoBar/main.yml?branch=main"/> <img src="https://img.shields.io/github/downloads/ivoronin/TomatoBar/total"/> <img src="https://img.shields.io/github/v/release/ivoronin/TomatoBar?display_name=tag"/> <img src="https://img.shields.io/homebrew/cask/v/tomatobar"/>
</p>

<img
  src="https://github.com/ivoronin/TomatoBar/raw/main/screenshot.png?raw=true"
  alt="Screenshot"
  width="50%"
  align="right"
/>

## Overview
Have you ever heard of Pomodoro? It’s a great technique to help you keep track of time and stay on task during your studies or work. Read more about it on <a href="https://en.wikipedia.org/wiki/Pomodoro_Technique">Wikipedia</a>.

TomatoBar is world's neatest Pomodoro timer for the macOS menu bar. All the essential features are here - configurable
work and rest intervals, optional sounds, discreet actionable notifications, global hotkey.

TomatoBar is fully sandboxed with no entitlements (except for the Apple Events entitlement, used to run the Do Not Disturb toggle shortcut).

## Fork notes
This fork makes a couple additions/modifications:

- Increases the maximum timer duration to 2 hours/120 minutes
- Adds an option to toggle Do Not Disturb automatically using a shortcut. The first time you start the timer you'll be prompted to add the shortcut, it will work fine afterwards (also PRed to https://github.com/ivoronin/TomatoBar/pull/82)
- Adds sound customization: to use, open the sound folder from settings and place audio files named "windup", "ding" or "ticking" in mp3 or m4a/mp4 (aac/alac) format
- Adds a preset selector with 4 presets you can quickly switch between
- Adds a pause button, keyboard shortcut and URL (based on https://github.com/ivoronin/TomatoBar/pull/52)
- Adds a skip button, keyboard shortcut and URL which can skip both work and rest (in addition to the existing rest skip notification)
- Adds an "add a minute" button, keyboard shortcut and URL
- Extends "stop after break" with "work" and "set" options
- Adds a "start with break" option
- Adds a "start timer on launch" option
- Makes numbers in the settings editable (based on https://github.com/ivoronin/TomatoBar/pull/63)
- Displays current interval on the start/stop button when "Stop after" is disabled
- Turns the volume display into a percentage, adds long tap gesture on the percentage to mute/unmute (in addition to the existing double tap reset)
- Adds an option for a full screen mask (taken from https://github.com/ivoronin/TomatoBar/pull/65)
- Doesn't play sounds when volume is set to zero (fixes issues with e.g. multipoint bluetooth headphones)
- Increases the minimum macOS version requirement to Monterey

## Website Blocking
TomatoBar now includes a website blocking feature that helps you stay focused during work sessions. When enabled, it blocks access to distracting websites like social media during your Pomodoro work intervals.

### Features
- Automatically blocks predefined websites during work sessions
- Unblocks websites during rest periods
- Works system-wide across all browsers
- One-time setup - no repeated password prompts
- Customizable block list

### Default Blocked Websites
The following websites are blocked by default:
- twitter.com / x.com
- instagram.com
- youtube.com
- reddit.com
- tiktok.com
- facebook.com

### Setup
1. Enable website blocking in TomatoBar settings
2. On first use, you'll be prompted to set up password-free blocking
3. Enter your admin password once for the initial setup
4. TomatoBar can now block/unblock websites automatically without asking for passwords

### How It Works
TomatoBar uses the system's `/etc/hosts` file to redirect blocked domains to localhost (127.0.0.1), preventing access during work sessions. A helper script with sudoers configuration ensures smooth operation without repeated password prompts.

### Managing Blocked Websites
You can add or remove websites from the block list:
1. Open TomatoBar settings
2. Click "Manage Blocked Websites"
3. Add new sites or remove existing ones
4. Changes take effect on the next work session

## Integration with other tools
### Event log
TomatoBar logs state transitions in JSON format to `~/Library/Containers/com.github.ivoronin.TomatoBar/Data/Library/Caches/TomatoBar.log`. Use this data to analyze your productivity and enrich other data sources.
### Controlling the timer
TomatoBar can be controlled using `tomatobar://` URLs. To start or stop the timer from the command line, use `open tomatobar://startStop`. To pause or resume use `open tomatobar://pauseResume`. To skip use `open tomatobar://skip`. To add a minute use `open tomatobar://addMinute`

## Older versions
Touch bar integration and older macOS versions (earlier than Big Sur) are supported by TomatoBar versions prior to 3.0

## Licenses
 - Timer sounds are licensed from buddhabeats
 - "macos-focus-mode.shortcut" is taken from the <a href="https://github.com/arodik/macos-focus-mode">macos-focus-mode</a> project under the MIT license.
