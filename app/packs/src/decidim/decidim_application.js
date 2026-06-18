// This file is compiled inside Decidim core pack. Code can be added here and will be executed
// as part of that pack

// Load images
require.context("../../images", true)

// Definizione variabili all'esterno
const $window = $(window);
const $body = $('body');
const $backToTop = $('#back-to-top');
const $stickyHeader = $("#sticky-header");

// Calcola l'offset solo se l'elemento esiste
const stickyOffset = $stickyHeader.length ? $stickyHeader.offset().top : 0;

$window.on('scroll', function() {
    // 1. Gestione Back to Top
    if ($backToTop.length) {
        if ($window.scrollTop() > 300) {
            if ($window.width() <= 640) {
                $backToTop.css('bottom', '270px');
            } else {
                $backToTop.css('bottom', '');
            }
            $backToTop.fadeIn(200);
            
            // Logica inversione colore
            const btnTop = $backToTop.offset().top;
            let overlap = false;
            $('.main-footer__down').each(function() {
                const secTop = $(this).offset().top;
                const secBottom = secTop + $(this).outerHeight();
                if (btnTop >= secTop && btnTop <= secBottom) {
                    overlap = true;
                    return false;
                }
            });
            $backToTop.toggleClass('invertito', overlap);
        } else {
            $backToTop.fadeOut(200);
        }
    }

    // 2. Gestione Sticky Header
    if ($stickyHeader.length) {
        const isSticky = $window.scrollTop() > stickyOffset;
        $body.toggleClass('page-is-sticky', isSticky);
    }
});

function repositionDecidimMenu() {
  const header = document.querySelector(".layout-container > header");
  if (!header) return;

  const isHomePage = document.body.classList.contains("page-home") || 
                     window.location.pathname === "/" || 
                     /^\/[a-z]{2}\/?$/.test(window.location.pathname);
  
  if (isHomePage) {
    const globalMenu = document.querySelector("#home__menu, .main-nav"); 
    if (globalMenu && !header.contains(globalMenu)) {
      header.appendChild(globalMenu);
    }
  } else {
    const contextNav = document.querySelector(".process-header__container, .breadcrumb, .nav-container");
    // Controllo extra: assicuriamoci che non sia l'elemento del menu home
    if (contextNav && !header.contains(contextNav) && !contextNav.id?.includes('home__menu')) {
      header.appendChild(contextNav);
    }
  }
}

document.addEventListener("DOMContentLoaded", repositionDecidimMenu);
document.addEventListener("turbolinks:load", repositionDecidimMenu);
window.addEventListener("load", repositionDecidimMenu);