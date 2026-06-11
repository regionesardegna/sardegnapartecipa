// This file is compiled inside Decidim core pack. Code can be added here and will be executed
// as part of that pack

// Load images
require.context("../../images", true)

window.addEventListener("scroll",function(){
       
       if(window.pageYOffset > 300) {
            if (document.body.clientWidth <= 640){
                document.getElementById("back-to-top").setAttribute("style","bottom: 270px");
            }
            document.getElementById("back-to-top").style.display="block";
       } else {
            document.getElementById("back-to-top").style.display="none";
       }
       
       let sticky = document.getElementById("sticky-header").offsetTop;
       
       if (document.body.clientWidth >= 640){
          if(window.pageYOffset > sticky){
             $('#img-user-icon').attr('style', 'display: none');
             $('#institutional-link').attr('style', 'fontSize: 12px');
             $('#img-gonfalone').attr('style', 'height: 24px');
          }else{
             $('#img-user-icon').attr('style', 'display: inline-block');
             $('#institutional-link').attr('style', 'fontSize: 14px');
             $('#img-gonfalone').attr('style', 'height: 28px');
          }
       }else{
          if(window.pageYOffset > sticky){
             $('#sticky-header').addClass('sticky-header');
             $('#top-header').attr('style', 'height: 28px');
             $('#img-user-icon').attr('style', 'display: none');
             $('#img-gonfalone').attr('style', 'height: 24px');
          }else{
             $('#sticky-header').removeClass('sticky-header');
             $('#top-header').attr('style', 'height:40px');
             $('#img-user-icon').attr('style', 'display: inline-block');
             $('#img-gonfalone').attr('style', 'height: 28px');
          }
       }
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