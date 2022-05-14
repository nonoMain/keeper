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

# @brief echo a message that an item has been backed up
# @param $1 the name of the item
# @param $2 the path to the archive
added_to_archive_message ()
{
	local thing="$1"
	local archive="$2"
	echo "Added $thing to $archive"
}

# @brief creates a tmp directory and echo the path
# @usage savedPath=$(generate_tmp_dir)
generate_tmp_dir ()
{
	echo "$(mktemp -d)"
}

# @brief echo the full path of a given path
# @param $1 path to the file
get_full_path ()
{
	cd $(dirname $1)
	echo "$PWD/$(basename $1)"
	cd $OLDPWD
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
check_if_archive_contains_file ()
{
	local archive=$1
	local file=$2
	list_archive_contents "$archive" | grep -q $file && return $?
}

check_if_archive_is_valid ()
{
	local archive=$1
	check_if_archive_contains_file "$archive" ".archive.info"
	return $?
}

# @brief source and backup using the given profile
# @needed 'use_profile_backup' function inside the profile file
backup_profile ()
{
	local profile=$1
	# load the backup profile
	source "$SCRIPT_DIR/profiles/$profile"
	# call the 'main' function of the backup profile
	use_profile_backup
}

# @brief restores the backup to a given path
# @param $1 path to the backup
# @param $2 path to restore to
restore_archive ()
{
	local archive=$1
	local path=$2
	local currentDir=$PWD
	cd "$path"
	case "$archive" in
		*.zip)
			unzip -o $archive .
			;;
		*.tar.gz)
			tar -xzf $archive .
			;;
	esac
	cd $currentDir
}

# @brief creats the archive and inserts a first file into it
# @param $1 path to the archive
# @param $2 path to the file to insert
make_archive_with_first_file ()
{
	local archive=$1
	local firstFile=$2
	local currentDir=$PWD
	cd $(dirname $firstFile)
	case "$archive" in
		*.zip)
			zip -r $archive $(basename $firstFile)
			;;
		*.tar.gz)
			tar -czf $archive $(basename $firstFile)
			;;
	esac
	echo "Created $archive and inserted $path to it"
	cd $currentDir
}

# @brief adds a path to the archive
# @param $1 path to the archive
# @param $2 path to the path to add
add_path_to_archive ()
{
	local archive=$1
	local path=$2
	local currentDir=$PWD
	[ ! -d $path ] && echo "cannot cd into $path" && return
	case "$archive" in
		*.zip)
			cd "$path"
			zip -r $archive .
			cd $currentDir
			;;
		*.tar.gz)
			# tar.gz archives can't be updated, so we have to recreate it
			local tmpDir=$(generate_tmp_dir)
			cp $archive $tmpDir
			#cp -r "$path"/* "$path"/.[a-zA-Z]* $tmpDir
			cp -r "$path/".[a-zA-Z]* $tmpDir || echo "Faild to find files matching '.[a-zA-Z]*'"
			cp -r "$path/"* $tmpDir || echo "Faild to find files matching '*'"
			cd $tmpDir
			tar -xzf $archive
			rm -rf $(basename $archive)
			# now tmpDir contains the prev archive with the stuff from the new path
			# so we can recreate the archive with the new stuff
			tar -chzf $archive .
			cd $OLDPWD
			;;
	esac
	added_to_archive_message "$path" "$archive"
}
