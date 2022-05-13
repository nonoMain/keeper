# Keeper.git
This is a bash script utility that backs up or loads
the files that you specify to wherever you specify

(on testing stages, no main function or restore abilities)

<p align="center">
  <img src="https://img.shields.io/github/repo-size/nonomain/keeper?style=for-the-badge">
</p>

# How to use?
Examples
```sh
# backup my home directory to backup.zip
./keeper.sh -b [options] backup.zip $HOME

# restore my backup.zip to some home directory
./keeper.sh -r [options] backup.zip $HOME
```

Script's usage
```
Usage: keeper.sh -[brh] [options] <path> [<path>]
-b                  backup option
Backup option requires <path to the backup (where it will be created)> [<path to start backup from>]
-r                  restore option
Restore option requires <path to restore from> [<path to restore to>]
Optional:
--preview           preview the archive information, only available for zip and tar.gz
--profile=""        backup profile (what files to backup), default is 'default'
--format=""         backup format, default is 'zip'. other options are 'tar.gz'
```

# What can be backed up?
Everything! I use it to back up an entire template home
directories for quickly setting up a user when going onto a new machine
including wallpapers and programs preferences.
It comes with a few templates so you can use them or learn
from them how to create your own.

# Features
- [x] different archive types (.zip, .tar.gz)
- [x] test if a certain [external] archive is valid
- [ ] support other backup profiles
- [ ] choose a backup profile
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
