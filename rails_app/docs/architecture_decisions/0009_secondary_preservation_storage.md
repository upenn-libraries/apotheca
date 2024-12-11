# Secondary Preservation Storage

## Date
2024-10-01

## Status
`Accepted`

## Context
It has always been a goal of our repository infrastructure to store a secondary copy of our preservation files in a second location. Now that we have moved to storing our primary preservation copy in AWS S3 we would like to keep a secondary copy in a second cloud solution. At this time, we should also consider whether we should add preservation events for actions completed in the secondary storage location.

## Decision
1. Using [Wasabi](https://wasabi.com/) to store a secondary copy of all of our preservation files. 
2. Add preservation events when data replicated in Wasabi.
3. Ensure the files stored in Wasabi are in a different geographic region than our primary preservation copies. We'll use the `us-west-1` region for Wasabi.
4. Our primary preservation file and replicated preservation file will have the same filename.

## Consequences

1. Wasabi provides a S3-compatible endpoint which will make it easy to support because S3 endpoints are widely supported by various Ruby libraries. We shied away from storage solutions that had "custom" endpoints (like Azure) because the Ruby tooling was limited and we predicted that it would be hard to support.
2. Wasabi includes egress and ingress cost in their base price, so we will be able to conduct fixity checking without worrying about costs.
3. By having the replicated preservation file have the same filename as the primary preservation file, it will reduce confusion, make it easier to restore files and make it easier to switch between primary and secondary file stores.
