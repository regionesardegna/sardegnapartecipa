// This file is compiled inside Decidim core pack. Code can be added here and will be executed
// as part of that pack

// Load images
require.context("../../images", true)

// ==========================================
// 1. GESTIONE SCROLL (Sticky Header & Back to Top)
// ==========================================
const initDecidimScrollEffects = function() {

    const $window = $(window);
    const $backToTop = $('#back-to-top');
    const $stickyHeader = $(".layout-container > header");

    const stickyOffset = $stickyHeader.length ? $stickyHeader.offset().top : 0;

    $window.off('scroll.decidimEffetti').on('scroll.decidimEffetti', function() {
        const scrollTop = $window.scrollTop();

        if ($backToTop.length) {
            if (scrollTop > 300) {
                if ($window.width() <= 640) {
                    $backToTop.css('bottom', '270px');
                } else {
                    $backToTop.css('bottom', '');
                }
                $backToTop.fadeIn(200);
            } else {
                $backToTop.fadeOut(200);
            }
        }

        if ($stickyHeader.length) {
            const isSticky = scrollTop > stickyOffset;
            
            $('body').toggleClass('page-is-sticky', isSticky);
        } 
    });
};

// ==========================================
// 2. RIPOSIZIONAMENTO MENU DECIDIM
// ==========================================
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

// ==========================================
// 3. MUTATION OBSERVER (Menu Mobile)
// ==========================================
const initMobileMenuObserver = function() {
    const mobileMenu = document.getElementById("dropdown-menu-main-mobile");
    
    // Disconnettiamo eventuali observer precedenti per evitare loop al cambio pagina
    if (window.decidimMobileMenuObserver) {
        window.decidimMobileMenuObserver.disconnect();
    }

    if (mobileMenu) {
        window.decidimMobileMenuObserver = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                if (mutation.attributeName === "aria-hidden") {
                    const isMenuHidden = mobileMenu.getAttribute("aria-hidden") === "true";
                    
                    if (!isMenuHidden) {
                        // Il menu mobile si è aperto -> aggiunge la classe al body
                        document.body.classList.add("mobile-menu-open");
                    } else {
                        // Il menu mobile si è chiuso -> rimuove la classe dal body
                        document.body.classList.remove("mobile-menu-open");
                    }
                }
            });
        });

        // Inizia ad osservare i cambiamenti di attributi sul menu mobile
        window.decidimMobileMenuObserver.observe(mobileMenu, { attributes: true });
    }
};


// ==========================================
// 4. INIZIALIZZAZIONE GLOBALE DEGLI EVENTI
// ==========================================
// Raggruppiamo tutto in un'unica funzione di avvio
const initAllDecidimScripts = function() {
    initDecidimScrollEffects();
    repositionDecidimMenu();
    initMobileMenuObserver();
};

// Agganciamo la funzione a TUTTI gli eventi di caricamento (Vanilla, Turbo e vecchio Turbolinks)
document.addEventListener("DOMContentLoaded", initAllDecidimScripts);
document.addEventListener("turbo:load", initAllDecidimScripts);
document.addEventListener("turbolinks:load", initAllDecidimScripts);
window.addEventListener("load", initAllDecidimScripts); // Mantenuto per extra sicurezza su asset asincroni