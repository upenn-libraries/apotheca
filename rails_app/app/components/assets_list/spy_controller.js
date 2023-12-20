import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
    /*
     * spy = #assets-nav
     * spiedElement = #assets-cards
     * oncanvasNavScroller = #assets-sidebar
     * oncanvasTargetScroller = spiedElement
     * offcanvasHeader = .offcanvas-header
     * offcanvasNavScroller = .offcanvas-body
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
        // Item being watched by scrollspy (#assets-cards)
        this.spiedElement = this.spiedElementTarget;
        // Item responding to changes in spied element (#assets-nav)
        this.spy = this.spyTarget;

        // Scrollspy not being used (< 8 assets)
        this.noSpy = this.element.classList.contains('no-spy');

        // If not using scrollspy, don't initialize
        if (this.noSpy) return;

        this.scrollSpy = null;

        // Scrolling element of the navigation sidebar on
        // large screens (#assets-sidebar)
        this.oncanvasNavScroller = this.oncanvasNavScrollerTarget;

        // Scrolling element of the navigation sidebar on
        // small screens (.offcanvas-body)
        this.offcanvasNavScroller = this.offcanvasNavScrollerTarget;
        this.offcanvasShown = false;

        // Active parent and child nav items as assigned by scrollspy
        this.activeParent = document.querySelector('.nav-link.parent.active');
        this.activeChild = document.querySelector('.nav-link.child.active');

        // Elements that we want to keep active until another element is made
        // active by scrollspy
        this.stayActiveParent = null;
        this.stayActiveChild = null;

        // Navigation item that we care most about when keeping the active nav
        // item on screen (child if active child exists, otherwise parent)
        this.activeItem = null;
        this.activeChanges = [];

        // Row of tabs on the Item show page, above the tab container
        this.tabHeader = document.querySelector('#assets.tab-pane .header-row');
        this.tabHeader.classList.add('sticky-top', 'bg-white');

        // Site wide sticky alert header - not always present on the page
        this.alertHeader = document.querySelector('.header-alert')

        // Initialize scrollspy once the spy controller is loaded
        Promise.resolve().then(() => {
            this.initScrollSpy();
        })

        // Fires whenever a new scrollspy item becomes active
        document.addEventListener('activate.bs.scrollspy', () =>
            this.monitorActive()
        );

        // Fires when the offcanvas menu is shown
        document.addEventListener('shown.bs.offcanvas', () =>
            this.offcanvasShownHandler()
        );
        // Fires when the offcanvas menu is hidden
        document.addEventListener('hidden.bs.offcanvas', () =>
            this.offcanvasHiddenHandler()
        );
    }

    /**
     * Initialize scrollspy, running once per second until confirm loaded
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
                // Stop the interval once confirmScrollSpy is true
                clearInterval(intervalId);
            }
        }, 1000);
    }

    // Check that scrollspy is active and there's a highlighted nav item
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
    // Refresh scrollspy upon offcanvas state change
    offcanvasShownHandler = () => {
        this.offcanvasShown = true;
        this.refreshScrollSpy();
    };
    offcanvasHiddenHandler = () => {
        this.offcanvasShown = false;
        this.refreshScrollSpy();
    };

    // retrieve offsetHeight value of potential alertHeader, returning 0 if it is not present on page
    alertHeaderOffsetHeight() {
        return this.alertHeader?.offsetHeight || 0
    }

    // Tab header is sticky-top when scrolled past the page header, taking the height of the sticky alertHeader
    // into account
    isStickyHeader() {
        if (!this.tabHeader) {
            return false;
        }
        return window.scrollY > this.tabHeader.offsetTop - this.alertHeaderOffsetHeight() - 1;
    }

    // Monitor active scrollspy items in the sidebar nav
    // Called upon every scrollspy change (activate.bs.scrollspy)
    monitorActive() {

        // Currently active parent and child nav items as assigned by scrollspy
        const newActiveParent = document.querySelector('.nav-link.parent.active');
        const newActiveChild = document.querySelector('.nav-link.child.active');

        // If there's a new active parent but it doesn't have any sibling
        // subnav, it's an empty nav section (ex: no unarranged assets)
        const noChildren = newActiveParent ?
            newActiveParent.nextElementSibling == null : false;

        // Keep track of what changed
        this.activeChanges = [];

        // New active parent nav item that's different from the one we have saved
        if (newActiveParent && newActiveParent !== this.activeParent) {
            // Track that there's a new active parent element
            this.activeChanges.push('parent');
            // Save the new parent as our active parent
            this.activeParent = newActiveParent;

            // If the new parent is for an empty nav section
            if (noChildren) {
                // Track that there are no child nav items in this update
                this.activeChanges.push('no children');
                // Save the new parent as the item we care most about keeping in view
                this.activeItem = newActiveParent;
            }
        }

        // If there's a new active child that's different from the one we have saved
        // and the active parent has child elements
        if ((newActiveChild && newActiveChild !== this.activeChild) && !noChildren) {
            // Track that there's a new active child element
            this.activeChanges.push('child');
            // Save the new child as our active child
            this.activeChild = newActiveChild;
            // Save the new child as the item we care most about keeping in view
            this.activeItem = newActiveChild;

            // If the new active child is the first element in its parent list,
            // set its parent as the item to keep in view (otherwise the parent
            // isn't reached by scrolling)
            if (newActiveChild === newActiveChild?.parentElement?.firstElementChild) {
                this.activeItem = this.activeParent;
            }
        }

        // Keep the active items highlighted until new ones are assigned
        this.keepHighlighted();
        // Keep the most important active item in view
        // (Tracked using activeItem as opposed to activeParent/Child)
        this.keepActiveItemInView();
    }

    // Keep the active parent and child highlighted until new ones are assigned
    keepHighlighted() {
        if (this.confirmScrollSpy()) {
            // If there's a new active child
            if (this.activeChanges.includes('child')) {
                // Remove the highlight from the old active child
                this.stayActiveChild?.classList.remove('stay-active');
                // Save the new active child as an item to keep highlighted
                // until a new one is assigned
                this.stayActiveChild = this.activeChild;
                // Give it the necessary class to stay highlighted, along
                // with its parent (just to be safe)
                this.stayActiveChild?.classList.add('stay-active');
                this.activeParent?.classList.add('stay-active');
            }

            // If there's a new active parent
            if (this.activeChanges.includes('parent')) {
                // Remove the highlight from the old active parent
                this.stayActiveParent?.classList.remove('stay-active');
                // Save the new active parent as an item to keep highlighted
                this.stayActiveParent = this.activeParent;
                // Give it the necessary class to stay highlighted
                this.stayActiveParent.classList.add('stay-active');

                // If there are no child nav items
                if (this.activeChanges.includes('no children')) {
                    // Remove the stay-active class from any active children
                    this.stayActiveChild?.classList.remove('stay-active');
                }
            }
        }
    }

    /**
     * Keep the active nav item in view on screen
     *
     * Scroll in from the top if it goes out the top, and scroll in from the
     * bottom if it goes out the bottom
     */
    keepActiveItemInView() {
        // The item we've determined most important to keep in view
        const item = this.activeItem;

        // If the offcanvas is shown (small screen), the scrolling element of
        // the sidebar navigation is .offcanvas-body, but on a larger screen
        // the scrolling element is #assets-sidebar
        let container = this.offcanvasShown
            ? this.offcanvasNavScroller
            : this.oncanvasNavScroller;

        // If for some reason there isn't an item or a container, stop here
        if (!item || !container) return;

        // Bounding rectangles of the active item and its container
        const itemRect = item.getBoundingClientRect();
        const containerRect = container.getBoundingClientRect();

        // Top and bottom of the container
        const containerTop = containerRect.top;
        const containerBottom = Math.min(containerRect.bottom, window.innerHeight);

        // Height of the visible portion of the nav container (because the nav
        // is scrollable beyond the top and bottom of the visible sidebar)
        const containerVisibleHeight = containerBottom - containerTop;

        // Determine when the active nav item is above or below the visible
        // bounds of the sidebar in order to scroll it back within view
        //
        // If the offcanvas menu is being used, take into account the sticky
        // heading that appears at its top
        //
        // If on a larger screen, otherwise if the main page header area is
        // still on screen, we only need to check if the item is above its
        // container
        //
        // But if the sticky header has taken over, we need to
        // take the height of it and the alertHeader into account
        const isAboveSidebar = this.offcanvasShown
            ? itemRect.top < this.offcanvasHeaderTarget.offsetHeight + 16
            : this.isStickyHeader()
                ? itemRect.top < (containerTop + this.tabHeader.offsetHeight + this.alertHeaderOffsetHeight())
                : itemRect.top < containerTop;

        // Determine when the active item has gone out the bottom of its
        // visible container
        const isBelowSidebar = itemRect.bottom > containerBottom;

        // Handle when the active item has gone out the top of its visible
        // container, scrolling it down from the top
        if (isAboveSidebar) {
            // The tab header is sticky once a user scrolls past the main page
            // header, so account for the tab header's and alertHeader's height in calculating
            // where the top is
            container.scrollTop = this.isStickyHeader()
                ? item.offsetTop - (this.tabHeader.offsetHeight + this.alertHeaderOffsetHeight())
                : item.offsetTop;

            // If the main scroller is scrolled all the way to its top,
            // force the sidebar to scroll to its top too
            //
            // Otherwise the main container reaches its top before the sidebar
            // is able to
            if (this.spiedElement.scrollTop < 20) {
                container.scrollTo({top: 0, behavior: 'smooth'});
            }
        }
        // Handle when the active item has gone out the bottom of its visible
        // container, scrolling it up from the bottom
        else if (isBelowSidebar) {
            // Calculate position and scroll the bottom of the item to be the
            // bottom of the nav container, taking into account the visible
            // portion of the container and the item's height
            container.scrollTo({
                top: item.offsetTop - containerVisibleHeight + item.offsetHeight + 20,
                behavior: 'smooth'
            });
        }
    }
}