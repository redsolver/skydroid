# SkyDroid

SkyDroid is a decentralized Android App Store which offers easy and fast app distribution, discoverability and security through collections, multi-language support, multiple Themes, Search and Filter options, nice error handling and of course a good user experience.

This is the main part of my submission to the [‘Own The Internet’ Hackathon](https://gitcoin.co/hackathon/own-the-internet).

Other parts are the [F-Droid bridge](https://github.com/redsolver/skydroid-fdroid-bridge) and the [Multi-DoH Server](https://github.com/redsolver/multi-doh-server).

## Install + First Steps

1. Visit https://get.skydroid.app on your Android device
2. Open the downloaded APK file and install it
3. Open SkyDroid and go to "Collections"
4. Add some recommended Collections
5. Navigate back to "Apps" and enjoy!

## Video Demo

Here's a little demo of the app and how it works: https://youtu.be/MTSrz3Jb778?t=2461

## Why it's important

Fair and secure app distribution is currently more important than ever. (see the current news about the Apple App Store and Google Play)

SkyDroid aims to fix this problem on Android by making direct app distribution decentralized, convenient to use, affordable and secure.

## Technical Details

### Apps

Every app on SkyDroid is offered through a specific domain. [Handshake Domains](https://handshake.org/) are also fully supported to allow full decentralization.

For example the domain `noteless.redsolver` has a `TXT` record with the following content:

`skydroid-app=1+AADbpx41U1UCRcIhSHvzRAgt8LJYaDlxiLyqHnPj8ckXAA+0a2e07bb2666409ceb6f49072e296d6ca4f2050af098da1cf6d17fd09b49e6cc`

The `skydroid-app=` part tells SkyDroid, that this Domain/Name contains an App.

The `1` is the version of this record format.

The `AADbpx41U1UCRcIhSHvzRAgt8LJYaDlxiLyqHnPj8ckXAA` part is a Skylink (explained in a moment) which points to the metadata file of the app.

The `0a2e07bb2666409ceb6f49072e296d6ca4f2050af098da1cf6d17fd09b49e6cc` part is a sha256 hash of the metadata file to ensure the integrity.

Ok, but what is a Skylink?

A Skylink points to a file on the Sia Skynet. The Sia Skynet is a decentralized CDN and file sharing platform for devs.

It works like this: There are multiple so-called "portals" to the Skynet. (for example https://siasky.net/ or https://www.siacdn.com/, anyone can host one!)

A file which is uploaded to one portal, can be downloaded from any other portal!

This enables fully decentralized file-sharing, because the uploader can use any portal or even directly upload to Skynet and also the user can choose between any of the portals!

Skylinks **must** be used for the metadata files and **can** be used for the app icon, images and the APK files.

Ok, so back to the metadata file!

If you add `noteless.redsolver` in SkyDroid, the apps checks the TXT records of the name like explained above and then downloads the metadata file.

You can choose any Skynet portal of your choice in the SkyDroid settings.

The metadata file is checked against the hash and then the app is shown in the UI.

When a SkyDroid user wants to check for updates of all apps, only the `TXT` records need to be checked.
Only if a new metadata hash is found, the metadata file is downloaded again and applied.

### Collections

A collection in SkyDroid has two main goals:

- Offer a way to discover apps
- Offer a decentralized trust-system for apps

A collection metadata file is loaded exactly like an app metadata file from a domain name (for example `redsolver`),
but it uses `skydroid-collection=` instead in the `TXT` record.

#### Discover Apps

A collection can be made by anyone.

It usually contain's multiple curated Domains/Names from SkyDroid apps which the collection author wants to recommend.

For example, a developer could have a collection of his own apps and some other apps he found and finds nice.

When the SkyDroid user adds the collection, every app in it is added as well.

Some collections are "recommended" by me in the app to get the user started fast, but any collection can be added easily by simply pressing the "Add" button and entering the Domain/Name.

#### Decentralized Trust-System

Collections can also "verify" apps they list. That basically means putting the hash of the app metadata to the name.

This allows security researchers or companies to check the app and mark it as "secure".

This system can also be used for other "verification" to for example check if an app is good or not.

The user can see how many and which collections verified the app in the current state on the "App Page".

### Metadata file examples

The `redsolver` collection metadata file (can be JSON or YAML):

```yaml
title: red's collection
description: This collection contains every app available via SkyDroid that I'm aware of. Some apps are verified.
icon: sia://PAGUwiKmHy_83Att8NssAMj79PF1V8g5x_B2lKyThFhKig

apps:
  - name: noteless.redsolver
    verifiedMetadataHashes:
      [
        f7922a73001a8838db29aa4eea5bc91244c07b65fd9a2f1bad16b6a491308af4,
        4bd9b5ad567784b4defa02a892794b28b4acc0b8e32b6c2e996f955280cfed02,
        f06c6781e7964ab458903594189734216a06f71bc820d2816c3f5347cff72fd5,
        0a2e07bb2666409ceb6f49072e296d6ca4f2050af098da1cf6d17fd09b49e6cc,
      ]
  - name: skydroid.app
    verifiedMetadataHashes:
      [bdcbc30b582a078deaea5c6c12f8d265ca22922e5143bb63974e91871de343fe]

```

The `noteless.redsolver` app metadata file (can be JSON or YAML):

```yaml
categories:
  - Writing
license: MIT
authorName: redsolver
authorEmail: info@redsolver.net
sourceCode: https://github.com/redsolver/noteless
issueTracker: https://github.com/redsolver/noteless/issues
changelog: https://github.com/redsolver/noteless/blob/HEAD/CHANGELOG.md

name: Noteless
packageName: net.redsolver.noteless

icon: https://github.com/redsolver/noteless/raw/master/assets/icon/icon.png

localized:
  en-US:
    description: |-
      Features

      * Markdown-optimized editor with syntax highlighting
      * Supports Github Flavored Markdown, KaTeX and mermaidjs for diagrams
      * Tags for organizing your notes
      * Pin, Star and sort your notes by title or different dates
      * Very themable - dark/light mode and accent color
      * Full-text search
      * File Attachments that can be embedded into a note
      * Multi-Note Editing
      * Slide actions for easier editing
      * Tutorial notes which explain how to use the app
    summary: A markdown note-taking app for mobile devices.
    whatsNew: "First release on SkyDroid, yay!"
    phoneScreenshotsBaseUrl: https://github.com/redsolver/noteless/raw/master/screenshots/
    phoneScreenshots:
      - screen1.png
      - screen2.png
      - screen3.png
      - screen4.png
      - screen5.png
      - screen6.png
      - screen7.png
      - screen8.png
      - screen9.png
      - screen10.png
      - screen11.png
      - screen12.png

builds:
  - versionName: 0.3.2
    versionCode: 32
    sha256: 0a5d15f00554e982e37ed9bdda41d17304e8f056913a8d0921a11d81844578e9
    apkLink: sia://AADTpnQ7qv4aFsJYTJECT8e8428kGgLmwLUWgqdycvquFg
  - versionName: 1.0.0
    versionCode: 100
    sha256: d56dccb20c45e84089560a8d7611eeb9a55a15647fa06aee822364f39c753a69
    apkLink: sia://AABBdXkn8Ogia55qK2vvYLRecYY2U-sKyTx0SoD8c6DOKQ

currentVersionName: 1.0.0
currentVersionCode: 100

added: 1596499200000
lastUpdated: 1596737665000
```

The screenshots and app icon can also be hosted on the Sia Skynet. (Just use `sia://` instead of `https://`, it gets automatically replaced with the selected Skynet Portal)

## How to publish your own app

// Coming soon

## Planned features

- Tools and documentation for app publishers
- Deep Links with `to.skydroid.app` (https://pub.dev/packages/uni_links)
- QR-Code Sharing of Apps
- Some sort of decentralized Rating System (maybe via Mastodon)
- Maybe use [Shizuku service](https://github.com/RikkaApps/Shizuku) like https://github.com/Aefyr/SAI to enable automatic background updates (if verified).
 
Oh, and the app is written in Flutter - making the SkyDroid App Store available on Windows, macOS or Linux is possible.