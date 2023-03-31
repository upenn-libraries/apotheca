import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["path", 'select', "list"]

    connect(event) {
        console.log('hello', this.element)
    }

    getPath(){
        return this.pathTarget.value
    }

   getDrive() {
       return this.selectTarget.value
    }

    setList(filenames) {
       this.listTarget.innerText = filenames
    }
    async submit(event){
        // TODO verify drive is selected, otherwise display error message
        event.preventDefault()
        const res = await fetch("/file_listing_tool/file_list", {
            method: "POST",
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({drive: this.getDrive(), path: this.getPath()} )
        })

        //TODO check for unsuccessful http response
        const json = await res.json()

        //TODO handle array of filenames
        this.setList(json.filenames)
    }
}
