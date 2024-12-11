# Metadata Storage

## Date
2023-07-23

## Status
`Accepted`

## Context
As part of our work to implement Valkyrie in Apotheca, we need to choose what metadata storage solutions to use. We must also consider where and how to store additional bibliographic metadata from the ILS for inclusion in the Apotheca record.

## Decision
1. Use Postgres as primary metadata store.
2. Use Solr as an additional metadata store that is used primarily for searching.
3. Postgres will store only original metadata created for Apotheca. The Solr record will merge in the additional metadata from Alma. 

## Consequences
1. We will not be able to retrieve Alma metadata from Postgres. We will only be able to access it by querying Solr. 
2. To make complex queries we'll have to create custom JSONB queries.
   - While this is a new syntax we have to learn, Postgres JSONB queries can be incredibly powerful and allow us the most flexibility out of the available Valkyrie metadata adapters.
