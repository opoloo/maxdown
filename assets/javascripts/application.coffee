$(document).ready ->
  cache.init()
  app.init()
  dropbox.init()
  maxdown.init(".editor")

# --------------- #

dropbox =
  app_key: "qf2b38mqupuufxi"
  client: ""
  current_user: ""

  init: ->
    @client = new Dropbox.Client key: @app_key
    @authenticate()

  synch: ->
    documents = []
    keys = Object.keys localStorage
    i = 0

    # Read all saved documents from localStorage
    while i < keys.length
      # Only add documents from localStorage (not settings)
      if keys[i].includes('maxdown:document:')
        documents.push JSON.parse(localStorage.getItem(keys[i]))
      i++

    #Synch with Dropbox Account
    for doc of documents
      doc = documents[doc]
      @client.writeFile doc.title + ".md", doc.content, (error, stat) ->
        if error
          console.log error
          return false
        console.log "Dropbox-Synch: File (" + doc.id + ") saved as revision " + stat.versionTag


  logged_in: ->
    $(".btn-dropbox-oauth").hide()
    $(".dropbox-oauth").html("Logged in as: " + @current_user.name + " (" + @current_user.email + ")")
    test = setInterval(->
      dropbox.synch()
    , 30000)

  get_user_info: ->
    @client.getAccountInfo (error, accountInfo) ->
      if error
        console.log error
        return false
      dropbox.current_user = accountInfo
      dropbox.logged_in()
      return

  authenticate: ->
    @client.authenticate {interactive: false}, (error, client) ->
      if error
        console.log error
        return false
      if client.isAuthenticated()
        dropbox.get_user_info()
      else
        button = document.querySelector('.btn-dropbox-oauth')
        button.addEventListener 'click', ->
          client.authenticate (error, client) ->
            if error
              console.log error
              return false
            dropbox.get_user_info()

app =
  manifest_url: location.href + 'manifest.webapp'

  init: ->
    @polyfills()
    @bind_events()
    @beautify_scrollbars()
    @is_installed()
    navbar.init('.app-bar', '.manage')
    tabs.init()

  bind_events: ->
    # Toggle Sidebar Menu
    $(document).on "click", ".btn-menu", (e) ->
      e.preventDefault()
      maxdown.toggle_sidebar()

    # Toggle Manage section
    $(document).on "click", ".btn-manage", (e) ->
      $(".wrapper").fadeToggle("fast")

    # Toggle theme
    $(document).on "click", ".btn-theme", (e) ->
      e.preventDefault()
      $(this).toggleClass "icon-radio-button-on icon-radio-button-off"
      maxdown.toggle_theme()

    # Handle theme switches
    $(document).on "change", ".theme-radio input", (e) ->
      e.preventDefault()
      maxdown.set_theme $(this).data('theme')

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
    Mousetrap.bind 'ctrl+m', ->
      maxdown.toggle_sidebar()

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

  polyfills: ->
    if !String::includes
      String::includes = ->
        'use strict'
        String::indexOf.apply(this, arguments) != -1

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


cache =
  app_cache: window.applicationCache

  init: ->
    @bind_events()

  bind_events: ->
    # Check if a new cache is available on page load.
    window.applicationCache.addEventListener 'updateready', ((e) ->
      if window.applicationCache.status == window.applicationCache.UPDATEREADY
        # Browser downloaded a new app cache.
        if confirm('A new version of this site is available. Load it?')
          window.location.reload()
      else
        # Manifest didn't changed. Nothing new to server.
      return
    ), false

    # Fired after the first cache of the manifest.
    @app_cache.addEventListener 'cached', @handle_cache_event, false

    # Checking for an update. Always the first event fired in the sequence.
    @app_cache.addEventListener 'checking', @handle_cache_event, false

    # An update was found. The browser is fetching resources.
    @app_cache.addEventListener 'downloading', @handle_cache_event, false

    # The manifest returns 404 or 410, the download failed,
    # or the manifest changed while the download was in progress.
    @app_cache.addEventListener 'error', @handle_cache_error, false

    # Fired after the first download of the manifest.
    @app_cache.addEventListener 'noupdate', @handle_cache_event, false

    # Fired if the manifest file returns a 404 or 410.
    # This results in the application cache being deleted.
    @app_cache.addEventListener 'obsolete', @handle_cache_event, false

    # Fired for each resource listed in the manifest as it is being fetched.
    @app_cache.addEventListener 'progress', @handle_cache_event, false

    # Fired when the manifest resources have been newly redownloaded.
    @app_cache.addEventListener 'updateready', @handle_cache_event, false

  handle_cache_event: (e) ->
    console.log 'App-Cache: ' + e.type

  handle_cache_error: (e) ->
    console.log 'App-Cache Error: Cache failed to update!'



# ------------------------------ #


maxdown =
  version: '0.3.4 (22. June 2015)'
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

    @get_version()

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
      extraKeys:
        "Ctrl-M": ->
          maxdown.toggle_sidebar()
        "Ctrl-Alt-F": ->
          maxdown.toggle_fullscreen()
        "Ctrl-Alt-N": ->
          maxdown.new_document()
    )

    @bind_events()
    @load_documents()

    # Check if theme cookie is set
    if app.get_cookie("maxdown_theme") is undefined
      app.set_cookie("maxdown_theme", "maxdown-light")
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

  get_version: ->
    $(".current-version").html @version

  get_remote_version: ->
    # Todo: Get version of online stable version

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
    # Only clear docs, not settings
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
    $(".write").toggleClass("maxdown-light maxdown-dark")
    if @cm.getOption('theme') is 'maxdown-light'
      @cm.setOption('theme', 'maxdown-dark')
      app.set_cookie "maxdown_theme", "maxdown-dark"
    else
      if @cm.getOption('theme') is 'maxdown-dark'
        @cm.setOption('theme', 'maxdown-light')
        app.set_cookie "maxdown_theme", "maxdown-light"

  set_theme: (theme) ->
    @cm.setOption 'theme', theme
    $('.write').removeClass("maxdown-light maxdown-dark")
    $('.write').addClass(theme)
    $(".theme-radio input[data-theme='"+theme+"']").prop('checked', true)
    app.set_cookie 'maxdown_theme', theme

  load_documents: ->
    documents = []
    keys = Object.keys localStorage
    i = 0

    # Read all saved documents from localStorage
    while i < keys.length
      # Only add documents from localStorage (not settings)
      if keys[i].includes('maxdown:document:')
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
    doc_id = 'maxdown:document:' + @generate_uuid()

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


# 
# Navbar
# Handles sticky navbar
#

navbar =
  c: ""                 # Container object
  n: ""                 # Navbar object
  n_height: 0           # Navbar height
  n_top: 0              # Navbar offset top
  d_height: 0           # Document height
  w_height: 0           # Window height
  w_scroll_current: 0   # Current scroll position
  w_scroll_before: 0    # Most recent scroll position
  w_scroll_diff: 0      # Difference between current and most recent scroll position

  init: (selector, container) ->
    @n = document.querySelector(selector)
    @c = document.querySelector(container)
    @bind_events()

  bind_events: ->
    # $(window).scroll (e) ->
    @c.addEventListener 'scroll', (event) ->
      navbar.scroll()

  scroll: ->
    @n_height = @n.offsetHeight
    # @d_height = document.body.offsetHeight
    @d_height = @c.scrollHeight
    @w_height = window.innerHeight
    # @w_scroll_current = window.pageYOffset
    @w_scroll_current = @c.scrollTop
    @w_scroll_diff = @w_scroll_before - @w_scroll_current
    @n_top = parseInt(window.getComputedStyle(@n).getPropertyValue('top')) + @w_scroll_diff

    if @w_scroll_current <= 0
      @n.style.top = '0px'
    else if @w_scroll_diff > 0
      @n.style.top = (if @n_top > 0 then 0 else @n_top) + 'px'
    else if @w_scroll_diff < 0
      if @w_scroll_current + @w_height >= @d_height - @n_height
        @n.style.top = (if (@n_top = @w_scroll_current + @w_height - @d_height) < 0 then @n_top else 0) + 'px'
      else
        @n.style.top = (if Math.abs(@n_top) > @n_height then -@n_height else @n_top) + 'px'

    @w_scroll_before = @w_scroll_current

#
# Tab management
#

tabs =
  init: ->
    @bind_events()

  bind_events: ->
    $(document).on 'click', '.tab-link', (e) ->
      e.preventDefault()
      tabs.switch_tab $(this).data('tab')

  switch_tab: (tab) ->
    unless $(".tab.active").data("tab") is tab
      $(".tab-link").removeClass 'tab-active'
      $(".tab-link[data-tab='" + tab + "']").addClass 'tab-active'
      $(".tab").removeClass 'active'
      $(".tab[data-tab='" + tab + "']").addClass 'active'
      $(".manage").scrollTop(0)