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
      $(this).attr("contenteditable", "true")

    # Handle title saving
    $(document).on "focusout", ".navbar .title", (e) ->
      maxdown.rename_document $(this).text()
      console.log 'Renamed document (Doc-ID: ' + maxdown.current_doc + ')'


# ------------------------------ #


maxdown =
  version: '0.2.1'
  cm: ''
  current_doc: null
  default_title: 'UntitledDocument'
  default_value: '# Maxdown - Markdown Editor\n\nPlease open a new document or choose an excisting from the sidebar. This document **won\'t be saved**.\n\n\n\n# Headline 1\n\n## Headline 2\n\n### Headline 3\n\n**strong**\n\n*emphasize*\n\n~~strike-through~~\n\n[Link](http://google.com)\n\n![Image](http://google.com/image.png)'

  init: (selector, t = 'maxdown-light') ->
    console.log '/*'
    console.log ' * Maxdown - Markdown Editor'
    console.log ' * Version: ' + @version
    console.log ' * Author: Max Boll'
    console.log ' * License: MIT'
    console.log ' */'

    @bind_events()
    @load_documents()

    @cm = CodeMirror($(selector)[0],
      value: @default_value
      mode:
        name: 'gfm'
        highlightFormatting: true
      lineWrapping: true
      tabSize: 2
      theme: t
    )
    # @cm.setValue(@default_value)

  bind_events: ->
    $(document).on 'change', '.documents', (e) ->
      maxdown.load_document $(this).val()

    $(document).on 'change', '.font-size', (e) ->
      maxdown.set_font_size $(this).val()

    $(document).on 'change', '.theme', (e) ->
      maxdown.set_theme $(this).val()

  rename_document: (new_title) ->
    doc = JSON.parse(localStorage.getItem(@current_doc))
    doc.title = new_title
    localStorage.setItem(doc.id, JSON.stringify(doc))
    $('.documents .document[data-docid=' + doc.id + ']').html new_title + '.md'

  new_document: ->
    # Clear editor
    @cm.setValue(@default_value)
    @cm.clearHistory()
    @save_document()

  load_document: (id) ->
    doc = JSON.parse(localStorage.getItem(id))
    $(".navbar .title").html doc.title
    @cm.setValue(doc.content)
    @current_doc = doc.id

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

    # Sort documents (not implemented yet)
    sortable = []
    for doc of documents
      sortable.push [
        doc
        documents[doc].updated_at
      ]
    sortable.sort (a, b) ->
      a[1] - b[1]
    # console.log sortable.reverse()

    # Parse each file and insert it into file-selection
    $(".documents").html("")
    $.each documents, (key, doc) ->
      $(".documents").append('<div class="document" data-docid="' + documents[key].id + '">' + documents[key].title + '.md</div>')

  save_document: ->
    # Ask for docname
    docname = @default_title

    # Unique File ID
    doc_id = @generate_uuid()

    # Create new file object
    doc =
      id: doc_id
      created_at: Date.now()
      updated_at: Date.now()
      title: docname
      content: @cm.getValue()

    # Save file object to localStorage
    localStorage.setItem(doc_id, JSON.stringify(doc))
    console.log 'New document created. (Doc-ID: ' + doc_id + ')'

    # Update documents list
    $('.documents').prepend('<div class="documents" data-docid="' + doc.id + '">' + doc.title + '.md</div>')
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