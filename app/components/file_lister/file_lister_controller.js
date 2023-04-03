import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["pathInput", "driveSelect", "filenameList", "fileListingForm", "driveResponse", "pathResponse", "errorMessage"]

    connect(event) {
        console.log('hello', this.element)
    }

    getPath(){
        return this.pathInputTarget.value
    }

   getDrive() {
       return this.driveSelectTarget.value
    }

    setDrive(drive){
        this.driveResponseTarget.value = drive
    }

    setPath(path){
        this.pathResponseTarget.value = path
    }

    setList(filenames) {
        this.filenameListTarget.innerText = filenames
    }

    setError(error){
        this.errorMessageTarget.innerText = error
    }

    clear(){
        this.filenameListTarget.innerText = ""
        this.errorMessageTarget.innerText = ""
    }

    copy() {
        navigator.clipboard.writeText(this.filenameListTarget.value)
    }

    async submit(event){
        event.preventDefault()
        this.clear()
        const response = await fetch("/file_listing_tool/file_list", {
            method: "POST",
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({drive: this.getDrive(), path: this.getPath()} )
        })

        const json = await response.json()

        if(!response.ok && json.error){
            this.setError(json.error)
        }

        if (json.filenames) {
            this.setDrive(json.drive)
            this.setPath(json.path)
            this.setList(json.filenames)
            this.fileListingFormTarget.hidden = false
        } else {
            this.fileListingFormTarget.hidden = true
        }
    }
}
