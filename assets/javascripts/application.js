// Generated by CoffeeScript 1.4.0
(function() {
  var app, cache, dropbox, maxdown, navbar, tabs;

  $(document).ready(function() {
    cache.init();
    app.init();
    dropbox.init();
    return maxdown.init(".editor");
  });

  dropbox = {
    app_key: "qf2b38mqupuufxi",
    client: "",
    current_user: "",
    init: function() {
      this.client = new Dropbox.Client({
        key: this.app_key
      });
      return this.authenticate();
    },
    synch: function() {
      var doc, documents, i, keys, _results;
      documents = [];
      keys = Object.keys(localStorage);
      i = 0;
      while (i < keys.length) {
        if (keys[i].includes('maxdown:document:')) {
          documents.push(JSON.parse(localStorage.getItem(keys[i])));
        }
        i++;
      }
      _results = [];
      for (doc in documents) {
        doc = documents[doc];
        _results.push(this.client.writeFile(doc.title + ".md", doc.content, function(error, stat) {
          if (error) {
            console.log(error);
            return false;
          }
          return console.log("Dropbox-Synch: File (" + doc.id + ") saved as revision " + stat.versionTag);
        }));
      }
      return _results;
    },
    logged_in: function() {
      var test;
      $(".btn-dropbox-oauth").hide();
      $(".dropbox-oauth").html("Logged in as: " + this.current_user.name + " (" + this.current_user.email + ")");
      return test = setInterval(function() {
        return dropbox.synch();
      }, 30000);
    },
    get_user_info: function() {
      return this.client.getAccountInfo(function(error, accountInfo) {
        if (error) {
          console.log(error);
          return false;
        }
        dropbox.current_user = accountInfo;
        dropbox.logged_in();
      });
    },
    authenticate: function() {
      return this.client.authenticate({
        interactive: false
      }, function(error, client) {
        var button;
        if (error) {
          console.log(error);
          return false;
        }
        if (client.isAuthenticated()) {
          return dropbox.get_user_info();
        } else {
          button = document.querySelector('.btn-dropbox-oauth');
          return button.addEventListener('click', function() {
            return client.authenticate(function(error, client) {
              if (error) {
                console.log(error);
                return false;
              }
              return dropbox.get_user_info();
            });
          });
        }
      });
    }
  };

  app = {
    manifest_url: location.href + 'manifest.webapp',
    init: function() {
      this.polyfills();
      this.bind_events();
      this.beautify_scrollbars();
      this.is_installed();
      navbar.init('.app-bar', '.manage');
      return tabs.init();
    },
    bind_events: function() {
      $(document).on("click", ".btn-menu", function(e) {
        e.preventDefault();
        return maxdown.toggle_sidebar();
      });
      $(document).on("click", ".btn-manage", function(e) {
        return $(".wrapper").fadeToggle("fast");
      });
      $(document).on("click", ".btn-theme", function(e) {
        e.preventDefault();
        $(this).toggleClass("icon-radio-button-on icon-radio-button-off");
        return maxdown.toggle_theme();
      });
      $(document).on("change", ".theme-radio input", function(e) {
        e.preventDefault();
        return maxdown.set_theme($(this).data('theme'));
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
            maxdown.load_document($(this).parent().data('docid'));
            return maxdown.cm.focus();
          }
        } else {
          $('.documents .document').removeClass('active');
          $(this).parent().addClass('active');
          maxdown.load_document($(this).parent().data('docid'));
          return maxdown.cm.focus();
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
        var offset;
        e.preventDefault();
        $(".main-nav, .btn-menu").toggleClass('active');
        $(".main-nav").fadeOut('fast');
        offset = $(".md-header-" + $(this).data("headline")).offset().top + $(".wrapper").scrollTop();
        return $(".wrapper").animate({
          scrollTop: offset + "px"
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
      $(document).on("click", ".btn-fullscreen", function(e) {
        e.preventDefault();
        return maxdown.toggle_fullscreen();
      });
      Mousetrap.bind('ctrl+m', function() {
        return maxdown.toggle_sidebar();
      });
      Mousetrap.bind('ctrl+alt+f', function() {
        return maxdown.toggle_fullscreen();
      });
      Mousetrap.bind('ctrl+alt+n', function() {
        return maxdown.new_document();
      });
      return $(document).on("click", ".btn-install", function(e) {
        e.preventDefault();
        return app.install();
      });
    },
    polyfills: function() {
      if (!String.prototype.includes) {
        return String.prototype.includes = function() {
          'use strict';
          return String.prototype.indexOf.apply(this, arguments) !== -1;
        };
      }
    },
    install: function() {
      var install_loc_find;
      install_loc_find = navigator.mozApps.install(this.manifest_url);
      install_loc_find.onsuccess = function(data) {};
      return install_loc_find.onerror = function() {
        return alert("There was an error while installing Maxdown on your device: " + install_loc_find.error.name);
      };
    },
    is_installed: function() {
      var install_check;
      if (navigator.mozApps) {
        install_check = navigator.mozApps.checkInstalled(this.manifest_url);
        return install_check.onsuccess = function() {
          if (install_check.result) {
            return $(".btn-install").hide();
          } else {
            return $(".btn-install").show();
          }
        };
      }
    },
    beautify_scrollbars: function() {
      return $(".wrapper, .documents").perfectScrollbar();
    },
    set_cookie: function(c_name, value, exdays) {
      var c_value, exdate;
      if (exdays == null) {
        exdays = 365;
      }
      exdate = new Date;
      exdate.setDate(exdate.getDate() + exdays);
      c_value = escape(value) + (exdays === null ? '' : '; expires=' + exdate.toUTCString());
      return document.cookie = c_name + '=' + c_value;
    },
    get_cookie: function(c_name) {
      var ARRcookies, i, x, y;
      i = void 0;
      x = void 0;
      y = void 0;
      ARRcookies = document.cookie.split(';');
      i = 0;
      while (i < ARRcookies.length) {
        x = ARRcookies[i].substr(0, ARRcookies[i].indexOf('='));
        y = ARRcookies[i].substr(ARRcookies[i].indexOf('=') + 1);
        x = x.replace(/^\s+|\s+$/g, '');
        if (x === c_name) {
          return unescape(y);
        }
        i++;
      }
    }
  };

  cache = {
    app_cache: window.applicationCache,
    init: function() {
      return this.bind_events();
    },
    bind_events: function() {
      window.applicationCache.addEventListener('updateready', (function(e) {
        if (window.applicationCache.status === window.applicationCache.UPDATEREADY) {
          if (confirm('A new version of this site is available. Load it?')) {
            window.location.reload();
          }
        } else {

        }
      }), false);
      this.app_cache.addEventListener('cached', this.handle_cache_event, false);
      this.app_cache.addEventListener('checking', this.handle_cache_event, false);
      this.app_cache.addEventListener('downloading', this.handle_cache_event, false);
      this.app_cache.addEventListener('error', this.handle_cache_error, false);
      this.app_cache.addEventListener('noupdate', this.handle_cache_event, false);
      this.app_cache.addEventListener('obsolete', this.handle_cache_event, false);
      this.app_cache.addEventListener('progress', this.handle_cache_event, false);
      return this.app_cache.addEventListener('updateready', this.handle_cache_event, false);
    },
    handle_cache_event: function(e) {
      return console.log('App-Cache: ' + e.type);
    },
    handle_cache_error: function(e) {
      return console.log('App-Cache Error: Cache failed to update!');
    }
  };

  maxdown = {
    version: '0.3.5 (30. June 2015)',
    cm: '',
    autosave_interval_id: null,
    autosave_interval: 5000,
    is_saved: true,
    current_doc: null,
    default_title: 'UntitledDocument',
    default_value: '# Maxdown - Markdown Editor\n\nPlease open a new document or choose an excisting from the sidebar. This document **won\'t be saved**.\n\n---\n\n# Headline 1\n\n## Headline 2\n\n### Headline 3\n\n**strong**\n\n*emphasize*\n\n~~strike-through~~\n\n[Link](http://google.com)\n\n![Image](http://placehold.it/350x150)\n\n---\n\n### Keyboard Shortcuts\n\n- **CTRL+M** -> Toggle sidebar\n- **CTRL+ALT+F** -> Toggle Fullscreen\n- **CTRL+ALT+N** -> New document',
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
      this.get_version();
      this.cm = CodeMirror($(selector)[0], {
        value: this.default_value,
        mode: {
          name: 'gfm',
          highlightFormatting: true
        },
        lineWrapping: true,
        tabSize: 2,
        theme: t,
        viewportMargin: Infinity,
        placeholder: "Start writing here...",
        extraKeys: {
          "Ctrl-M": function() {
            return maxdown.toggle_sidebar();
          },
          "Ctrl-Alt-F": function() {
            return maxdown.toggle_fullscreen();
          },
          "Ctrl-Alt-N": function() {
            return maxdown.new_document();
          }
        }
      });
      this.bind_events();
      this.load_documents();
      if (app.get_cookie("maxdown_theme") === void 0) {
        app.set_cookie("maxdown_theme", "maxdown-light");
      }
      this.set_theme(app.get_cookie("maxdown_theme"));
      if (!this.fullscreen_possible) {
        $(".actions .btn-fullscreen").hide();
      }
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
    get_version: function() {
      return $(".current-version").html(this.version);
    },
    get_remote_version: function() {},
    fullscreen_possible: function() {
      if (document.fullscreenEnabled || document.webkitFullscreenEnabled || document.mozFullScreenEnabled || document.msFullscreenEnabled) {
        return true;
      } else {
        return false;
      }
    },
    toggle_fullscreen: function() {
      var i;
      $(".btn-fullscreen").toggleClass("icon-fullscreen icon-fullscreen-exit");
      if (this.is_fullscreen()) {
        if (document.exitFullscreen) {
          document.exitFullscreen();
        } else if (document.webkitExitFullscreen) {
          document.webkitExitFullscreen();
        } else if (document.mozCancelFullScreen) {
          document.mozCancelFullScreen();
        } else if (document.msExitFullscreen) {
          document.msExitFullscreen();
        }
        return console.log('Fullscreen-Mode disabled');
      } else {
        i = document.querySelector("html");
        if (i.requestFullscreen) {
          i.requestFullscreen();
        } else if (i.webkitRequestFullscreen) {
          i.webkitRequestFullscreen();
        } else if (i.mozRequestFullScreen) {
          i.mozRequestFullScreen();
        } else if (i.msRequestFullscreen) {
          i.msRequestFullscreen();
        }
        return console.log('Fullscreen-Mode enabled');
      }
    },
    is_fullscreen: function() {
      if (document.fullscreenElement || document.webkitFullscreenElement || document.mozFullScreenElement || document.msFullscreenElement) {
        return true;
      } else {
        return false;
      }
    },
    toggle_sidebar: function() {
      $(".btn-menu").toggleClass("active");
      $(".main-nav").toggleClass("active");
      return $(".main-nav").fadeToggle("fast");
    },
    autosave: function() {
      var doc;
      if (this.current_doc !== null && this.is_saved !== true) {
        doc = JSON.parse(localStorage.getItem(this.current_doc));
        doc.updated_at = Date.now();
        if (doc.content !== this.cm.getValue()) {
          $("head link[rel='shortcut icon']").attr("href", "favicon_save.ico");
          $("head link[rel='icon']").attr("href", "favicon_save.ico");
          setTimeout(function() {
            $("head link[rel='shortcut icon']").attr("href", "favicon.ico");
            return $("head link[rel='icon']").attr("href", "favicon.ico");
          }, 2000);
          doc.content = this.cm.getValue();
          localStorage.setItem(doc.id, JSON.stringify(doc));
          console.log('Document overwritten (Doc-ID: ' + this.current_doc + ')');
          this.is_saved = true;
          window.onbeforeunload = void 0;
          return this.load_documents();
        }
      }
    },
    rename_document: function(new_title) {
      var doc;
      doc = JSON.parse(localStorage.getItem(this.current_doc));
      if (new_title !== "" && new_title !== doc.title) {
        doc.title = new_title;
        doc.updated_at = Date.now();
        localStorage.setItem(doc.id, JSON.stringify(doc));
      }
      this.load_documents();
      return console.log('Renamed document (Doc-ID: ' + maxdown.current_doc + ')');
    },
    new_document: function() {
      this.cm.setValue("");
      this.cm.clearHistory();
      this.save_document();
      if ($(".btn-menu").hasClass('active')) {
        this.toggle_sidebar();
      }
      return this.cm.focus();
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
      return this.is_saved = true;
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
          if ($(this).hasClass("cm-header-4")) {
            size = "headline-4";
          }
          if ($(this).hasClass("cm-header-5")) {
            size = "headline-5";
          }
          if ($(this).hasClass("cm-header-6")) {
            size = "headline-6";
          }
          return $(".documents .document[data-docid='" + id + "'] .headlines").append("<div class='headline " + size + "' data-headline='" + key + "'>" + $(this).text() + "</div>");
        }
      });
    },
    set_font_size: function(size) {
      return $('.CodeMirror').css("font-size", size + "px");
    },
    toggle_theme: function() {
      $(".write").toggleClass("maxdown-light maxdown-dark");
      if (this.cm.getOption('theme') === 'maxdown-light') {
        this.cm.setOption('theme', 'maxdown-dark');
        return app.set_cookie("maxdown_theme", "maxdown-dark");
      } else {
        if (this.cm.getOption('theme') === 'maxdown-dark') {
          this.cm.setOption('theme', 'maxdown-light');
          return app.set_cookie("maxdown_theme", "maxdown-light");
        }
      }
    },
    set_theme: function(theme) {
      this.cm.setOption('theme', theme);
      $('.write').removeClass("maxdown-light maxdown-dark");
      $('.write').addClass(theme);
      $(".theme-radio input[data-theme='" + theme + "']").prop('checked', true);
      return app.set_cookie('maxdown_theme', theme);
    },
    load_documents: function() {
      var doc, documents, i, keys;
      documents = [];
      keys = Object.keys(localStorage);
      i = 0;
      while (i < keys.length) {
        if (keys[i].includes('maxdown:document:')) {
          documents.push(JSON.parse(localStorage.getItem(keys[i])));
        }
        i++;
      }
      documents.sort(function(a, b) {
        return a.updated_at - b.updated_at;
      });
      documents.reverse();
      $(".documents").html("");
      for (doc in documents) {
        doc = documents[doc];
        $(".documents").append('<div class="document" data-docid="' + doc.id + '"><div class="btn-delete-document icon-delete"></div><input type="text" value="' + doc.title + '" /><span>' + doc.title + '.md</span><div class="headlines"></div></div>');
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
      doc_id = 'maxdown:document:' + this.generate_uuid();
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

  navbar = {
    c: "",
    n: "",
    n_height: 0,
    n_top: 0,
    d_height: 0,
    w_height: 0,
    w_scroll_current: 0,
    w_scroll_before: 0,
    w_scroll_diff: 0,
    init: function(selector, container) {
      this.n = document.querySelector(selector);
      this.c = document.querySelector(container);
      return this.bind_events();
    },
    bind_events: function() {
      return this.c.addEventListener('scroll', function(event) {
        return navbar.scroll();
      });
    },
    scroll: function() {
      this.n_height = this.n.offsetHeight;
      this.d_height = this.c.scrollHeight;
      this.w_height = window.innerHeight;
      this.w_scroll_current = this.c.scrollTop;
      this.w_scroll_diff = this.w_scroll_before - this.w_scroll_current;
      this.n_top = parseInt(window.getComputedStyle(this.n).getPropertyValue('top')) + this.w_scroll_diff;
      if (this.w_scroll_current <= 0) {
        this.n.style.top = '0px';
      } else if (this.w_scroll_diff > 0) {
        this.n.style.top = (this.n_top > 0 ? 0 : this.n_top) + 'px';
      } else if (this.w_scroll_diff < 0) {
        if (this.w_scroll_current + this.w_height >= this.d_height - this.n_height) {
          this.n.style.top = ((this.n_top = this.w_scroll_current + this.w_height - this.d_height) < 0 ? this.n_top : 0) + 'px';
        } else {
          this.n.style.top = (Math.abs(this.n_top) > this.n_height ? -this.n_height : this.n_top) + 'px';
        }
      }
      return this.w_scroll_before = this.w_scroll_current;
    }
  };

  tabs = {
    init: function() {
      return this.bind_events();
    },
    bind_events: function() {
      return $(document).on('click', '.tab-link', function(e) {
        e.preventDefault();
        return tabs.switch_tab($(this).data('tab'));
      });
    },
    switch_tab: function(tab) {
      if ($(".tab.active").data("tab") !== tab) {
        $(".tab-link").removeClass('tab-active');
        $(".tab-link[data-tab='" + tab + "']").addClass('tab-active');
        $(".tab").removeClass('active');
        $(".tab[data-tab='" + tab + "']").addClass('active');
        return $(".manage").scrollTop(0);
      }
    }
  };

}).call(this);
