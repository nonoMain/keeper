#!/usr/bin/env -S bash -e

# --- Do not touch section

config_backup_profile='default'
config_no_confirm=0

# put the script directory in 'SCRIPT_DIR' (symlink safe way)
SOURCE=${BASH_SOURCE[0]}
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
	DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
	SOURCE=$(readlink "$SOURCE")
	[[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
export SCRIPT_DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )

# source lib
source $SCRIPT_DIR/.keeper.lib.sh

# --- Functions and global variables section
TMP_DIR=""

# @brief adds a path to the $TMP_DIR
# @param $1 path to add
# @param $2 place to add the path at
# @needed '$TMP_DIR'
add_path_to_tmp_dir ()
{
	local pathFrom="$1"
	local pathTo="$2"
	add_path_to_dest_at "$pathFrom" "$TMP_DIR/$pathTo"
}

# @brief adds a list of paths to the $TMP_DIR
# @param $1 path to take the list from
# @param $2 place to add the paths at
# @param $@ list of paths to add
# @needed 'add_path_to_tmp_dir'
add_entries_to_archive()
{
	local dirFrom=$1; shift
	local dirTo=$1; shift
	local paths=("$@")
	for entrie in "${paths[@]}"; do
		add_path_to_tmp_dir "$dirFrom/$entrie" "$dirTo/$entrie"
		echo "Linked $entrie to $dirTo"
	done
}

# @brief a tmp function that will be replaced by the real one from the backup profile
add_profile_backup ()
{
	echo "Err: No profile was loaded, exisiting"
	exit
}

# @brief initializes archive with the archive.info file
create_archive ()
{
	local archivePath="$1"
	local dirForInfo=$(generate_tmp_dir)
	touch "$dirForInfo/archive.info"
	local archiveinfoPath="$dirForInfo/archive.info"
	cat > $archiveinfoPath <<EOF
# default archive.info file
archive-creator=$USER
date-created=$(date +%Y-%m-%d)
doc='backup made by $USER on $HOSTNAME'
EOF
	make_archive_with_first_file "$archivePath" "$archiveinfoPath"
	rm -rf $dirForInfo
}

run_backup ()
{
	local pathToStartFrom="$1"
	local archivePath=$2
	local currentDir=$(pwd)
	cd $pathToStartFrom
	TMP_DIR=$(generate_tmp_dir)
	echo "Starting backup"
	archivePath=$(get_full_path "$archivePath")
	create_archive $archivePath
	# backup
	backup_profile $config_backup_profile
	# add all the files in $TMP_DIR to the archive
	add_path_to_archive "$archivePath" "$TMP_DIR"
	rm -rf $TMP_DIR
	cd $currentDir
}

run_restore ()
{
	echo "Starting restore"
	local archivePath=$1
	local destPath=$2
	archivePath=$(get_full_path "$archivePath")
	# restore
	restore_archive "$archivePath" "$destPath"
}

# --- Main section
#[ $# -eq 0 ] && help_message && exit
#[ $# -eq 1 ] && [[ "$1" =~ ^(-h|--help)$ ]] && help_message && exit
#
#if [[ "$1" =~ ^(--preview)$ ]]; then
#		echo "TODO: Preview $2"
#		exit
#fi
## $# is 2 or above
#if [[ "$1" =~ ^(-b|--backup)$ ]]; then
#	# 3 arguments means: the -b option, the path to start from and the archive path
#	# 2 arguments means: the -b option and the archive path
#	if [[ $# -eq 3 ]]; then
#		local pathToStartFrom=$2
#		if [[ -d $pathToStartFrom ]]; then
#		else
#		echo "Err: $pathToStartFrom directory does not exist"
#		exit
#		fi
#	fi
#elif [[ "$1" =~ ^(-r|--restore)$ ]]; then
#	echo "TODO: Restore"
#fi

ARGC=$#
choose="" # can be either 'backup' or 'restore'
pathFrom=""
pathTo=""
while [ $# -gt 0 ]; do
	case $1 in
		-h | --help)
			help_message
			exit
			;;
		--no-confirm)
			config_no_confirm=1
			shift
			;;
		-b | --backup)
			if [[ $choose == "restore" ]]; then
				echo "Err: Can't do a backup and a restore at the same time"
				exit
			fi
			choose="backup"
			shift
			;;
		-r | --restore)
			if [[ $choose == "backup" ]]; then
				echo "Err: Can't do a backup and a restore at the same time"
				exit
			fi
			choose="restore"
			shift
			;;
		--preview)
			echo "TODO: Preview, don't use this option"
			exit
			;;
		--profile)
			echo "TODO: Profile, don't use this option"
			exit
			;;
		-f | --from)
			pathFrom="$2"
			shift 2 # shift 2 times to get rid of the option's value
			;;
		-t | --to)
			pathTo="$2"
			shift 2 # shift 2 times to get rid of the option's value
			;;
		-- )
			echo "reached end of options"
			shift
			break
			;;
		*)
			echo "Err: Unknown option"
			help_message
			exit
			;;
	esac
done

echo "# ---- errors/notes about options ---- #"
case $choose in
	backup)
		[ -z "$pathTo" ] && echo "Err: No path to backup to was given" && help_message && exit
		[[ ! $pathTo =~ \.(zip|tar.gz) ]] && echo "Err: Archive type not supported, must be .zip or .tar.gz" && help_message && exit
		# 'from' is optional
		if [ -z "$pathFrom" ]; then
			echo "Note: No path to start from was given, starting from current directory [$PWD]"
			pathFrom="$PWD"
		else
			if [[ ! -d $pathFrom ]]; then
				echo "Err: $pathFrom is not a directory"
				help_message
				exit
			fi
		fi
		;;
	restore)
		[ -z "$pathFrom" ] && echo "Err: No path to restore from was given" && help_message && exit
		[ ! -f "$pathFrom" ] && echo "Err: $pathFrom is not a file [required by restore option]" && help_message && exit
		[ $(check_if_archive_is_valid "$pathFrom") ] || echo "Err: $pathFrom is not a valid archive to restore from [Note: an archive must contain certain things, look at the README.md]" && exit
		# 'to' is optional
		if [ -z "$pathTo" ]; then
			echo "Note: No path to restore to was given, restoring to current directory [$PWD]"
			pathTo="$PWD"
		else
			if [[ ! -d $pathTo ]]; then
				echo "Err: $pathTo is not a directory"
				help_message
				exit
			fi
		fi
		;;
	*)
		echo "Err: You need to specify 'backup' or 'restore' option"
		help_message
		exit
		;;
esac

echo "# ---- actual run ---- #"
[ $config_no_confirm == 1 ] || press_to_confirm "Are you sure you want to $choose?, press [ANY KEY] to continue"
