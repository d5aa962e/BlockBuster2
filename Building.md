# Building Block Buster 2

## BB2.SYSTEM

Block Buster is assembled with Merlin 8.  Load up the dist/BB2-SRC ProDOS volume, load BB2.S into the editor, and assemble.  If successful, BB2.SYSTEM will be saved to the disk.

You'll need an 800k disk drive to mount BB2-SRC.  The PUTs within the BB2.S main file can be easily modified to reference 140k drives if need be.

**Note: The files in the src directory are more for reference than for compiling.  All files needed to build Block Buster can be found on the BB2-SRC disk image.**

## The Help System

The help system is built around an AppleWorks word processor file.  This AWP file is indexed by topic, and Block Buster then uses the index to load the relevant portion of the AWP file to memory.

In a nutshell, AWP Option Codes are use to describe the size of the help window for the particular topic.  Option Codes are as follows:

### Options Related to the Window

- Page Number (PN) - Window Top
- Set a Marker (SM) - Window Left
- Skip Lines (SK) -  Window Height (in lines)
- Platen Width (PW) - Window Width (# of chars = PW-inches * 10)
- New Page (NP) - Starts a new topic
- Page Header (HE) - Text holds the Window Title

If Top or Left numbers are not supplied, then the window is centered around the screen height or width respectively.


### Options Related to Character Formatting

- Enter Keyboard (EK) - Displays the Open Apple character
- Underline (UB/UE) - "underlined" characters are displayed as MouseText
- Boldface (BB/BE) - "boldface" characters are displayed in Inverse
- Special Code (SC) - 1: Displays Block Buster version number

See the Appleworks BB2.HLP word processor file for additional information.

## Building the Help Index

The BASIC program AWP.INDEXER will scan BB2.HLP and produce BB2.IDX.  Both files must be in the same location in order for the help system to work.


