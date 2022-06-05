# keeper.git
This is a bash script utility that backs up or loads
the files that you specify to wherever you specify

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
# restore my backup.zip to a specific directory
./keeper.sh -r [options] -f backup.zip -t <specific directory>

# restore my backup.zip to a specific directory from a script that restores that config to
# a new user (at least that how I'd do it)
./keeper.sh -r --no-confirm --sed-home-path -f backup.zip -t <specific directory>
```

Usage
```
Usage: keeper.sh [options]
-b, --backup         backup option [requires -t]
-r, --restore        restore option [requires -f]
-f, --from <path>    in case of restore, specify the backup file
                     in case of backup its optional, specify the directory to start from [default=\$PWD]
-t, --to <path>      in case of backup, specify the name of the backup file
                     in case of restore its optional, specify the directory to restore to [default=\$PWD]
-h, --help           show this help message
--profiles           show the available profiles
--profile <profile>  backup profile (what files to backup), default is 'default'
--no-confirm         don't ask for confirmation before executing the backup/restore
--no-color           don't use colors in output
--preview            preview information about the backup/restore before running it [requires -b or -r]
--dont-run           run everything but the backup/restore
--only-preview       calls --preview and --dont-run [requires -b or -r]
-m, --message <msg>  in case of backup, the message to be added to the backup file (to be previewed)
--sed-home-path      will replace the old home path with the new one inside all the files from the archive
                         mainly used for images and files that were written as in /home/<old_user> inside
                         config files and now are in /home/<new_user>

** Note: you cannot combine options as one command line argument e.g: **
Good:
    keeper.sh -b -f $HOME -t /tmp/backup.tar.gz
Bad:
    keeper.sh -bf $HOME -t /tmp/backup.tar.gz
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
- [x] support external archive profiles [look here for more information](./PROFILES.md)
- [x] choose a backup profile
- [x] preview archive information
- [x] edit the content when restoring a backup according to the new user

# Create you own profiles
you can easily make your own archive profiles just look on the [doc](./PROFILES.md)
and look at the already existing [profiles](./profiles/) for ideas.

# Archive internals
with the knowledge about the layout and the parts you can create your own archives without
using the script and modify existing backups to work with it
## Archive info file
*this file will contain information that helps keeper to present and use the archive*
(it is located in <archive-dir>/archive.info)
> you can add to this file other stuff outside of what listed in the example
> 'creator' field is required if you want to use the --sed-home-path option

### Archive information file
the archive info file must be with the 4 first lines:
1. comment line
2. creator name
3. date
4. one line doc
The other lines will be printed later as a message if preview is chosen
```sh
# default archive.info file
creator='$USER'
date_archive_created='$(date +%Y-%m-%d)'
doc='backup made by $USER on $HOSTNAME'
# Preview message
This archive is for KDE and needs such and such
packages, Enjoy
```
### Archive layout
```
|- <archive-name>/            The archive
|  |- archive.info            File that contains the information about the archive
|  |- all the other the stuff
```
