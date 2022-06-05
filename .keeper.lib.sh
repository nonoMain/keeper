# this file contains functions that are sourced to the main program

if [ -z "$SCRIPT_DIR" ]; then
	SOURCE="${BASH_SOURCE[0]}"
	while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
		DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
		SOURCE="$(readlink "$SOURCE")"
		[[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
	done
	DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
	SCRIPT_DIR="$DIR"
fi
source $SCRIPT_DIR/.base.lib.sh

# @brief prints the usage & help of the program
help_message ()
{
	echo \
"
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
"
}

# @brief echo a message that an item has been backed up
# @param $1 the name of the item
# @param $2 the path to the archive
added_to_archive_message ()
{
	local thing="$1"
	local archive="$2"
	echo_msg "Added $thing to $archive"
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
		echo_msg "Will expand & link $pathFrom to $dirAt"
		ln -sf ${pathFrom} "$dirAt"
	elif [[ -e "$pathFrom" ]]; then
		echo_msg "Linking $pathFrom to $pathAt"
		ln -sf "$pathFrom" "$pathAt"
	fi
}

# @brief lists the files/directories in the archive (.zip or .tar.gz)
# @param $1 path to the archive
list_archive_contents ()
{
	local archive=$1
	case "$archive" in
		*.zip)
			unzip -l $archive | awk '{$1=$2=$3=""; print $0}'
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
	list_archive_contents "$archive" | grep -q $file
	if [ $? -eq 1 ]; then
		echo 0
	else
		echo 1
	fi
}

display_file_from_archive ()
{
	local archive=$1
	local file=$2
	case "$archive" in
		*.zip)
			unzip -p $archive $file
			;;
		*.tar.gz)
			local tmpDir=$(generate_tmp_dir)
			cd $tmpDir
			tar -xzf $archive "./$file"
			cat $file
			cd $OLDPWD
			rm -rf $tmpDir
			;;
	esac
}

check_if_archive_is_valid ()
{
	local archive=$1
	[[ ! $archive =~ \.(zip|tar.gz) ]] && return 1
	check_if_archive_contains_file "$archive" ".archive.info"
	return $?
}

source_archive_info ()
{
	local archive=$1
	local file="archive.info"
	local tmpDir=$(generate_tmp_dir)
	cd $tmpDir
	case "$archive" in
		*.zip)
			unzip -o $archive $file &> /dev/null
			;;
		*.tar.gz)
			tar -xzf $archive "./$file" &> /dev/null
			;;
	esac
	while read -r line; do
		eval "$line"
	done < <( sed -n 2,4p $file )
	cd $OLDPWD
	rm -rf $tmpDir
}

list_profiles ()
{
	echo_msg "Available profiles:"
	ls $SCRIPT_DIR/profiles
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
			unzip -o $archive 1>/dev/null
			;;
		*.tar.gz)
			tar -xzf $archive 1>/dev/null
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
			zip -r $archive $(basename $firstFile) 1> /dev/null
			;;
		*.tar.gz)
			tar -czf $archive $(basename $firstFile) 1> /dev/null
			;;
	esac
	echo_ok_msg "Created $archive and inserted $path to it"
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
	[ ! -d $path ] && echo_error_msg "cannot cd into $path" && return
	case "$archive" in
		*.zip)
			cd "$path"
			zip -r $archive . 1> /dev/null
			cd $currentDir
			;;
		*.tar.gz)
			# tar.gz archives can't be updated, so we have to recreate it
			local tmpDir=$(generate_tmp_dir)
			cp $archive $tmpDir
			#cp -r "$path"/* "$path"/.[a-zA-Z]* $tmpDir
			cp -r "$path/".[a-zA-Z]* $tmpDir &> /dev/null || echo_warning_msg "Faild to find files matching '.[a-zA-Z]*'"
			cp -r "$path/"* $tmpDir &> /dev/null || echo_warning_msg "Faild to find files matching '*'"
			cd $tmpDir
			tar -xzf $archive 1> /dev/null
			rm -rf $(basename $archive)
			# now tmpDir contains the prev archive with the stuff from the new path
			# so we can recreate the archive with the new stuff
			tar -chzf $archive . 1> /dev/null
			cd $OLDPWD
			;;
	esac
	added_to_archive_message "$path" "$archive"
}
