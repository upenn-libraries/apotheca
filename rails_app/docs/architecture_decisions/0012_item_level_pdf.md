# Title

Item Level PDF

## Date

2025-01-14

## Status

`Accepted`

## Context

We need to serve searchable item level PDFs to clients on the front end. The pages of the item level PDF
should reflect the order of the item's arranged assets.

## Decision

1. Use VIPS to generate a temporary derivative JPEG for each asset.
2. Use HexaPDF to build item level PDF and combine temporary JPEGs with existing text-only PDFs.
3. Generate item level PDF after a successful publish enqueue job.
4. Store the item level PDF in the derivatives storage.

## Consequences

1. Leverages existing VIPS installation for image processing.
2. Supports creating a cover page, bookmarks, and labels for PDFs.
3. Publish job will not be slowed down by PDF generation.
4. Requires using more derivative storage space.
