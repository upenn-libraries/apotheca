import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect(event) {
        this.togglePlaceholders()
        this.updateNumbering()
    }

    dragstart(event) {
        event.dataTransfer.setData("application/drag-key", event.target.getAttribute("data-asset-id"))
        event.dataTransfer.effectAllowed = "move"
    }

    dragover(event) {
        event.preventDefault()
        return true
    }

    dragenter(event) {
        event.preventDefault()
    }

    drop(event) {
        const asset_id = event.dataTransfer.getData("application/drag-key")
        const dropTarget = event.target
        const draggedAsset = this.element.querySelector(`[data-asset-id='${asset_id}']`)
        const positionComparison = dropTarget.compareDocumentPosition(draggedAsset)
        if (positionComparison & 4) {
            event.target.closest("div.card").insertAdjacentElement('beforebegin', draggedAsset)
        } else if (positionComparison & 2) {
            event.target.closest("div.card").insertAdjacentElement('afterend', draggedAsset)
        }
        event.preventDefault()
    }

    dragend(event) {
        this.togglePlaceholders()
        this.updateNumbering()
        this.toggleArrangedComponents()
    }

    unorder(event) {
        const unorderedList = document.getElementById("unarranged-assets")
        unorderedList.appendChild(event.target.closest(".asset-card"))
        this.togglePlaceholders()
        this.updateNumbering()
        this.toggleArrangedComponents()
    }

    makeFirst(event) {
        const orderedList = document.getElementById("arranged-assets")
        orderedList.prepend(event.target.closest(".asset-card"))
        this.togglePlaceholders()
        this.updateNumbering()
        this.toggleArrangedComponents()
    }

    makeLast(event) {
        const orderedList = document.getElementById("arranged-assets")
        orderedList.append(event.target.closest(".asset-card"))
        this.togglePlaceholders()
        this.updateNumbering()
        this.toggleArrangedComponents()
    }

    togglePlaceholders() {
        const unorderedList = document.getElementById("unarranged-assets")
        const orderedList = document.getElementById("arranged-assets")
        if(unorderedList.querySelector(".asset-card") && unorderedList.querySelector(".placeholder-card")) {
            unorderedList.querySelector(".placeholder-card").remove()
        } else if (!unorderedList.querySelector(".asset-card") && !unorderedList.querySelector(".placeholder-card")) {
            this.conjurePlaceholder(unorderedList)
        }
        if(orderedList.querySelector(".asset-card") && orderedList.querySelector(".placeholder-card")) {
            orderedList.querySelector(".placeholder-card").remove()
        } else if (!orderedList.querySelector(".asset-card") && !orderedList.querySelector(".placeholder-card")) {
            this.conjurePlaceholder(orderedList)
        }
    }

    conjurePlaceholder(list) {
        const message = list.dataset.emptyMessage
        const placeholder = document.createElement("div")
        const placeholderBody = document.createElement("div")
        placeholder.className = "card placeholder-card border border-3 rounded-1"
        placeholderBody.className = "card-body"
        placeholderBody.innerText = message
        placeholder.appendChild(placeholderBody)
        list.insertAdjacentElement("afterbegin", placeholder)
    }

    updateNumbering() {
        const orderedList = document.getElementById("arranged-assets")
        const unorderedList = document.getElementById("unarranged-assets")
        const unordered_nums = unorderedList.querySelectorAll('span.asset-order-number')
        const ordered_nums = orderedList.querySelectorAll('span.asset-order-number')
        unordered_nums.forEach(function (badge_span, index) {
            badge_span.innerText = ''
        })
        ordered_nums.forEach(function (badge_span, index) {
            badge_span.innerText = index + 1
        })
    }

    toggleArrangedComponents() {
        const orderedList = document.getElementById("arranged-assets")
        const unorderedList = document.getElementById("unarranged-assets")
        //hide all function links in unordered
        unorderedList.querySelectorAll('.arranged-shortcut-buttons').forEach(function (element) {
            element.classList.add('visually-hidden')
        })
        //disable all hidden fields in unordered
        unorderedList.querySelectorAll('.asset-id-input').forEach(function (element) {
            element.disabled = true
        })
        //show all function links in ordered
        orderedList.querySelectorAll('.arranged-shortcut-buttons').forEach(function (element) {
            element.classList.remove('visually-hidden')
        })
        //enable all hidden fields in ordered
        orderedList.querySelectorAll('.asset-id-input').forEach(function (element) {
            element.disabled = false
        })
    }
}
