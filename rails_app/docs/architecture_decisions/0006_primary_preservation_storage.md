# Primary Preservation Storage

## Date
2023-12-15

## Status
`Accepted`

## Context
Our previous implementation used a locally hosted Ceph storage cluster. It created a bucket for each item and this proved to be unsustainable. As part of our migration to Apotheca, we'll have to migrate the content into a new structure so it's a good time to consider alternative storage solutions.

## Decision
1. Use AWS S3 as our primary preservation storage.
2. Use an AWS region in the eastern United States. 

## Consequences
1. Reduced maintenance of a locally-hosted storage cluster.
2. $$$$$
   - AWS S3 storage costs can fluctuate and be hard to estimate, but we think the trade-off of reduced maintenance is worth it. Internally, AWS S3 is replacing a lot of previously locally-hosted storage solutions.
3. AWS S3 should provide better uptime and availability, while reducing the need for staff expertise with high-availability local storage.
