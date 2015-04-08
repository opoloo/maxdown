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
      $(this).toggleClass("active")
      $(".main-nav").toggleClass("active")
      $(".actions, .title").fadeToggle()

    # Toggle theme
    $(document).on "click", ".btn-theme", (e) ->
      e.preventDefault()
      $(this).toggleClass("maxdown-light maxdown-dark")
      maxdown.toggle_theme()

    # Create new document button
    $(document).on "click", ".btn-new-document", (e) ->
      e.preventDefault()
      maxdown.new_document()

    # Handle document buttons
    $(document).on "click", ".document", (e) ->
      e.preventDefault()
      $('.documents .document').removeClass 'active'
      $(this).addClass 'active'
      maxdown.load_document $(this).data('docid')

    # Handle title renaming
    $(document).on "click", ".navbar .title", (e) ->
      unless maxdown.current_doc is null
        $("input", $(this)).show().focus()

    # Handle title saving
    $(document).on "blur", ".title input", (e) ->
      maxdown.rename_document $(this).val()
      $(this).hide()

    # Handle key inputs
    $(document).on "keydown", ".title input", (e) ->
      key = e.keyCode || e.which
      if key is 13
        maxdown.rename_document $(this).val()
        $(this).hide()


# ------------------------------ #


maxdown =
  version: '0.2.2 (8. April 2015)'
  cm: ''
  autosave_interval_id: null
  autosave_interval: 5000
  is_saved: true
  msg_saved: "Saved!"
  msg_saving: "Saving..."
  msg_not_saved: "<span style='color: #f00;'>Not Saved...</span>"
  current_doc: null
  default_title: 'UntitledDocument'
  default_value: '# Maxdown - Markdown Editor\n\nPlease open a new document or choose an excisting from the sidebar. This document **won\'t be saved**.\n\n\n\n# Headline 1\n\n## Headline 2\n\n### Headline 3\n\n**strong**\n\n*emphasize*\n\n~~strike-through~~\n\n[Link](http://google.com)\n\n![Image](http://placehold.it/350x150)'

  init: (selector, t = 'maxdown-light') ->
    console.log '/*'
    console.log ' * Maxdown - Markdown Editor'
    console.log ' * Version: ' + @version
    console.log ' * Author: Max Boll'
    console.log ' * Website: http://opoloo.com'
    console.log ' * License: MIT'
    console.log ' */'

    $(".title span").html 'Maxdown - Markdown Editor'
    $(".title input").val 'Maxdown - Markdown Editor'

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

    @autosave_interval_id = setInterval(->
      maxdown.autosave()
    , maxdown.autosave_interval)

  bind_events: ->
    @cm.on "change", (cm, change) ->
      maxdown.is_saved = false
      $(".save-info").html maxdown.msg_not_saved
      window.onbeforeunload = ->
        return "You have unsaved changes in your document."

  autosave: ->
    if @current_doc != null and @is_saved != true
      # Get current document object
      doc = JSON.parse(localStorage.getItem(@current_doc))
      # Update document
      doc.updated_at = Date.now()
      # Only update document if content has changed
      if doc.content != @cm.getValue()
        $(".save-info").html @msg_saving
        doc.content = @cm.getValue()
        # Overwrite document object
        localStorage.setItem(doc.id, JSON.stringify(doc))
        console.log 'Document overwritten (Doc-ID: ' + @current_doc + ')'
        @is_saved = true
        $(".save-info").html @msg_saved
        window.onbeforeunload = undefined
        @load_documents()

  rename_document: (new_title) ->
    # Get current document object
    doc = JSON.parse(localStorage.getItem(@current_doc))
    # Rename title
    doc.title = new_title
    # Overwrite document object
    localStorage.setItem(doc.id, JSON.stringify(doc))
    # Show new title
    $('.documents .document[data-docid=' + doc.id + ']').html new_title + '.md'
    $('.title span').html new_title
    console.log 'Renamed document (Doc-ID: ' + maxdown.current_doc + ')'

  new_document: ->
    # Clear editor
    @cm.setValue "# UntitledDocument\n\nWelcome to your new document. Start writing your awesome story now."
    @cm.clearHistory()
    @save_document()

  load_document: (id) ->
    doc = JSON.parse(localStorage.getItem(id))
    $(".title span").html doc.title
    $(".title input").val doc.title
    @cm.setValue(doc.content)
    @current_doc = doc.id

    # Get headline
    @get_headlines(id)

    # Fix save info bug
    @is_saved = true
    $(".save-info").html @msg_saved

  get_headlines: (id) ->
    $(".documents .document[data-docid='" + id + "'] .headlines").html("")
    $.each $(".cm-header"), (key, val) ->
      if !$(this).hasClass("cm-formatting")
        size = "headline-1"
        if $(this).hasClass("cm-header-1")
          size = "headline-1"
        if $(this).hasClass("cm-header-2")
          size = "headline-2"
        if $(this).hasClass("cm-header-3")
          size = "headline-3"
        $(".documents .document[data-docid='" + id + "'] .headlines").append "<div class='headline " + size + "'>" + $(this).text() + "</div>"

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
      $(".documents").append('<div class="document" data-docid="' + doc.id + '"><span>' + doc.title + '.md</span><div class="headlines"></div></div>')

    if @current_doc != null
      $(".documents .document[data-docid='" + @current_doc + "']").addClass 'active'
      @get_headlines(@current_doc)

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

    # Update documents list
    $('.documents .document').removeClass 'active'
    $('.documents').prepend('<div class="document active" data-docid="' + doc.id + '">' + doc.title + '.md</div>')
    $('.title span').html doc.title
    $('.title input').val doc.title

    # Update current doc ID
    @current_doc = doc_id

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