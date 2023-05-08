import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
    static targets = [
        'filenameList',
        'extractedFilenamesForm',
        'extractedFilenamesDrive',
        'extractedFilenamesPath',
        'errorMessage',
    ];

    setDrive(drive) {
        this.extractedFilenamesDriveTarget.value = drive;
    }

    setPath(path) {
        this.extractedFilenamesPathTarget.value = path;
    }

    setList(filenames) {
        this.filenameListTarget.innerText = filenames;
    }

    setError(error) {
        this.errorMessageTarget.innerText = error;
    }

    clearErrorMessage() {
        this.errorMessageTarget.innerText = '';
    }

    copy() {
        navigator.clipboard.writeText(this.filenameListTarget.innerText);
    }

    disableButtons() {
        document.getElementById('copy-button').disabled = true
        document.getElementById('export-button').disabled = true
    }

    enableButtons() {
        document.getElementById('copy-button').disabled = false
        document.getElementById('export-button').disabled = false
    }

    async getFilenames(formData) {
        const response = await fetch(event.target.action, {
            method: 'POST',
            headers: {
                Accept: 'application/json',
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(Object.fromEntries(formData)),
        });

        if(!response.ok && response.status !== 422) {
            throw Error(`Something Went Wrong: ${response.status}`)
        }

       return await response.json();
    }

    async submit(event) {
        event.preventDefault();
        this.clearErrorMessage();

        const formData = new FormData(event.target, event.submitter)
        try {
            const json = await this.getFilenames(formData);

            if (json.error) throw Error(json.error);
            this.setDrive(json.drive);
            this.setPath(json.path);
            this.setList(json.filenames);
            this.extractedFilenamesFormTarget.hidden = false;
            if (!json.filenames) {
                this.filenameListTarget.innerText = 'That path has no files. This may be the case if the specified path contains only directories.'
                this.disableButtons()
            } else {
                this.enableButtons()
            }
        } catch(error) {
            this.setError(error.message)
            this.extractedFilenamesFormTarget.hidden = true;
        }
    }
}
