# Get-DuplicateFiles

[![github-actions](https://github.com/theohbrothers/Get-DuplicateFiles/workflows/ci-master-pr/badge.svg)](https://github.com/theohbrothers/Get-DuplicateFiles/actions)
[![github-release](https://img.shields.io/github/v/release/theohbrothers/Get-DuplicateFiles?style=flat-square)](https://github.com/theohbrothers/Get-DuplicateFiles/releases/)

A script to locate duplicate files between two sets of folders (e.g. source folders vs. other folders).

It is common to have two or more folders with duplicate files, whether the files were purposedly, accidentally, or unknowingly created. This script helps to locate those duplicate files, so follow-up action can be taken on them.

While this script is similar to [Get-DuplicateItem](https://github.com/theohbrothers/Get-DuplicateItem), `Get-DuplicateItem` is limited to a search scope of a single folder, and does not allow controling the duplicate criteria. In general, dealing with duplicate files is an interactive and very case-specific process, so a script that is easily editable and extensible is a better solution than a module like `Get-DuplicateItem`.

## How it works

- Define the duplicate criteria to include any of the following: File name, file size, file hash, and date modified:
- Searches two groups of folders (i.e. source and other) for all descendent files.
- Compares files of the two groups of folders, identifying duplicates using the criteria you defined
- Finally, exports duplicates into a `duplicates.json` file.

## `duplicates.json`

The key is a dash-delimited string of the duplicate criteria. The value is an array, with the first item being the source file, and the rest being duplicate files. The date modified key is in [`ISO 8601`](https://www.iso.org/iso-8601-date-and-time-format.html) format.

Example of a duplicate criteria: File name, file size, file hash, and date modified:

```json
{
    "README.md-2103-5F0F47C3F7434A4E77B53C78B0782CFDC1B67C5407172BB6D0276EEEB31EBC83-2021-08-18 01:47:32 +0000": [
        "C:\\path\\to\\source folder\\README.md", // The first file is the source file.
        "C:\\path\\to\\other folder\\README.md", // The rest are duplicates.
        ...
    ],
    ...
}
```
