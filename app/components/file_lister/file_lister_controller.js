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
        this.clear()
        this.filenameListTarget.innerText = filenames
    }

    setError(error){
        this.clear()
        this.errorMessageTarget.innerText = error

    }

    clear(){
        this.filenameListTarget.innerText = ""
        this.errorMessageTarget.innerText= ""
    }
    async submit(event){
        // TODO verify drive is selected, otherwise display error message
        event.preventDefault()
        const response = await fetch("/file_listing_tool/file_list", {
            method: "POST",
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({drive: this.getDrive(), path: this.getPath()} )
        })

        if(!response.ok) {
            return this.setError(response.status)
        }


        const json = await response.json()

        //TODO check for unsuccessful http response

        //TODO check if there's an error on the http response

        if(json.error){
            this.setError(json.error)
        } else if (json.filenames) {
            //TODO handle array of filenames
            this.setDrive(json.drive)
            this.setPath(json.path)
            this.setList(json.filenames)
            this.fileListingFormTarget.hidden = false
        } else {
            this.setError()
        }




    }
}
