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
    static targets = [
        'spy',
        'spiedElement',
        'oncanvasNavScroller',
        'offcanvasHeader',
        'offcanvasNavScroller'
    ];

    /**
     * Initializes necessary variables for scrollspy implementation
     */
    initialize() {
        this.spiedElement = this.spiedElementTarget;
        this.spy = this.spyTarget;

        this.noSpy = this.element.classList.contains('no-spy');

        if (this.noSpy) return;

        this.scrollSpy = null;
        this.oncanvasNavScroller = this.oncanvasNavScrollerTarget;

        this.offcanvasSpiedElement = window;
        this.offcanvasNavScroller = this.offcanvasNavScrollerTarget;
        this.offcanvasShown = false;

        this.stayActiveParent = null;
        this.stayActiveChild = null;
        this.activeItem = null;
        this.activeChanges = [];

        this.tabHeader = document.querySelector('#assets.tab-pane .header-row');
        this.tabHeader.classList.add('sticky-top', 'bg-white');
        this.activeParent = document.querySelector('.nav-link.parent.active');
        this.activeChild = document.querySelector('.nav-link.child.active');

        Promise.resolve().then(() => {
            this.initScrollSpy();
        })

        // Fires whenever a new scrollspy item becomes active
        document.addEventListener('activate.bs.scrollspy', () => this.monitorActive());
        // Fires when the offcanvas menu is shown
        document.addEventListener('shown.bs.offcanvas', () => this.offcanvasShownHandler());
        // Fires when the offcanvas menu is hidden
        document.addEventListener('hidden.bs.offcanvas', () => this.offcanvasHiddenHandler());
    }

    /**
     * Initialize scrollspy, running once per second until loaded
     */
    initScrollSpy() {
        const intervalId = setInterval(() => {
            this.scrollSpy = new bootstrap.ScrollSpy(this.spiedElement, {
                target: this.spy,
                rootMargin: '0% 0% -75%',
                threshold: [0, .5, 1],
                smoothScroll: true,
                tabindex: -1,
            });

            if (this.confirmScrollSpy()) {
                clearInterval(intervalId); // Stop the interval once confirmScrollSpy is true
            }
        }, 1000); // Run the code every second (1000 milliseconds)
    }

    // Make sure scrollspy got loaded
    confirmScrollSpy() {
        return this.scrollSpy && this.activeItem;
    }

    // Refresh scrollspy after previously hidden elements are displayed
    refreshScrollSpy() {
        if (this.scrollSpy) {
            bootstrap.ScrollSpy.getInstance(this.spiedElement).refresh();
        }
    }

    // Keep track of when the offcanvas menu is shown or hidden
    offcanvasShownHandler = () => {
        this.offcanvasShown = true;
        this.refreshScrollSpy();
    };
    offcanvasHiddenHandler = () => {
        this.offcanvasShown = false;
        this.refreshScrollSpy();
    };

    // Tab header is sticky-top when scrolled past the page header
    isStickyHeader() {
        if (!this.tabHeader) {
            return false;
        }
        return window.scrollY > this.tabHeader.offsetTop - 1;
    }

    // Monitor active scrollspy items
    monitorActive() {
        const newActiveParent = document.querySelector('.nav-link.parent.active');
        const newActiveChild = document.querySelector('.nav-link.child.active');
        const noChildren = newActiveParent ? newActiveParent.nextElementSibling == null : false;
        this.activeChanges = [];

        if (newActiveParent && newActiveParent !== this.activeParent) {
            this.activeChanges.push('parent');
            this.activeParent = newActiveParent;

            if (noChildren) {
                this.activeChanges.push('no children');
                this.activeItem = newActiveParent;
            }
        }

        if ((newActiveChild && newActiveChild !== this.activeChild) && !noChildren) {
            this.activeChanges.push('child');
            this.activeChild = newActiveChild;
            this.activeItem = newActiveChild;

            if (newActiveChild === newActiveChild?.parentElement?.firstElementChild) {
                this.activeItem = this.activeParent;
            }
        }

        this.keepHighlighted();
        this.keepActiveItemInView();
    }

    // Keep the active parent and child highlighted until new ones are assigned
    keepHighlighted() {
        if (this.confirmScrollSpy()) {

            if (this.activeChanges.includes('child')) {
                this.stayActiveChild?.classList.remove('stay-active');
                this.stayActiveChild = this.activeChild;
                this.stayActiveChild?.classList.add('stay-active');
                // Add stay-active class to child's parent too just in case
                this.activeParent?.classList.add('stay-active');
            }

            if (this.activeChanges.includes('parent')) {
                this.stayActiveParent?.classList.remove('stay-active');
                this.stayActiveParent = this.activeParent;
                this.stayActiveParent.classList.add('stay-active');

                if (this.activeChanges.includes('no children')) {
                    this.stayActiveChild?.classList.remove('stay-active');
                }
            }
        }
    }

    // Keep the active nav item in view on screen
    // Scroll in from top if goes out the top, and
    // scroll in from bottom if goes out the bottom
    keepActiveItemInView() {
        const item = this.activeItem;
        let container = this.offcanvasShown
            ? this.offcanvasNavScroller
            : this.oncanvasNavScroller;

        if (!item || !container) return;

        const itemRect = item.getBoundingClientRect();
        const containerRect = container.getBoundingClientRect();

        const containerTop = containerRect.top;
        const containerBottom = Math.min(containerRect.bottom, window.innerHeight);
        const containerVisibleHeight = containerBottom - containerTop;

        // Determine when the active nav item is above or below the visible
        // bounds of the sidebar in order to scroll it back within view
        const isAboveSidebar = this.offcanvasShown
            ? itemRect.top < this.offcanvasHeaderTarget.offsetHeight + 16
            : this.isStickyHeader()
                ? itemRect.top < (containerTop + this.tabHeader.offsetHeight)
                : itemRect.top < containerTop;

        const isBelowSidebar = itemRect.bottom > containerBottom;

        if (isAboveSidebar) {
            // The tab header is sticky once a user scrolls past the main page
            // header, so his accounts for the tab's height in calculating scroll
            container.scrollTop = this.isStickyHeader()
                ? item.offsetTop - this.tabHeader.offsetHeight
                : item.offsetTop;

            // If the main scroller is scrolled all the way to its top,
            // force the sidebar to scroll to its top too
            if (this.spiedElement.scrollTop < 20) {
                container.scrollTo({top: 0, behavior: 'smooth'});
            }
        } else if (isBelowSidebar) {
            container.scrollTo({
                top: item.offsetTop - containerVisibleHeight + item.offsetHeight + 20,
                behavior: 'smooth'
            });
        }
    }
}