rem 0) Full backup
rem rsync.exe -av --no-super --delete /cygdrive/j/PDMS_Master/_Start /cygdrive/d/_Backup/backup0
rem 1) Incremental backup
rsync.exe -av --no-super --delete --link-dest=/cygdrive/d/_Backup/backup0 /cygdrive/j/PDMS_Master/_Start /cygdrive/d/_Backup/backup1
