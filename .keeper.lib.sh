# this file contains functions that are sourced to the main program

# @brief prints the usage & help of the program
help_message ()
{
	echo \
"
Usage: keeper.sh -[brh] [options] [<path>] <path>
-b					backup option
Backup option requires <path to the backup (where it will be created)> [<path to start backup from>]
-r					restore option
Restore option requires [<path to restore to>] <path to restore from>
Optional:
--preview			preview the archive information, only available for zip and tar.gz
--profile=""		backup profile (what files to backup), default is 'default'
--format=""			backup format, default is 'zip'. other options are 'tar.gz'
-h					show this help message
"
}

# @brief creates a tmp directory and echo the path
# @usage savedPath=$(generate_tmp_dir)
generate_tmp_dir ()
{
	echo "$(mktemp -d)"
}

# @brief adds files/directories from the path to the backup archive at the given path
# @param $1 path to copy from [the file/directory to add]
# @param $2 path to save at [<archive>/<place to save the path at>]
add_path_to_dest_at ()
{
	local pathFrom=$1
	local pathAt=$2
	local dirAt=$(dirname "$pathAt")
	[ ! -d $dirAt ] && mkdir -p $dirAt
	if [[ "${pathFrom@Q}" =~ \* ]]; then
		cd $dirAt
		ln -sf ${pathFrom} $dirAt
		cd $OLDPWD
	elif [[ -e "$pathFrom" ]]; then
		ln -sf $pathFrom $pathAt
	fi
}

# @brief lists the files/directories in the archive (.zip or .tar.gz)
# @param $1 path to the archive
list_archive_contents ()
{
	local archive=$1
	case "$archive" in
		*.zip)
			unzip -l $archive
			;;
		*.tar.gz)
			tar -tzf $archive
			;;
	esac
}

# @ brief checks if an archive is contains a file
# @param $1 path to the archive
# @param $2 file to check for
check_if_file_in_archive ()
{
	local archive=$1
	local file=$2
	list_archive_contents "$archive" | grep -q $file && echo $?
}

# @brief source and backup using the given profile
# @needed 'add_profile_backup' function inside the profile file
backup_profile ()
{
	# load the backup profile
	source $SCRIPT_DIR/profiles/default
	# call the 'main' function of the backup profile
	add_profile_backup
}

# @brief creats the archive and inserts a first file into it
# @param $1 path to the archive
# @param $2 path to the file to insert
make_archive_with_first_file ()
{
	local archive=$1
	local firstFile=$2
	cd $(dirname $firstFile)
	case "$archive" in
		*.zip)
			zip -r $archive $(basename $firstFile)
			;;
		*.tar.gz)
			tar -czf $archive $(basename $firstFile)
			;;
	esac
	cd $OLDPWD
}

# @brief adds a path to the archive
# @param $1 path to the archive
# @param $2 path to the path to add
add_path_to_archive ()
{
	local archive=$1
	local path=$2
	[ ! -d $path ] && echo "cannot cd into $path" && return
	cd "$path"
	echo "Adding $path to $archive"
	case "$archive" in
		*.zip)
			zip -r $archive .
			;;
		*.tar.gz)
			tar -cjf $archive .
			;;
	esac
	echo "Added $path to $archive"
	cd $OLDPWD
}
