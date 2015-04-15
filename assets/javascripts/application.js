// Generated by CoffeeScript 1.7.1
(function() {
  var app, maxdown;

  $(document).ready(function() {
    app.init();
    return maxdown.init(".editor");
  });

  app = {
    init: function() {
      return this.bind_events();
    },
    bind_events: function() {
      $(document).on("click", ".btn-menu", function(e) {
        e.preventDefault();
        $(this).toggleClass("active");
        $(".main-nav").toggleClass("active");
        return $(".main-nav").fadeToggle("fast");
      });
      $(document).on("click", ".btn-theme", function(e) {
        e.preventDefault();
        $(this).toggleClass("maxdown-light maxdown-dark");
        return maxdown.toggle_theme();
      });
      $(document).on("click", ".btn-new-document", function(e) {
        e.preventDefault();
        return maxdown.new_document();
      });
      $(document).on("click", ".document span", function(e) {
        e.preventDefault();
        if (maxdown.current_doc !== null && maxdown.is_saved === false) {
          if (confirm("You have unsaved changes in your document. Would you like to switch the document anyway?")) {
            $('.documents .document').removeClass('active');
            $(this).parent().addClass('active');
            return maxdown.load_document($(this).parent().data('docid'));
          }
        } else {
          $('.documents .document').removeClass('active');
          $(this).parent().addClass('active');
          return maxdown.load_document($(this).parent().data('docid'));
        }
      });
      $(document).on("blur", ".document.active input", function(e) {
        maxdown.rename_document($(this).val());
        return $(this).hide();
      });
      $(document).on("keydown", ".document.active input", function(e) {
        var key;
        key = e.keyCode || e.which;
        if (key === 13) {
          maxdown.rename_document($(this).val());
          return $(this).hide();
        }
      });
      $(document).on("click", ".headline", function(e) {
        e.preventDefault();
        $(".main-nav, .btn-menu").toggleClass('active');
        $(".main-nav").fadeOut('fast');
        return $("html,body").animate({
          scrollTop: $(".md-header-" + $(this).data("headline")).offset().top - $(".navbar").height() + "px"
        }, 500);
      });
      $(document).on("click", ".btn-delete-document", function(e) {
        var doc_id;
        e.preventDefault();
        if (confirm("Are you sure?")) {
          doc_id = $(this).parent().data("docid");
          return maxdown.delete_document(doc_id);
        }
      });
      $(document).on("click", ".btn-delete-all", function(e) {
        e.preventDefault();
        if (confirm("Are you sure? All documents will be deleted!")) {
          return maxdown.delete_all_documents();
        }
      });
      $(document).on("click", ".documents .document.active > span", function(e) {
        e.preventDefault();
        return $("input", $(this).parent()).show().focus().select();
      });
      return $(document).on("click", ".btn-fullscreen", function(e) {
        var i;
        e.preventDefault();
        i = document.querySelector("body");
        if (i.requestFullscreen) {
          return i.requestFullscreen();
        } else if (i.webkitRequestFullscreen) {
          return i.webkitRequestFullscreen();
        } else if (i.mozRequestFullScreen) {
          return i.mozRequestFullScreen();
        } else if (i.msRequestFullscreen) {
          return i.msRequestFullscreen();
        }
      });
    }
  };

  maxdown = {
    version: '0.2.5 (15. April 2015)',
    cm: '',
    autosave_interval_id: null,
    autosave_interval: 5000,
    is_saved: true,
    current_doc: null,
    default_title: 'UntitledDocument',
    default_value: '# Maxdown - Markdown Editor\n\nPlease open a new document or choose an excisting from the sidebar. This document **won\'t be saved**.\n\n---\n\n# Headline 1\n\n## Headline 2\n\n### Headline 3\n\n**strong**\n\n*emphasize*\n\n~~strike-through~~\n\n[Link](http://google.com)\n\n![Image](http://placehold.it/350x150)',
    init: function(selector, t) {
      if (t == null) {
        t = 'maxdown-light';
      }
      console.log('/*');
      console.log(' * Maxdown - Markdown Editor');
      console.log(' * Version: ' + this.version);
      console.log(' * Author: Max Boll');
      console.log(' * Website: http://opoloo.com');
      console.log(' * License: MIT');
      console.log(' */');
      this.cm = CodeMirror($(selector)[0], {
        value: this.default_value,
        mode: {
          name: 'gfm',
          highlightFormatting: true
        },
        lineWrapping: true,
        tabSize: 2,
        theme: t
      });
      this.bind_events();
      this.load_documents();
      return this.autosave_interval_id = setInterval(function() {
        return maxdown.autosave();
      }, maxdown.autosave_interval);
    },
    bind_events: function() {
      return this.cm.on("change", function(cm, change) {
        if (maxdown.current_doc !== null) {
          maxdown.is_saved = false;
          return window.onbeforeunload = function() {
            return "You have unsaved changes in your document.";
          };
        }
      });
    },
    autosave: function() {
      var doc;
      if (this.current_doc !== null && this.is_saved !== true) {
        doc = JSON.parse(localStorage.getItem(this.current_doc));
        doc.updated_at = Date.now();
        if (doc.content !== this.cm.getValue()) {
          $(".save-info").fadeIn();
          doc.content = this.cm.getValue();
          localStorage.setItem(doc.id, JSON.stringify(doc));
          console.log('Document overwritten (Doc-ID: ' + this.current_doc + ')');
          this.is_saved = true;
          window.onbeforeunload = void 0;
          this.load_documents();
          return $(".save-info").delay(500).fadeOut();
        }
      }
    },
    rename_document: function(new_title) {
      var doc;
      doc = JSON.parse(localStorage.getItem(this.current_doc));
      if (new_title !== "") {
        doc.title = new_title;
        doc.updated_at = Date.now();
        localStorage.setItem(doc.id, JSON.stringify(doc));
      }
      this.load_documents();
      return console.log('Renamed document (Doc-ID: ' + maxdown.current_doc + ')');
    },
    new_document: function() {
      this.cm.setValue("# UntitledDocument\n\nWelcome to your new document. Start writing your awesome story now.");
      this.cm.clearHistory();
      return this.save_document();
    },
    delete_document: function(id) {
      if (this.current_doc === id) {
        this.current_doc = null;
      }
      localStorage.removeItem(id);
      this.load_documents();
      return console.log("Deleted document (Doc-ID: " + id + ")");
    },
    delete_all_documents: function() {
      this.current_doc = null;
      localStorage.clear();
      this.load_documents();
      return console.log("Deleted all documents");
    },
    load_document: function(id) {
      var doc;
      doc = JSON.parse(localStorage.getItem(id));
      $(".title span").html(doc.title);
      $(".title input").val(doc.title);
      this.cm.setValue(doc.content);
      this.current_doc = doc.id;
      this.get_headlines(id);
      $("html,body").scrollTop(0);
      this.is_saved = true;
      return $(".save-info").hide();
    },
    get_headlines: function(id) {
      $(".documents .document[data-docid='" + id + "'] .headlines").html("");
      return $.each($(".cm-header"), function(key, val) {
        var size;
        if (!$(this).hasClass("cm-formatting")) {
          $(this).addClass("md-header-" + key);
          size = "headline-1";
          if ($(this).hasClass("cm-header-1")) {
            size = "headline-1";
          }
          if ($(this).hasClass("cm-header-2")) {
            size = "headline-2";
          }
          if ($(this).hasClass("cm-header-3")) {
            size = "headline-3";
          }
          return $(".documents .document[data-docid='" + id + "'] .headlines").append("<div class='headline " + size + "' data-headline='" + key + "'>" + $(this).text() + "</div>");
        }
      });
    },
    set_font_size: function(size) {
      return $('.CodeMirror').css("font-size", size + "px");
    },
    toggle_theme: function() {
      $("body").toggleClass("maxdown-light maxdown-dark");
      if (this.cm.getOption('theme') === 'maxdown-light') {
        return this.cm.setOption('theme', 'maxdown-dark');
      } else {
        if (this.cm.getOption('theme') === 'maxdown-dark') {
          return this.cm.setOption('theme', 'maxdown-light');
        }
      }
    },
    set_theme: function(theme) {
      this.cm.setOption('theme', theme);
      $('body, #editor').removeClass("maxdown-light");
      $('body, #editor').removeClass("maxdown-dark");
      return $('body, #editor').addClass(theme);
    },
    load_documents: function() {
      var doc, documents, i, keys;
      documents = [];
      keys = Object.keys(localStorage);
      i = 0;
      while (i < keys.length) {
        documents.push(JSON.parse(localStorage.getItem(keys[i])));
        i++;
      }
      documents.sort(function(a, b) {
        return a.updated_at - b.updated_at;
      });
      documents.reverse();
      $(".documents").html("");
      for (doc in documents) {
        doc = documents[doc];
        $(".documents").append('<div class="document" data-docid="' + doc.id + '"><div class="btn-delete-document fontawesome-trash"></div><input type="text" value="' + doc.title + '" /><span>' + doc.title + '.md</span><div class="headlines"></div></div>');
      }
      if (this.current_doc !== null) {
        $(".documents .document[data-docid='" + this.current_doc + "']").addClass('active');
        this.get_headlines(this.current_doc);
        doc = JSON.parse(localStorage.getItem(this.current_doc));
        $('.title span').html(doc.title);
        return $('.title input').val(doc.title);
      } else {
        $(".title span").html('Maxdown - Markdown Editor');
        $(".title input").val('Maxdown - Markdown Editor');
        return this.cm.setValue(this.default_value);
      }
    },
    save_document: function() {
      var doc, doc_id, docname;
      docname = this.default_title;
      doc_id = this.generate_uuid();
      doc = {
        id: doc_id,
        created_at: Date.now(),
        updated_at: Date.now(),
        title: docname,
        content: this.cm.getValue()
      };
      localStorage.setItem(doc_id, JSON.stringify(doc));
      console.log('New document created. (Doc-ID: ' + doc_id + ')');
      this.current_doc = doc_id;
      return this.load_documents();
    },
    generate_uuid: function() {
      var chars, i, r, rnd, uuid;
      chars = '0123456789abcdef'.split('');
      uuid = [];
      rnd = Math.random;
      r = void 0;
      i = 0;
      uuid[8] = uuid[13] = uuid[18] = uuid[23] = '-';
      uuid[14] = '4';
      while (i < 36) {
        if (!uuid[i]) {
          r = 0 | rnd() * 16;
          uuid[i] = chars[i === 19 ? r & 0x3 | 0x8 : r & 0xf];
        }
        i++;
      }
      return uuid.join('');
    }
  };

}).call(this);
