$(document).ready ->
  app.init()
  maxdown.init(".editor")

# --------------- #

app =
  manifest_url: location.href + 'manifest.webapp'

  init: ->
    @bind_events()
    @beautify_scrollbars()
    @is_installed()

  bind_events: ->
    # Toggle Sidebar Menu
    $(document).on "click", ".btn-menu", (e) ->
      e.preventDefault()
      maxdown.toggle_sidebar()

    # Toggle theme
    $(document).on "click", ".btn-theme", (e) ->
      e.preventDefault()
      $(this).toggleClass "icon-circle-spot icon-circle-blank"
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
          maxdown.cm.focus()
      else
        $('.documents .document').removeClass 'active'
        $(this).parent().addClass 'active'
        maxdown.load_document $(this).parent().data('docid')
        maxdown.cm.focus()

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
      offset = $(".md-header-" + $(this).data("headline")).offset().top + $(".wrapper").scrollTop()
      $(".wrapper").animate
        scrollTop: offset + "px"
      , 500
      # $(".wrapper, .documents").perfectScrollbar('update')

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

    # Keyboard Shortcut Sidebar
    # Mousetrap.bind 'ctrl+m', ->
    #   maxdown.toggle_sidebar()

    # Keyboard Shortcut Fullscreen
    Mousetrap.bind 'ctrl+alt+f', ->
      maxdown.toggle_fullscreen()

    # Keyboard Shortcut New Document
    Mousetrap.bind 'ctrl+alt+n', ->
      maxdown.new_document()

    # Handle install button
    $(document).on "click", ".btn-install", (e) ->
      e.preventDefault()
      app.install()

  install: ->
    install_loc_find = navigator.mozApps.install @manifest_url
    install_loc_find.onsuccess = (data) ->
      # alert "Maxdown was successfully installed on your device."
    install_loc_find.onerror = ->
      alert "There was an error while installing Maxdown on your device: " + install_loc_find.error.name

  is_installed: ->
    if navigator.mozApps
      install_check = navigator.mozApps.checkInstalled @manifest_url
      install_check.onsuccess = ->
        if install_check.result
          # App is installed
          $(".btn-install").hide()
        else
          # App is not installed
          $(".btn-install").show()

  beautify_scrollbars: ->
    # To stuff here
    $(".wrapper, .documents").perfectScrollbar()

  set_cookie: (c_name, value, exdays = 365) ->
    exdate = new Date
    exdate.setDate exdate.getDate() + exdays
    c_value = escape(value) + (if exdays == null then '' else '; expires=' + exdate.toUTCString())
    document.cookie = c_name + '=' + c_value

  get_cookie: (c_name) ->
    i = undefined
    x = undefined
    y = undefined
    ARRcookies = document.cookie.split(';')
    i = 0
    while i < ARRcookies.length
      x = ARRcookies[i].substr(0, ARRcookies[i].indexOf('='))
      y = ARRcookies[i].substr(ARRcookies[i].indexOf('=') + 1)
      x = x.replace(/^\s+|\s+$/g, '')
      if x == c_name
        return unescape(y)
      i++


# ------------------------------ #


maxdown =
  version: '0.2.13 (13. May 2015)'
  cm: ''
  autosave_interval_id: null
  autosave_interval: 5000
  is_saved: true
  current_doc: null
  default_title: 'UntitledDocument'
  default_value: '# Maxdown - Markdown Editor\n\nPlease open a new document or choose an excisting from the sidebar. This document **won\'t be saved**.\n\n---\n\n# Headline 1\n\n## Headline 2\n\n### Headline 3\n\n**strong**\n\n*emphasize*\n\n~~strike-through~~\n\n[Link](http://google.com)\n\n![Image](http://placehold.it/350x150)\n\n---\n\n### Keyboard Shortcuts\n\n- **CTRL+M** -> Toggle sidebar\n- **CTRL+ALT+F** -> Toggle Fullscreen\n- **CTRL+ALT+N** -> New document'

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
      viewportMargin: Infinity
      placeholder: "Start writing here..."
      # extraKeys:
      #   Space: ->
      #     console.log "Test"
    )

    @bind_events()
    @load_documents()

    # Check if theme cookie is set
    if app.get_cookie("maxdown_theme") != undefined
      @set_theme app.get_cookie("maxdown_theme")

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
    $(".btn-fullscreen").toggleClass "icon-fullscreen icon-fullscreen-exit"
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

  toggle_sidebar: ->
    $(".btn-menu").toggleClass "active"
    $(".main-nav").toggleClass "active"
    $(".main-nav").fadeToggle "fast"

  autosave: ->
    if @current_doc != null and @is_saved != true
      # Get current document object
      doc = JSON.parse(localStorage.getItem(@current_doc))
      # Update document
      doc.updated_at = Date.now()
      # Only update document if content has changed
      if doc.content != @cm.getValue()
        # $(".save-info").fadeIn().delay(2000).fadeOut()
        $("head link[rel='shortcut icon']").attr("href", "favicon_save.ico")
        $("head link[rel='icon']").attr("href", "favicon_save.ico")
        setTimeout(->
          $("head link[rel='shortcut icon']").attr("href", "favicon.ico")
          $("head link[rel='icon']").attr("href", "favicon.ico")
        , 2000)
        doc.content = @cm.getValue()
        # Overwrite document object
        localStorage.setItem(doc.id, JSON.stringify(doc))
        console.log 'Document overwritten (Doc-ID: ' + @current_doc + ')'
        @is_saved = true
        window.onbeforeunload = undefined
        @load_documents()

  rename_document: (new_title) ->
    # Get current document object
    doc = JSON.parse(localStorage.getItem(@current_doc))

    # Check if new title is provided and it's different
    if new_title != "" && new_title != doc.title
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
    @cm.setValue ""
    @cm.clearHistory()
    @save_document()
    if $(".btn-menu").hasClass 'active'
      @toggle_sidebar()
    @cm.focus()

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
    # $(".save-info").hide()

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
        if $(this).hasClass("cm-header-4")
          size = "headline-4"
        if $(this).hasClass("cm-header-5")
          size = "headline-5"
        if $(this).hasClass("cm-header-6")
          size = "headline-6"
        $(".documents .document[data-docid='" + id + "'] .headlines").append "<div class='headline " + size + "' data-headline='" + key + "'>" + $(this).text() + "</div>"

  set_font_size: (size) ->
    $('.CodeMirror').css "font-size", size + "px"

  toggle_theme: ->
    $("body").toggleClass("maxdown-light maxdown-dark")
    if @cm.getOption('theme') is 'maxdown-light'
      @cm.setOption('theme', 'maxdown-dark')
      app.set_cookie "maxdown_theme", "maxdown-dark"
    else
      if @cm.getOption('theme') is 'maxdown-dark'
        @cm.setOption('theme', 'maxdown-light')
        app.set_cookie "maxdown_theme", "maxdown-light"

  set_theme: (theme) ->
    @cm.setOption 'theme', theme
    $('body').removeClass("maxdown-light maxdown-dark")
    $('body').addClass(theme)

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
      $(".documents").append('<div class="document" data-docid="' + doc.id + '"><div class="btn-delete-document icon-delete"></div><input type="text" value="' + doc.title + '" /><span>' + doc.title + '.md</span><div class="headlines"></div></div>')

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