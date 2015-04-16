# MaxDown - Markdown Editor

Maxdown is a simple markdown editor, using the [codemirror](http://codemirror.net)-engine. Simple design for easy writing without distraction. Markdown will be highlighted as you type. The whole project is [open-source](LICENSE). Feel free to contribute in any way you like.

- [Features](#features)
- [Changelog](#changelog)
- [Known Bugs](#known-bugs)
- [Contribution](#contribution)
- [Online demo](http://opoloo.github.io/maxdown)
- [Download latest release](https://github.com/opoloo/maxdown/releases)
- [Open new issue](https://github.com/opoloo/maxdown/issues/new)
- ~~[Official website](#)~~ (coming soon)

![current version](https://img.shields.io/badge/current_version-0.2.6-brightgreen.svg)
![latest update](https://img.shields.io/badge/latest_update-16._April_2015-brightgreen.svg)
![status](https://img.shields.io/badge/status-stable--beta-yellow.svg)

## Features

- Markdown Highlighting ([GFM-Style](https://help.github.com/articles/github-flavored-markdown/))
- Saving documents to localStorage
- Renaming documents
- Switch themes (light/dark)
- Jump to sections of your document using quick anchor links to headlines
- Fullscreen mode for distraction free environment
- Delete single/all documents from localStorage
- Even more. I don't know. I'm just the developer :) Cheers. RTFM

## Changelog

- v0.2.6 (16. April 2015)
  - Added fullscreen mode
  - Adjusted sidebar styling
  - New editor styles for links/images
  - Increased saving animation duration
- v0.2.5 (15. April 2015)
  - Colorized cursor + selected text
  - Fixed autosave bug
  - Removed top navbar
  - Re-Arranged Sidebar
  - Added FontAwesome (Iconfont)
  - Custom scrollbar styling for documents list
  - Improved saving-animation
  - Added delete all button
- v0.2.4 (14. April 2015)
  - Improved renaming function (checking for empty value)
  - Made sidebar scrollable
- v0.2.3 (9. April 2015)
  - Improved title handling
  - Renaming documents is now possible inside the documents list (click active document once again)
  - Focus-loss fixed when deleting documents
  - Added new formatting styling
  - Updated "New Document" label
- v0.2.2 (8. April 2015)
  - Autosave system tweaks
  - Document list now ordered by "most recent update" DESC
  - Current document will move to the top of the document list (only when edited/saved)
  - Headlines of current document will be shown inside the documents list
  - Clicking on the headlines will scroll to that position inside your current document
  - Changing the document will jump back to top
  - Improved document listing in main-nav
  - Removing documents is now possible (confirmation needed)
- v0.2.1 (7. April 2015)
  - Adding new documents is now possible
  - New documents will be saved automatically
  - Added markdown cheat-sheet on "start screen"
  - Added document renaming
  - Added warning before leaving page without saving
  - Added auto-save (interval: 5s)
- v0.2.0 (26. March 2015)
  - New layout
  - Editor Javascript adjustment
- v0.1.0 (11. March 2015)
  - deprecated
  - some stuff was integrated here. Who knows.

## Known bugs

[Known bugs and other issues can be found here](https://github.com/opoloo/maxdown/issues)

## Contribution

Feel free to fork the code to contribute and/or open issues for bugs/suggestions/whatsoever. Thanks!