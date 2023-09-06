# Create Descriptive Metadata Structure
   
## Date
2023-06-20

## Status
`Accepted`

## Context
This application will expand on the descriptive metadata schema that is provided in Colenda. It will add the ability to add URIs for selected fields and define a role for each name.

## Decision
The descriptive metadata schema in this application will define each top level field as an array of hashes. Each hash will minimally contain a `value` key defining the value of that entry. Additionally some fields may also have a `uri` field. Name will contain both a `uri` and `role` subfield. Though this change adds more complexity to the structure of our metadata it will make it easier to make changes to the fields. Below is the new structure written in json:

```json
{
   "title": [{ "value": "Rondo for the piano forte : introduced in the German comedy of The three suitors" }],
   "subject" [{ "value": "Rondos (Piano)", "uri": "http://id.loc.gov/authorities/subjects/sh85115272" }],
   "name": [
     {
       "value": "Holst, M. (Matthias), 1767-1854.", 
       "uri": "http://id.loc.gov/authorities/names/no92011485", 
       "role": [{ "value": "Creator", "uri": "https://id.loc.gov/vocabulary/relators/cre" }] 
     }
   ] 
 }
```

## Consequences
1. Bulk import headers
   * The column headers for bulk import will get longer. Each descriptive metadata field will have to end in the `.value` or `.uri`.
   * The added complexity of the metadata schema could make it harder to train staff.
2. Adding subfields
   * It will be easier to add subfields if necesary. For example, imagine a case were we wanted to add a `type` subfield for each identifier, the new schema structure could support that without much of a hassel. Or imagine the case where we needed to add a `uri` subfield to a metadata field that was not original supporting URIs.
