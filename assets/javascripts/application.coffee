$(document).ready ->
  app.init()
  maxdown.init(".editor")

# --------------- #

app =
  init: ->
    @bind_events()

  bind_events: ->
    # Toggle Sidebar Menu
    $(document).on "click", ".btn-menu", (e) ->
      e.preventDefault()
      $(this).toggleClass "active"
      $(".main-nav").toggleClass "active"
      $(".main-nav").fadeToggle "fast"

    # Toggle theme
    $(document).on "click", ".btn-theme", (e) ->
      e.preventDefault()
      $(this).toggleClass "fontawesome-circle fontawesome-circle-blank"
      maxdown.toggle_theme()

    # Create new document button
    $(document).on "click", ".btn-new-document", (e) ->
      e.preventDefault()
      maxdown.new_document()

    # Handle document buttons
    $(document).on "click", ".document span", (e) ->
      e.preventDefault()
      # Check if current document is saved
      if maxdown.current_doc != null && maxdown.is_saved == false
        if confirm "You have unsaved changes in your document. Would you like to switch the document anyway?"
          $('.documents .document').removeClass 'active'
          $(this).parent().addClass 'active'
          maxdown.load_document $(this).parent().data('docid')
      else
        $('.documents .document').removeClass 'active'
        $(this).parent().addClass 'active'
        maxdown.load_document $(this).parent().data('docid')

    # Handle title saving
    $(document).on "blur", ".document.active input", (e) ->
      maxdown.rename_document $(this).val()
      $(this).hide()

    # Handle key inputs
    $(document).on "keydown", ".document.active input", (e) ->
      key = e.keyCode || e.which
      if key is 13
        maxdown.rename_document $(this).val()
        $(this).hide()

    # Handle headline clicks (anchor scrolling)
    $(document).on "click", ".headline", (e) ->
      e.preventDefault()
      # Close sidebar
      $(".main-nav, .btn-menu").toggleClass 'active'
      $(".main-nav").fadeOut 'fast'
      # Scroll to headline
      $("html,body").animate
        scrollTop: $(".md-header-" + $(this).data("headline")).offset().top - $(".navbar").height() + "px"
      , 500

    # Handle document delete button
    $(document).on "click", ".btn-delete-document", (e) ->
      e.preventDefault()
      if confirm("Are you sure?")
        doc_id = $(this).parent().data "docid"
        maxdown.delete_document doc_id

    # Handle delete all button
    $(document).on "click", ".btn-delete-all", (e) ->
      e.preventDefault()
      if confirm("Are you sure? All documents will be deleted!")
        maxdown.delete_all_documents()

    # Handle active document click (renaming)
    $(document).on "click", ".documents .document.active > span", (e) ->
      e.preventDefault()
      $("input", $(this).parent()).show().focus().select()

    # Handle Fullscreen button
    $(document).on "click", ".btn-fullscreen", (e) ->
      e.preventDefault()
      maxdown.toggle_fullscreen()


# ------------------------------ #


maxdown =
  version: '0.2.6 (16. April 2015)'
  cm: ''
  autosave_interval_id: null
  autosave_interval: 5000
  is_saved: true
  current_doc: null
  default_title: 'UntitledDocument'
  default_value: '# Maxdown - Markdown Editor\n\nPlease open a new document or choose an excisting from the sidebar. This document **won\'t be saved**.\n\n---\n\n# Headline 1\n\n## Headline 2\n\n### Headline 3\n\n**strong**\n\n*emphasize*\n\n~~strike-through~~\n\n[Link](http://google.com)\n\n![Image](http://placehold.it/350x150)'

  init: (selector, t = 'maxdown-light') ->
    console.log '/*'
    console.log ' * Maxdown - Markdown Editor'
    console.log ' * Version: ' + @version
    console.log ' * Author: Max Boll'
    console.log ' * Website: http://opoloo.com'
    console.log ' * License: MIT'
    console.log ' */'

    @cm = CodeMirror($(selector)[0],
      value: @default_value
      mode:
        name: 'gfm'
        highlightFormatting: true
      lineWrapping: true
      tabSize: 2
      theme: t
    )

    @bind_events()
    @load_documents()

    # Checks if fullscreen mode is rather supported or not
    unless @fullscreen_possible
      # If fullscreen mode is not supported, hide the icon
      $(".actions .btn-fullscreen").hide()


    @autosave_interval_id = setInterval(->
      maxdown.autosave()
    , maxdown.autosave_interval)

  bind_events: ->
    @cm.on "change", (cm, change) ->
      if maxdown.current_doc != null
        maxdown.is_saved = false
        window.onbeforeunload = ->
          return "You have unsaved changes in your document."

  fullscreen_possible: ->
    # Detects if fullscreen is supported/enabled in current browser
    if document.fullscreenEnabled or document.webkitFullscreenEnabled or document.mozFullScreenEnabled or document.msFullscreenEnabled
      return true
    else
      return false

  toggle_fullscreen: ->
    if @is_fullscreen()
      if document.exitFullscreen
        document.exitFullscreen()
      else if document.webkitExitFullscreen
        document.webkitExitFullscreen()
      else if document.mozCancelFullScreen
        document.mozCancelFullScreen()
      else if document.msExitFullscreen
        document.msExitFullscreen()
      console.log 'Fullscreen-Mode disabled'
    else
      i = document.querySelector("html");
      if i.requestFullscreen
        i.requestFullscreen()
      else if i.webkitRequestFullscreen
        i.webkitRequestFullscreen()
      else if i.mozRequestFullScreen
        i.mozRequestFullScreen()
      else if i.msRequestFullscreen
        i.msRequestFullscreen()
      console.log 'Fullscreen-Mode enabled'

  is_fullscreen: ->
    # Check if fullscreen mode is currently active
    if document.fullscreenElement or document.webkitFullscreenElement or document.mozFullScreenElement or document.msFullscreenElement
      return true
    else
      return false

  autosave: ->
    if @current_doc != null and @is_saved != true
      # Get current document object
      doc = JSON.parse(localStorage.getItem(@current_doc))
      # Update document
      doc.updated_at = Date.now()
      # Only update document if content has changed
      if doc.content != @cm.getValue()
        $(".save-info").fadeIn()
        doc.content = @cm.getValue()
        # Overwrite document object
        localStorage.setItem(doc.id, JSON.stringify(doc))
        console.log 'Document overwritten (Doc-ID: ' + @current_doc + ')'
        @is_saved = true
        window.onbeforeunload = undefined
        @load_documents()
        $(".save-info").delay(500).fadeOut()

  rename_document: (new_title) ->
    # Get current document object
    doc = JSON.parse(localStorage.getItem(@current_doc))

    # Check if new title is provided
    unless new_title == ""
      # Rename title
      doc.title = new_title
      doc.updated_at = Date.now()

      # Overwrite document object
      localStorage.setItem(doc.id, JSON.stringify(doc))

    # Show new title
    @load_documents()

    console.log 'Renamed document (Doc-ID: ' + maxdown.current_doc + ')'

  new_document: ->
    # Clear editor
    @cm.setValue "# UntitledDocument\n\nWelcome to your new document. Start writing your awesome story now."
    @cm.clearHistory()
    @save_document()

  delete_document: (id) ->
    if @current_doc is id
      @current_doc = null
    localStorage.removeItem id
    @load_documents()
    console.log "Deleted document (Doc-ID: " + id + ")"

  delete_all_documents: ->
    @current_doc = null
    localStorage.clear()
    @load_documents()
    console.log "Deleted all documents"

  load_document: (id) ->
    doc = JSON.parse(localStorage.getItem(id))
    $(".title span").html doc.title
    $(".title input").val doc.title
    @cm.setValue(doc.content)
    @current_doc = doc.id

    # Get headline
    @get_headlines(id)

    # Go back to top
    $("html,body").scrollTop(0)

    # Fix save info bug
    @is_saved = true
    $(".save-info").hide()

  get_headlines: (id) ->
    $(".documents .document[data-docid='" + id + "'] .headlines").html("")
    $.each $(".cm-header"), (key, val) ->
      if !$(this).hasClass("cm-formatting")
        $(this).addClass "md-header-" + key
        size = "headline-1"
        if $(this).hasClass("cm-header-1")
          size = "headline-1"
        if $(this).hasClass("cm-header-2")
          size = "headline-2"
        if $(this).hasClass("cm-header-3")
          size = "headline-3"
        $(".documents .document[data-docid='" + id + "'] .headlines").append "<div class='headline " + size + "' data-headline='" + key + "'>" + $(this).text() + "</div>"

  set_font_size: (size) ->
    $('.CodeMirror').css "font-size", size + "px"

  toggle_theme: ->
    $("body").toggleClass("maxdown-light maxdown-dark")
    if @cm.getOption('theme') is 'maxdown-light'
      @cm.setOption('theme', 'maxdown-dark')
    else
      if @cm.getOption('theme') is 'maxdown-dark'
        @cm.setOption('theme', 'maxdown-light')

  set_theme: (theme) ->
    @cm.setOption 'theme', theme
    $('body, #editor').removeClass("maxdown-light")
    $('body, #editor').removeClass("maxdown-dark")
    $('body, #editor').addClass(theme)

  load_documents: ->
    documents = []
    keys = Object.keys localStorage
    i = 0

    # Read all saved documents from localStorage
    while i < keys.length
      documents.push JSON.parse(localStorage.getItem(keys[i]))
      i++

    # Sort documents (updated_at DESC)
    documents.sort (a, b) ->
      a.updated_at - b.updated_at
    documents.reverse()

    # Add documents to document-list
    $(".documents").html("")
    for doc of documents
      doc = documents[doc]
      $(".documents").append('<div class="document" data-docid="' + doc.id + '"><div class="btn-delete-document fontawesome-trash"></div><input type="text" value="' + doc.title + '" /><span>' + doc.title + '.md</span><div class="headlines"></div></div>')

    if @current_doc != null
      # Update active document
      $(".documents .document[data-docid='" + @current_doc + "']").addClass 'active'

      # Update headlines of active document
      @get_headlines(@current_doc)

      # Get current doc info
      doc = JSON.parse(localStorage.getItem(@current_doc))

      # Set title
      $('.title span').html doc.title
      $('.title input').val doc.title
    else
      $(".title span").html 'Maxdown - Markdown Editor'
      $(".title input").val 'Maxdown - Markdown Editor'
      @cm.setValue @default_value

  save_document: ->
    # Set document title
    docname = @default_title

    # Get unique file ID
    doc_id = @generate_uuid()

    # Create new file object
    doc =
      id: doc_id
      created_at: Date.now()
      updated_at: Date.now()
      title: docname
      content: @cm.getValue()

    # Save file object to localStorage in JSON format
    localStorage.setItem(doc_id, JSON.stringify(doc))
    console.log 'New document created. (Doc-ID: ' + doc_id + ')'

    # Update current doc ID
    @current_doc = doc_id

    # Update documents list
    @load_documents()

  generate_uuid: ->
    chars = '0123456789abcdef'.split('')
    uuid = []
    rnd = Math.random
    r = undefined
    i = 0
    uuid[8] = uuid[13] = uuid[18] = uuid[23] = '-'
    uuid[14] = '4' # version 4
    while i < 36
      if !uuid[i]
        r = 0 | rnd() * 16
        uuid[i] = chars[if i == 19 then r & 0x3 | 0x8 else r & 0xf]
      i++
    uuid.join ''