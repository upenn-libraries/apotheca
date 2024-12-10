# Metadata Storage

## Date
2023-07-23

## Status
`Accepted`

## Context
As part of our work to implement Valkyrie in Apotheca, we need to choose what metadata storage solutions to use.

## Decision
1. Use Postgres as primary metadata store.
2. Use Solr as an additional metadata store that is used primarily for searching.
3. Only Solr will merge in the additional metadata from Alma. Postgres will only store original metadata created for Apotheca.

## Consequences
1. We will not be able to retrieve Alma metadata from Postgres. We will only be able to access it by querying Solr. 
2. To make complex queries we'll have to create custom JSONB queries.
   - While this is a new syntax we have to learn, Postgres JSONB queries can be incredibly powerful and allow us the most flexibility out of the available Valkyrie metadata adapters.
