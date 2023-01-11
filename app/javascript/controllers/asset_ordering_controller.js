import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [ "arrangedList", "unarrangedList" ]

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
            dropTarget.closest("div.card").insertAdjacentElement('beforebegin', draggedAsset)
        } else if (positionComparison & 2) {
            dropTarget.closest("div.card").insertAdjacentElement('afterend', draggedAsset)
        }
        event.preventDefault()
    }

    dragend(event) {
        this.refreshLists()
    }

    unorder(event) {
        this.unarrangedListTarget.appendChild(event.target.closest(".asset-card"))
        this.refreshLists()
    }

    makeFirst(event) {
        this.arrangedListTarget.prepend(event.target.closest(".asset-card"))
        this.refreshLists()
    }

    makeLast(event) {
        // const orderedList = document.getElementById("arranged-assets")
        this.arrangedListTarget.append(event.target.closest(".asset-card"))
        this.refresh()
    }

    togglePlaceholders() {
        const unarrangedList = this.unarrangedListTarget
        const arrangedList = this.arrangedListTarget
        if(unarrangedList.querySelector(".asset-card") && unarrangedList.querySelector(".placeholder-card")) {
            unarrangedList.querySelector(".placeholder-card").remove()
        } else if (!unarrangedList.querySelector(".asset-card") && !unarrangedList.querySelector(".placeholder-card")) {
            this.conjurePlaceholder(unarrangedList)
        }
        if(arrangedList.querySelector(".asset-card") && arrangedList.querySelector(".placeholder-card")) {
            arrangedList.querySelector(".placeholder-card").remove()
        } else if (!arrangedList.querySelector(".asset-card") && !arrangedList.querySelector(".placeholder-card")) {
            this.conjurePlaceholder(arrangedList)
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
        // TODO: unarranged placeholder should include empty array value as hidden field
    }

    updateNumbering() {
        const unordered_nums = this.unarrangedListTarget.querySelectorAll('span.asset-order-number')
        const ordered_nums = this.arrangedListTarget.querySelectorAll('span.asset-order-number')
        unordered_nums.forEach(function (badge_span) {
            badge_span.innerText = ''
        })
        ordered_nums.forEach(function (badge_span, index) {
            badge_span.innerText = index + 1
        })
    }

    toggleArrangedComponents() {
        // hide all function links in unordered
        this.unarrangedListTarget.querySelectorAll('.arranged-shortcut-buttons').forEach(function (element) {
            element.classList.add('visually-hidden')
        })
        // disable all hidden fields in unordered
        this.unarrangedListTarget.querySelectorAll('.asset-id-input').forEach(function (element) {
            element.disabled = true
        })
        // show all function links in ordered
        this.arrangedListTarget.querySelectorAll('.arranged-shortcut-buttons').forEach(function (element) {
            element.classList.remove('visually-hidden')
        })
        // enable all hidden fields in ordered
        this.arrangedListTarget.querySelectorAll('.asset-id-input').forEach(function (element) {
            element.disabled = false
        })
    }

    refreshLists() {
        this.togglePlaceholders()
        this.updateNumbering()
        this.toggleArrangedComponents()
    }
}
