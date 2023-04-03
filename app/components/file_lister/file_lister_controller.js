import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["pathInput", "driveSelect", "filenameList"]

    connect(event) {
        console.log('hello', this.element)
    }

    getPath(){
        return this.pathInputTarget.value
    }

   getDrive() {
       return this.driveSelectTarget.value
    }

    setList(filenames) {
       this.filenameListTarget.innerText = filenames
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
