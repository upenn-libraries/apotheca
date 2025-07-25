# IIIF Image Derivative

## Date
2025-07-24

## Status
`Accepted`

## Context
For some file formats it's helpful to have an `access` copy _and_ a `iiif_image` (ie, video files). Currently, the pyramidal tiff needed for the IIIF Image service is stored as the `access` copy for images, shifting this to its own derivative type will allow us to be more flexible. This change will allow for any type of asset to have a pyramidal tiff for use in an IIIF Image Server.

## Decision
1. Create `iiif_image` derivative to replace the `access` derivative for images. The `iiif_image` derivative will store the pyramidal titled tiff needed for the IIIF Image server.
2. Migrate all the `access` derivatives for image-based Assets to be an `iiif_image` derivative.
3. Create an `iiif_image` derivative for video files to provide resizable preview images.

## Consequences
1. We will be able to store a `access` derivatives and a `iiif_image` derivative for video files and other non-image content. Because of this change, we will be able to provide larger image derivatives for videos.
2. We will have to account for images-based assets having pyramidal tiffs in both the `access` and `iiif_image` derivative while we migrate to just using the `iiif_image` derivative.
3. We will have to create temporary code to migrate `access` derivatives to be `iiif_image` derivatives. This code must be efficient and should avoid unnecessarily regenerating derivatives.