import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
    /*
     * mainContent  = #assets-cards
     * sidebar      = #assets-sidebar
     */
    static targets = ['mainContent', 'sidebar'];

    /**
     * Initializes necessary variables to monitor the scroll position of
     * elements within scrollable sections of a scrollable page
     */
    initialize() {
        // Main content area of the assets list (#assets-cards)
        this.mainContent = this.mainContentTarget;

        // Sidebar navigation area of the assets list (#assets-sidebar)
        this.sidebar = this.sidebarTarget;

        // Row of tabs on the Item show page, above the tab container
        this.tabHeader = document.querySelector('#assets.tab-pane .header-row');
        this.tabHeader.classList.add('sticky-top', 'bg-white');

        // Site wide sticky alert header
        this.alertHeader =  document.querySelector('.header-alert')

        // Prevent sticky tabHeader from overlapping with sticky alertHeader
        // Adjust the top offset of tabHeader if alertHeader exists
        if (this.alertHeader) {
            this.tabHeader.style.top= this.alertHeader.offsetHeight + 'px'
        }

        // Tab container for the assets tab of the Item show page
        // (not including the tabs themselves)
        this.tabContainer = document.querySelector('#assets.tab-pane');

        // Is the offcanvas menu shown (small screen)?
        this.offcanvasShown = false;

        // Fires when the offcanvas menu is shown
        document.addEventListener('shown.bs.offcanvas', () => {
            this.offcanvasShown = true;
        });
        // Fires when the offcanvas menu is hidden
        document.addEventListener('hidden.bs.offcanvas', () => {
            this.offcanvasShown = false;
        });

        // Remove the horizontal rule from under the last asset, because
        // we stretch that section to allow for scrolling the page to the top
        const lastAsset = document.querySelector('#assets-list-container.spy ' +
            '#assets-cards .assets-cards-section:last-of-type .asset-row:last-of-type');
        if (lastAsset && lastAsset.nextElementSibling.tagName === 'HR') {
            lastAsset.nextElementSibling.remove();
        }
    }

    /**
     * Calculate the height of an element including padding, borders, and margins
     *
     * @param element
     */
    getOuterHeight(element) {
        // return 0 if element is falsy
        if (!element) { return 0 }

        // Get the css styles that have been applied to the element
        const computedStyles = window.getComputedStyle(element);

        // Calculate its total height, including margins
        return element.offsetHeight + parseInt(computedStyles.marginTop) + parseInt(computedStyles.marginBottom);
    }

    /**
     * Determines if element has been scrolled past
     * (gone out the top of its container)
     *
     * Used to check if the page header is still visible or a sticky header
     * has taken over
     *
     * @param element
     * @param container
     * @returns {boolean}
     */
    isScrolledPast(element, container = window) {
        return window.scrollY > element.offsetTop
    }

    /**
     * Scrolls elements in the main content area of the assets tab to the top
     * of their container, taking into account the sticky tab header that takes
     * over when the containing page is scrolled past its default header
     *
     * @param {Event} event
     *     The click event on a sidebar navigation link
     */
    scrollToTop(event) {
        event.preventDefault();

        // Link clicked in the nav sidebar
        const clickedLink = event.target.getAttribute('href');

        // Target element's title in the main container, to know what to scroll
        // to the top
        const targetTitle = document.querySelector(clickedLink);

        if (this.offcanvasShown) {
            // If on a smaller screen (nav is in offcanvas), take into account
            // the height of the sticky tab header that appears
            window.scrollTo({
                behavior: "smooth",
                top:
                    targetTitle.getBoundingClientRect().top -
                    document.body.getBoundingClientRect().top -
                    this.getOuterHeight(this.alertHeader) -
                    this.getOuterHeight(this.tabHeader),
            });
        } else {
            // If on a larger screen, check if the page header is still visible
            const headerShown = !this.isScrolledPast(this.tabContainer, window);

            if (headerShown) {
                // If it is, scroll to the top of the main content's container
                this.mainContent?.scrollTo({
                    behavior: 'smooth',
                    top: targetTitle.offsetTop,
                });
            } else {
                // If not, the sticky tab header is active, so take the tab
                // header's height and alertHeader's height into account in determining the top of
                // the container
                this.mainContent?.scrollTo({
                    behavior: 'smooth',
                    top:
                        targetTitle.offsetTop -
                        this.getOuterHeight(this.alertHeader) -
                        this.getOuterHeight(this.tabHeader)
                });
            }
        }
    }
}