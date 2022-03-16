# ORIX SDK
Tools & Macros for Orix devs

## Directories
- asm: Assembly sources
- include:
- macros: SDK Macros
- examples: examples
- bin : binaries/tools
- cfg : cfg for relocbin and cl65

## relocbin uses

Relocbin is a script which convert a static binary (built with telestrat target and cfg included) into a relocatable binary format for orix

You need to build your binary with normal telestrat target :

### cl65 -ttelestrat mysrc.c -o 800

Then build again with your binary with the cfg in cfg/ folder of orix-sdk

### cl65 -ttelestrat --config cfg/telestrat_900.cfg mysrc.c -o 900

usr now relocbin :

python3 relocbin3.py 800 900 2 mybin

At this step, mybin is now a relocatable format which is recognized with kernel v2021.3 only
