/* ============================================
   Equipify Documentation — script.js
   Vanilla JS — Zero Dependencies
   ============================================ */

document.addEventListener('DOMContentLoaded', function () {

  /* ───── DOM References ───── */
  var sidebar        = document.getElementById('sidebar');
  var sidebarOverlay = document.getElementById('sidebarOverlay');
  var menuToggle     = document.getElementById('menuToggle');
  var printBtn       = document.getElementById('printBtn');
  var currentEl      = document.getElementById('currentSection');
  var navLinks       = document.querySelectorAll('.sidebar-nav a');
  var sections       = document.querySelectorAll('.doc-section, .cover');
  var body           = document.body;

  /* ───── 1. Smooth Scrolling ───── */
  document.addEventListener('click', function (e) {
    var link = e.target.closest('a[href^="#"]');
    if (!link) return;
    var id = link.getAttribute('href');
    if (!id || id === '#') return;
    var target = document.querySelector(id);
    if (!target) return;
    e.preventDefault();
    var top = target.getBoundingClientRect().top + window.pageYOffset - 20;
    window.scrollTo({ top: top, behavior: 'smooth' });
    history.replaceState(null, '', id);
  });

  /* ───── 2. Active Section Indicator ───── */
  var titleMap = {};
  sections.forEach(function (sec) {
    var h2 = sec.querySelector('h2');
    if (h2) titleMap[sec.id] = h2.textContent;
  });

  function updateActiveLink() {
    var scrollY = window.scrollY + 120;
    var currentId = '';
    sections.forEach(function (sec) {
      if (sec.offsetTop <= scrollY) currentId = sec.id;
    });
    navLinks.forEach(function (link) {
      var href = link.getAttribute('href');
      var match = href && href.substring(1) === currentId;
      link.classList.toggle('active', match);
    });
    if (currentEl && titleMap[currentId]) {
      currentEl.textContent = titleMap[currentId];
    }
  }

  var scrollTimer;
  window.addEventListener('scroll', function () {
    cancelAnimationFrame(scrollTimer);
    scrollTimer = requestAnimationFrame(updateActiveLink);
  });
  updateActiveLink();

  /* ───── 3. Sidebar Toggle (Mobile) ───── */
  function openSidebar() {
    if (sidebar) sidebar.classList.add('open');
    if (sidebarOverlay) sidebarOverlay.classList.add('active');
  }

  function closeSidebar() {
    if (sidebar) sidebar.classList.remove('open');
    if (sidebarOverlay) sidebarOverlay.classList.remove('active');
  }

  if (menuToggle) menuToggle.addEventListener('click', openSidebar);
  if (sidebarOverlay) sidebarOverlay.addEventListener('click', closeSidebar);

  navLinks.forEach(function (link) {
    link.addEventListener('click', function () {
      if (window.innerWidth <= 960) closeSidebar();
    });
  });

  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') closeSidebar();
  });

  /* ───── 4. Print / Download PDF ───── */
  function triggerPrint() { window.print(); }

  if (printBtn) printBtn.addEventListener('click', triggerPrint);

  var pdfBtn = document.getElementById('pdfBtn');
  if (pdfBtn) pdfBtn.addEventListener('click', triggerPrint);

  document.addEventListener('keydown', function (e) {
    if ((e.ctrlKey || e.metaKey) && e.key === 'p') {
      e.preventDefault();
      triggerPrint();
    }
  });

  /* ───── 6. Image Lightbox ───── */
  var lightbox = null;
  var lightboxImg = null;
  var lightboxCaption = null;
  var lightboxCounter = null;
  var currentImages = [];
  var currentIndex = 0;

  function createLightbox() {
    lightbox = document.createElement('div');
    lightbox.id = 'lightbox-overlay';
    lightbox.innerHTML =
      '<div class="lightbox-backdrop"></div>' +
      '<div class="lightbox-content">' +
        '<button class="lightbox-close" title="Close">&times;</button>' +
        '<button class="lightbox-prev" title="Previous">&#8249;</button>' +
        '<button class="lightbox-next" title="Next">&#8250;</button>' +
        '<img class="lightbox-img" src="" alt="">' +
        '<div class="lightbox-caption"></div>' +
        '<div class="lightbox-counter"></div>' +
      '</div>';
    document.body.appendChild(lightbox);
    lightboxImg = lightbox.querySelector('.lightbox-img');
    lightboxCaption = lightbox.querySelector('.lightbox-caption');
    lightboxCounter = lightbox.querySelector('.lightbox-counter');
    lightbox.querySelector('.lightbox-backdrop').addEventListener('click', closeLightbox);
    lightbox.querySelector('.lightbox-close').addEventListener('click', closeLightbox);
    lightbox.querySelector('.lightbox-prev').addEventListener('click', function () { navLightbox(-1); });
    lightbox.querySelector('.lightbox-next').addEventListener('click', function () { navLightbox(1); });
  }

  function openLightbox(src, caption, idx, collection) {
    if (!lightbox) createLightbox();
    if (!lightbox) return;
    currentImages = collection || [];
    currentIndex = idx || 0;
    showLightboxImage();
    lightbox.classList.add('active');
    body.style.overflow = 'hidden';
  }

  function showLightboxImage() {
    if (!lightbox) return;
    var item = currentImages[currentIndex];
    if (item) {
      lightboxImg.src = item.src;
      lightboxImg.alt = item.alt || '';
      lightboxCaption.textContent = item.caption || '';
    }
    if (currentImages.length > 1) {
      lightboxCounter.textContent = (currentIndex + 1) + ' / ' + currentImages.length;
      lightboxCounter.style.display = '';
    } else {
      lightboxCounter.style.display = 'none';
    }
  }

  function navLightbox(dir) {
    if (currentImages.length <= 1) return;
    currentIndex = (currentIndex + dir + currentImages.length) % currentImages.length;
    showLightboxImage();
  }

  function closeLightbox() {
    if (lightbox) lightbox.classList.remove('active');
    body.style.overflow = '';
  }

  document.addEventListener('keydown', function (e) {
    if (!lightbox || !lightbox.classList.contains('active')) return;
    if (e.key === 'Escape') closeLightbox();
    if (e.key === 'ArrowLeft') navLightbox(-1);
    if (e.key === 'ArrowRight') navLightbox(1);
  });

  function attachLightbox() {
    var images = [];
    document.querySelectorAll('.screenshot-img-wrapper img, figure.screenshot img, .doc-section img').forEach(function (img) {
      if (img.closest('.lightbox-content') || img.closest('.cover-logos') || img.closest('.sidebar') || img.closest('.cover')) return;
      images.push(img);
    });
    var collection = images.map(function (im) {
      var c = '';
      var f = im.closest('figure');
      if (f) { var ca = f.querySelector('figcaption .fig-title'); if (ca) c = ca.textContent; }
      return { src: im.src, alt: im.alt, caption: c };
    });
    images.forEach(function (img, i) {
      img.style.cursor = 'zoom-in';
      img.addEventListener('click', function () {
        openLightbox(img.src, collection[i].caption, i, collection);
      });
    });
  }
  attachLightbox();

  /* ───── 7. Expand / Collapse ───── */
  function initCollapse() {
    document.querySelectorAll('.doc-section h3, .doc-section h4').forEach(function (heading) {
      var next = heading.nextElementSibling;
      if (!next) return;
      if (!['P', 'UL', 'OL', 'DIV', 'TABLE'].includes(next.tagName)) return;
      heading.classList.add('collapsible-heading');
      var indicator = document.createElement('span');
      indicator.className = 'collapse-indicator';
      indicator.innerHTML = '&#9662;';
      heading.appendChild(indicator);
      var contentWrap = document.createElement('div');
      contentWrap.className = 'collapse-content';
      contentWrap.style.cssText = 'overflow:hidden;transition:max-height 0.3s ease,opacity 0.3s ease;';
      var siblings = [];
      var sib = heading.nextElementSibling;
      var stopTags = heading.tagName === 'H4' ? ['H2', 'H3', 'H4'] : ['H2', 'H3'];
      while (sib && !stopTags.includes(sib.tagName)) {
        siblings.push(sib);
        sib = sib.nextElementSibling;
      }
      siblings.forEach(function (el) { contentWrap.appendChild(el); });
      heading.insertAdjacentElement('afterend', contentWrap);
      var collapsed = false;
      heading.addEventListener('click', function (e) {
        if (e.target.closest('a')) return;
        collapsed = !collapsed;
        if (collapsed) {
          contentWrap.style.maxHeight = contentWrap.scrollHeight + 'px';
          requestAnimationFrame(function () {
            contentWrap.style.maxHeight = '0px';
            contentWrap.style.opacity = '0';
          });
          indicator.style.transform = 'rotate(-90deg)';
        } else {
          contentWrap.style.maxHeight = contentWrap.scrollHeight + 'px';
          contentWrap.style.opacity = '1';
          indicator.style.transform = 'rotate(0deg)';
          setTimeout(function () { contentWrap.style.maxHeight = 'none'; }, 310);
        }
      });
    });
  }
  initCollapse();

  /* ───── 8. Copy Code ───── */
  document.querySelectorAll('pre').forEach(function (pre) {
    var btn = document.createElement('button');
    btn.className = 'code-copy-btn no-print';
    btn.textContent = 'Copy';
    pre.style.position = 'relative';
    pre.appendChild(btn);
    btn.addEventListener('click', function () {
      var code = pre.querySelector('code');
      var text = (code || pre).textContent;
      if (!navigator.clipboard) {
        var ta = document.createElement('textarea');
        ta.value = text;
        ta.style.cssText = 'position:fixed;left:-9999px;';
        document.body.appendChild(ta);
        ta.select();
        try { document.execCommand('copy'); } catch (e) { /* silent */ }
        document.body.removeChild(ta);
        btn.textContent = 'Copied!';
        setTimeout(function () { btn.textContent = 'Copy'; }, 1500);
        return;
      }
      navigator.clipboard.writeText(text).then(function () {
        btn.textContent = 'Copied!';
        setTimeout(function () { btn.textContent = 'Copy'; }, 1500);
      }).catch(function () {
        btn.textContent = 'Failed';
        setTimeout(function () { btn.textContent = 'Copy'; }, 1500);
      });
    });
  });

  /* ───── 9. Back to Top ───── */
  var backToTop = document.createElement('button');
  backToTop.className = 'back-to-top no-print';
  backToTop.innerHTML = '&#8593;';
  backToTop.title = 'Back to top';
  document.body.appendChild(backToTop);

  window.addEventListener('scroll', function () {
    backToTop.classList.toggle('visible', window.scrollY > 400);
  });

  backToTop.addEventListener('click', function () {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  });

  /* ───── 10. TOC Group Collapse ───── */
  document.querySelectorAll('.nav-group-label').forEach(function (label) {
    var ul = label.closest('ul');
    if (!ul) return;
    var items = ul.querySelectorAll('li:not(.nav-group-label)');
    var arrow = document.createElement('span');
    arrow.style.cssText = 'float:right;transition:transform 0.2s;font-size:0.8em;';
    arrow.innerHTML = '&#9662;';
    label.appendChild(arrow);
    var collapsed = false;
    label.addEventListener('click', function () {
      collapsed = !collapsed;
      items.forEach(function (li) { li.style.display = collapsed ? 'none' : ''; });
      arrow.style.transform = collapsed ? 'rotate(-90deg)' : '';
    });
  });

  /* ───── 11. Print Mode — Auto expand ───── */
  window.addEventListener('beforeprint', function () {
    document.querySelectorAll('.collapse-content').forEach(function (el) {
      el.style.maxHeight = 'none';
      el.style.opacity = '1';
      el.style.overflow = 'visible';
    });
    document.querySelectorAll('.collapse-indicator').forEach(function (el) {
      el.style.display = 'none';
    });
    closeSidebar();
  });

  window.addEventListener('afterprint', function () {
    document.querySelectorAll('.collapse-indicator').forEach(function (el) {
      el.style.display = '';
    });
  });

  /* ───── 12. Responsive Table Scroll Hint ───── */
  document.querySelectorAll('.table-wrap').forEach(function (wrap) {
    var hint = document.createElement('div');
    hint.className = 'scroll-hint no-print';
    hint.textContent = '\u2190 Scroll horizontally \u2192';
    hint.style.display = 'none';
    wrap.parentNode.insertBefore(hint, wrap.nextSibling);
    function checkScroll() {
      hint.style.display = wrap.scrollWidth > wrap.clientWidth ? 'block' : 'none';
    }
    checkScroll();
    window.addEventListener('resize', checkScroll);
  });

});
