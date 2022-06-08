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
# This is a base template for a bash lib file.
# taken from www.github.com/nonoMain/templates/blob/master/bash/lib.sh

# colors
bash_lib_define_colors ()
{
	if [[ -z $NO_COLOR ]]; then
		RED='\033[0;31m'
		GREEN='\033[0;32m'
		YELLOW='\033[0;33m'
		BLUE='\033[0;34m'
		PURPLE='\033[0;35m'
		CYAN='\033[0;36m'
		WHITE='\033[0;37m'
		NC='\033[0m' # No Color
	else
		RED=''
		GREEN=''
		YELLOW=''
		BLUE=''
		PURPLE=''
		CYAN=''
		WHITE=''
		NC=''
	fi
	MSG_COLOR=$BLUE
	OK_COLOR=$GREEN
	ERROR_COLOR=$RED
	WARNING_COLOR=$YELLOW
}
bash_lib_define_colors


# @brief echo the script's dir (symlink safe way)
# @usage script_dir=$(find_script_dir)
find_script_dir ()
{
	SOURCE="${BASH_SOURCE[0]}"
	while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
		DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
		SOURCE="$(readlink "$SOURCE")"
		[[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
	done
	DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
	echo "$DIR"
}

# @brief echo the script's dir (doesn't follow symlinks)
# @usage script_dir=$(find_script_dir_unsafe)
find_script_dir_unsafe ()
{
	echo "$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
}

# @brief echo the given text as a message
# @param $1 the text to echo
echo_msg ()
{
	echo -e "[ ${MSG_COLOR}MSG${NC} ] $1"
}

# @brief echo the given text as an ok message
# @param $1 the text to echo
echo_ok_msg ()
{
	echo -e "[ ${OK_COLOR}OK${NC}  ] $1"
}

# @brief echo the given text as a warning message
# @param $1 the text to echo
echo_warning_msg ()
{
	echo -e "[ ${WARNING_COLOR}WAR${NC} ] $1"
}

# @brief echo the given text as an error message
# @param $1 the text to echo
echo_error_msg ()
{
	echo -e "[ ${ERROR_COLOR}ERR${NC} ] $1"
}

# @brief waits until any key is pressed
# @usage wait_for_any_key_press
wait_for_any_key_press ()
{
	read -n 1 -s -r -p "$1"
	echo
}

# @brief echo the full path of a given path
# @param $1 path to the file
get_full_path ()
{
	cd $(dirname $1)
	echo "$PWD/$(basename $1)"
	cd $OLDPWD
}

# @brief prints the usage & help of the program
help_message ()
{
	echo \
"
Usage: keeper.sh [options]
general:
    -b, --backup          backup option [requires -t]
    -r, --restore         restore option [requires -f]
    -f, --from <path>     in case of restore, specify the backup file
                          in case of backup its optional, specify the directory to start from [default=\$PWD]
    -t, --to <path>       in case of backup, specify the name of the backup file
                          in case of restore its optional, specify the directory to restore to [default=\$PWD]
    --no-confirm          don't ask for confirmation before executing the backup/restore
    --no-color            don't use colors in output
    --dont-run            run everything but the backup/restore
    -h, --help            show this help message

backup:
    --profiles            show the available profiles
    --profile <profile>   backup profile (what files to backup), default is 'default'
    -m, --message <msg>   in case of backup, the message to be added to the backup info file (to be previewed)
    --message-file <file> in case of backup, the file to be added to the backup info file (to be previewed)
                          this option is made for when the message you want is pre-made or multilined
restore:
    --preview             preview information about the backup before restoring it
    --only-preview        calls --preview and --dont-run
    --sed-home-path       will replace the old home path with the new one inside all the files from the archive
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
		ln -sf $PWD/${pathFrom} "$dirAt"
	elif [[ -e "$pathFrom" ]]; then
		echo_msg "Linking $PWD/$pathFrom to $pathAt"
		ln -sf "$PWD/$pathFrom" "$pathAt"
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
			cp -r "$path/".[^\.]* $tmpDir 1> /dev/null || echo_warning_msg "Failed to find files matching '.*'"
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
