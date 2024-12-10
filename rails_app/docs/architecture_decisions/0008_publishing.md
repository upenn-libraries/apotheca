# Publishing

## Date
2024-02-29

## Status
`Accepted`

## Context
Apotheca and Colenda are two separate applications and we need some way for Apotheca to communicate to Colenda which items are to be displayed.

## Decision
1. Apotheca will "publish" out to Colenda by sending a JSON payload that includes descriptive metadata and asset file information.
2. Colenda will serve up original and derivative files using pre-signed AWS S3 URLs.
3. Apotheca will generate the IIIF manifest as part of the publishing process.

## Consequences
1. Potentially allow us to "publish" to other interfaces.
2. JSON payload can be fairly large depending on how many Assets an Item has.
3. IIIIF manifest generation required information about Colenda.
   - Ideally Apotheca will not know anything about the interface it is publishing to, but because we wanted to include links to Colenda in the IIIF manifest, we had to configure details about the endpoint.
   - In the future, we can do more to move the inline values to be configurable.

