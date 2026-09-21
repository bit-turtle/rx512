# rx512 arch

## BRAM Layout (8kb total)
* 1kb cache
  * 512 byte instruction cache
  * 512 byte data cache
* 3kb GPU mem
* 4kb General Purpose Memory

## Initialization Steps
1. Initialize SDHC card
2. Load first sector into instruction cache
3. Enable CPU
