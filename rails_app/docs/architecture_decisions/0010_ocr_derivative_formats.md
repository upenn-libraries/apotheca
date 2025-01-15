# Title

OCR Derivatives Formats

## Date

2015-01-14

## Status

`Accepted`

## Context

We need to serve searchable PDFs at the item level. This requires performing OCR on an item's assets and storing ocr
output as derivative files to support current and future feature requirements.

## Decision

1. Use Tesseract to perform OCR and output three additional OCR derivative formats for each asset.
2. Store a text-only PDF containing an invisible layer of extracted text in their original positions.
3. Store a plain text file containing the extracted text.
4. Store an HOCR file containing extracted text and positional data.

## Consequences

1. Use Tesseract to output all the desired derivative formats in a single command.
2. Storing a text-only pdf to reduces the size of the asset PDF and supports composing an item level PDF.
3. Storing a plain text file supports full text search.
4. Storing a robust hocr file supports text overlay features in image viewers.
5. Generating OCR and creating item-level PDF become two separate and distinct processes.
6. Storing these additional OCR derivatives increases the space used in our derivative storage.
