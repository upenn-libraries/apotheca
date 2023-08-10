import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
    /*
     * spy = #assets-nav
     * spiedElement = #assets-cards
     * oncanvasNavScroller = #assets-sidebar
     * oncanvasTargetScroller = spiedElement
     * offcanvasHeader = .offcanvas-header
     * offcanvasNavScroller = .offcanvas-body
     * offcanvasSpiedElementScroller = document.body
     */
    static targets = ['mainContent', 'sidebar'];

    /**
     * Initializes necessary variables for scrollspy implementation
     */
    initialize() {
        this.mainContent = this.mainContentTarget;
        this.sidebar = this.sidebarTarget;

        this.tabHeader = document.querySelector('#assets.tab-pane .header-row');
        this.tabHeader.classList.add('sticky-top', 'bg-white');

        this.tabContainer = document.querySelector('#assets.tab-pane');

        this.offcanvasShown = false;

        // Fires when the offcanvas menu is shown
        document.addEventListener('shown.bs.offcanvas', () => this.offcanvasShownHandler());
        // Fires when the offcanvas menu is hidden
        document.addEventListener('hidden.bs.offcanvas', () => this.offcanvasHiddenHandler());
    }

    // Tab header is sticky-top when scrolled past the page header
    // isStickyHeader() {
    //     if (!this.tabHeader) {
    //         return false;
    //     }
    //     return window.scrollY > this.tabHeader.getBoundingClientRect().top;
    // }

    // Keep track of when the offcanvas menu is shown or hidden
    offcanvasShownHandler = () => {
        this.offcanvasShown = true;
    };
    offcanvasHiddenHandler = () => {
        this.offcanvasShown = false;
    };

    isScrolledPast(element, container = window) {
        return window.scrollY > element.offsetTop
    }

    scrollToTop(event) {
        event.preventDefault();
        const clickedLink = event.target.getAttribute('href');
        const targetTitle = document.querySelector(clickedLink);
        const siteHeader = document.getElementById('site-header');

        if (this.offcanvasShown) {
            window.scrollTo({
                behavior: 'smooth',
                top: targetTitle.getBoundingClientRect().top - document.body.getBoundingClientRect().top - siteHeader.offsetHeight,
            });
        } else {
            const headerShown = !this.isScrolledPast(this.tabContainer, window);
            if (headerShown) {
                this.mainContent?.scrollTo({
                    behavior: 'smooth', top: targetTitle.offsetTop,
                });
            } else {
                this.mainContent?.scrollTo({
                    behavior: 'smooth', top: targetTitle.offsetTop - siteHeader.offsetHeight
                })
            }
        }
    }
}