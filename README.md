# keeper.git
This is a bash script utility that backs up or loads
the files that you specify to wherever you specify

(on testing stages, no main function or restore abilities)

<p align="center">
  <img src="https://img.shields.io/github/repo-size/nonomain/keeper?style=for-the-badge">
</p>

# How to use?
Examples
```sh
# backup starting from my current directory to backup.zip
./keeper.sh -b [options] -t backup.zip
# backup starting from a specific directory to backup.zip
./keeper.sh -b [options] -t backup.zip -f <specific directory>

# restore my backup.zip to home directory
./keeper.sh -r [options] -f backup.zip
# restore my backup.zip to specific directory
./keeper.sh -r [options] -f backup.zip -t <specific directory>
```

Usage
```
Usage: keeper.sh [options]
-h, --help           show this help message
-b, --backup         backup option [requires -t]
-r, --restore        restore option [requires -f]
-f, --from <path>    in case of restore, specify the backup file
                     in case of backup its optional, specify the directory to start from [default=\$PWD]
-t, --to <path>      in case of backup, specify the name of the backup file
                     in case of restore its optional, specify the directory to restore to [default=\$PWD]
Optional:
--no-confirm         don't ask for confirmation before executing the backup/restore
--preview            preview the information about the backup/restore
--profile <profile>  backup profile (what files to backup), default is 'default'
```

# What can be backed up?
Everything! I use it to back up an entire template home
directories for quickly setting up a user when going onto a new machine
including wallpapers and programs preferences.
It comes with a few templates so you can use them or learn
from them how to create your own.

# Features
- [x] different archive types (.zip, .tar.gz)
- [x] execute purely from command line arguments
- [x] test if a certain [external] archive is valid
- [x] support other backup profiles
- [x] choose a backup profile
- [ ] preview archive information
- [ ] use backup profiles also to restore (instead of just restoring everything that inside)
- [ ] edit the content when restoring a backup according to the new user

# Archive internals
with the knowledge about the layout and the parts you can create your own archives without
using the script and modify existing backups to work with it
## Archive info file
*this file will contain information that helps keeper to present and use the archive*
(it is located in <archive-dir>/archive.info)
> you can add to this file other stuff outside of what listed in the description
### archive.info terms:
* archive-creator - the username of the user that this backup came from, this will be used to
                   edit some files and correct the path inside them from /home/<olduser>
                   to /home/<newuser> in the case where the usernames are different
* date-created    - the date that the archive was created in, will be shown to the user before
                   restoring from this archive
* doc             - a short description about this archive and important notes if there are any
                   will be shown to the user before restoring from this archive
### default archive information file
the default file will insert the archive-creator and the date information
when creating a backup (located in <archive-dir>/archive.info)
so for an archive.info for a backup today will look like:
```sh
# default archive.info file
archive-creator='<username>'
date-created='13/05/22'
doc='backup made by <username> on <hostname>'
```
### Example archive information file
```sh
# example of a archive.info file
archive-creator='nonoma1n'
# date format isn't specific
date-created='13/05/22'
# adding a list of packages that this backup requires or anything in that style is optional
doc="kde setup backup - need to install latte-dock and hack nerd-font in order to use it
**note** I also have a list of all the required packages to install in 'required.txt'
alongside my archive.info file so its best that you'll look into it"
```
### Archive layout
```
|- <archive-name>/            The archive
|  |- archive.info            File that contains the information about the archive
|  |- backup-root/            Directory that contains all the files and directories
|  |                           that will be copied to the destination
```
