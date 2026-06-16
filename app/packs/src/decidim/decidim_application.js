// This file is compiled inside Decidim core pack. Code can be added here and will be executed
// as part of that pack

// Load images
require.context("../../images", true)

window.addEventListener("scroll",function(){	   
	// Selezioniamo l'elemento una sola volta per migliorare le prestazioni
	const $backToTop = $('#back-to-top');

	if ($(window).scrollTop() > 300) {
		
		// Gestione della posizione su mobile
		if ($(window).width() <= 640) {
			$backToTop.css('bottom', '270px');
		} else {
			$backToTop.css('bottom', ''); // Resetta il bottom su desktop (usa il valore del CSS)
		}

		$backToTop.fadeIn(200); // Mostra con una leggera sfumatura
	} else {
		$backToTop.fadeOut(200); // Nasconde con una leggera sfumatura
	}
	
	if ($backToTop.is(':visible')) {
		const btnTop = $backToTop.offset().top;
		let overlap = false;

		// Cicla su tutte le sezioni che hanno lo sfondo problematico
		$('.main-footer__down').each(function() {
			const secTop = $(this).offset().top;
			const secBottom = secTop + $(this).outerHeight();

			// Controlla se il bottone è dentro la sezione
			if (btnTop >= secTop && btnTop <= secBottom) {
				overlap = true;
				return false; // Interrompe il ciclo .each() appena trova una corrispondenza
			}
		});

		// Aggiunge o toglie la classe in base all'intersezione
		$backToTop.toggleClass('invertito', overlap);
	}
		
	const $window = $(window);
	const $body = $('body');
	// Calcoliamo l'offset una sola volta all'avvio
	const stickyOffset = $("#sticky-header").offset().top; 

	$window.on('scroll', function() {
		// Applica o rimuove la classe in base allo scroll (restituisce true o false)
		const isSticky = $window.scrollTop() > stickyOffset;
		$body.toggleClass('page-is-sticky', isSticky);
	});

});

// Funzione che sposta i menù
function riposizionaMenuDecidim() {
  const header = document.querySelector(".layout-container > header");
  if (!header) return;

  // Riconosce la Home Page anche con le lingue
  const isHomePage = document.body.classList.contains("page-home") || 
                     window.location.pathname === "/" || 
                     /^\/[a-z]{2}\/?$/.test(window.location.pathname);
  
  if (isHomePage) {
    // AGGIORNAMENTO: Cerca #home__menu (o .main-nav per sicurezza)
    const globalMenu = document.querySelector("#home__menu, .main-nav"); 
    
    // Sposta solo se non è già stato spostato
    if (globalMenu && !header.contains(globalMenu)) {
      header.appendChild(globalMenu);
    }
  } else {
    const contextNav = document.querySelector(".process-header__container, .breadcrumb, .nav-container");
    if (contextNav && !header.contains(contextNav)) {
      header.appendChild(contextNav);
    }
  }
}

document.addEventListener("DOMContentLoaded", riposizionaMenuDecidim);
document.addEventListener("turbolinks:load", riposizionaMenuDecidim);
window.addEventListener("load", riposizionaMenuDecidim);