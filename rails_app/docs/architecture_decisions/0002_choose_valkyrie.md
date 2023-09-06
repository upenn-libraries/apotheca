# Choose Valkyrie
   
## Date 
2022-09-01

## Status
`Accepted`

## Context
To start development on the application we needed to choose a framework to define our models and a processes for persisting metadata and files.

## Decision
We've decided to use [Valkyrie](https://github.com/samvera/valkyrie) to presist our metadata to Postgres and our files to S3-compabible object stores. We choose Valkyrie because it is agnostic about what metadata storage and file storage is used. We can easily create additional adapters for metadata or file stores if we decided to use something that's not supported. Additionally when we move our data to a new metadata or file store, Valkyrie has cleary defined paths to do so. We are also inspired by other repositories that make use of the gem and have been successfully managing their data.

## Consequences
1. Gem dependency
   * We will become dependent on this gem, but we feel confident that if it's no longer supported we could incorporate the gem into our codebase or continue to support it.
2. Callbacks for resources 
   * Valkyrie doesn't define a way to apply callbacks when creating/updating/deleting resources. We'll have to implement a new way run those.
3. Data model changes
   * Implementing changes to the data model once we have data in production could prove challenging. If we change the structure of our metadata we will probably have to create internal migrations to move the data to the new structure. This is mitigated by Valkyrie somewhat, because underneath the hood it implements all attributes as multivalued even if when they are single value attributes.
