# IIIF Image Server

## Date
2024-02-01

## Status
`Accepted`

## Context
In order for images to load quickly and efficiently, we need to provide a IIIF Image server that serves up the images requested. Colenda uses a locally-hosted [Cantaloupe](https://cantaloupe-project.github.io/) instance to serve up our images. Colenda images load slowly because the derivative files provided to Cantaloupe are JPEGs instead of JP2s or Pyramidal TIFFs. As we reimplement this, we should create a more efficient image derivative. 

## Decision
1. Use `serverless-iiif` to serve up our images. `serverless-iiif` is an AWS Lambda that uses [iiif-processor](https://www.npmjs.com/package/iiif-processor), a Node module that implements the IIIF image API, to serve up images hosted in AWS S3.
2. Generate pyramidal-tiled TIFFs as our access derivative for images.

## Consequences
1. By using `serverless-iiif`, we will no longer have the overheard of maintaining a locally hosted IIIF image server.
2. `serverless-iiif` is an AWS Lambda, in order to run this service we will have to have more local expertise of AWS. We are already moving in this direction since we are using AWS S3 as are primary storage layer. 
3. We'll have to pay-per-request. Peer institutions (that have more content than we currently do) have shared that the costs are minimal. Since we are already storing our derivatives in AWS S3 with any solution we used we were going to pay for egress. 
