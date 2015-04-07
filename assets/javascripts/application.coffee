$(document).ready ->
  app.init()
  editor.init(".editor")

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
      editor.toggle_theme()

    # Create new document button
    $(document).on "click", ".btn-new-document", (e) ->
      e.preventDefault()
      editor.new_document()

    # Handle document buttons
    $(document).on "click", ".document", (e) ->
      e.preventDefault()
      editor.load_document $(this).data('docid')

# -------------- #

editor =
  cm: ''
  default_title: 'UntitledDocument'
  default_value: '# New document\n\nStart writing your story here...'

  init: (selector, t = 'maxdown-light') ->
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
    $(document).on 'click', '.btn-action', (e) ->
      action = $(this).data('action')
      switch action
        when 'new'
          editor.new_document()
        when 'save'
          editor.save_document()

    $(document).on 'change', '.documents', (e) ->
      editor.load_document $(this).val()

    $(document).on 'change', '.font-size', (e) ->
      editor.set_font_size $(this).val()

    $(document).on 'change', '.theme', (e) ->
      editor.set_theme $(this).val()

  new_document: ->
    # Clear editor
    @cm.setValue(@default_value)
    @cm.clearHistory()

  load_document: (id) ->
    @cm.setValue(JSON.parse(localStorage.getItem(id)).content)

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
    alert 'File successfully saved.'

    # Update documents list
    $('.actions .documents').append('<option value="' + doc.id + '">' + doc.title + '</option>')
    $('.actions .documents').val(doc.id)

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