# MaxDown - Markdown Editor

Maxdown is a simple markdown editor, using the [codemirror](http://codemirror.net)-engine. You can find a [preview here](http://opoloo.github.io/maxdown).

![current version](https://img.shields.io/badge/current_version-0.2.3_beta-brightgreen.svg)

![status](https://img.shields.io/badge/status-stable-brightgreen.svg)

### Features

- Writing (markdown highlighting)
- Saving documents to localStorage
- Renaming documents
- Switch themes (light/dark)
- Jump to sections of your document using quick anchor links to headlines
- Even more. I don't know. I'm just the developer :) Cheers. RTFM

### Changelog

- v0.2.3 (9. April 2015)
  - Improved title handling
  - Renaming documents is now possible inside the documents list (click active document once again)
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

### Known bugs

- Losing focus of current document when deleting another one
- No "unsafed changes warning" when switching documents
- `is_saved` will be set to `false` when switching documents

[See all issues](https://github.com/opoloo/maxdown/issues)