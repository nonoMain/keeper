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
		echo_msg "Linked $dirFrom/$entrie to $dirTo"
	done
}

# @brief a tmp function that will be replaced by the real one from the backup profile
add_profile_backup ()
{
	echo_error_msg "No profile was loaded, exisiting"
	exit
}

# @brief genereate a info file about the archive and echo the path to it
# @param $1 message to include in the info file
generate_info_file ()
{
	local message="$1"
	local dirForInfo=$(generate_tmp_dir)
	touch "$dirForInfo/archive.info"
	local archiveinfoPath="$dirForInfo/archive.info"
	cat > $archiveinfoPath <<EOF
# default archive.info file
creator='$USER'
date_archive_created='$(date +%Y-%m-%d)'
doc='backup made by $USER on $HOSTNAME'
message='$message'
EOF
	echo $archiveinfoPath
}

# @brief initializes archive with the archive.info file
# @param $1 path to the wanted archive
# @param $2 message to include in the info file
create_archive ()
{
	local archivePath="$1"
	local archive_info_message="$2"
	local infoFile=$(generate_info_file "$archive_info_message")
	make_archive_with_first_file "$archivePath" "$infoFile"
	rm -rf $(dirname $infoFile)
}

# @brief echos the archive.info file from the archive
# @param $1 path to the archive
preview_archive_details ()
{
	display_file_from_archvie "$1" "archive.info"
}

run_backup ()
{
	local pathToStartFrom="$1"
	local archivePath="$2"
	local info_message="$3"
	archivePath=$(get_full_path "$archivePath")
	local currentDir=$(pwd)
	cd $pathToStartFrom
	TMP_DIR=$(generate_tmp_dir)
	create_archive $archivePath "$info_message"
	# backup
	backup_profile $config_backup_profile
	# add all the files in $TMP_DIR to the archive
	add_path_to_archive "$archivePath" "$TMP_DIR"
	rm -rf $TMP_DIR
	cd $currentDir
}

run_restore ()
{
	local archivePath=$1
	local destPath=$2
	archivePath=$(get_full_path "$archivePath")
	# restore
	restore_archive "$archivePath" "$destPath"
	source_archive_info_file "$archivePath"

	# --sed-home-path
	echo_msg "Sed home path:"
	if [[ $sed_home_path -eq 1 ]]; then
		if [[ -z "$creator" ]]; then
			echo_error_msg "No creator was found in the archive.info file"
		elif [[ "$creator" == "$USER" ]]; then
			echo_warning_msg "The archive was made by a creator named $creator, so no changes will be made"
		else
			echo_warning_msg "replacing $creator with $USER on all archive files in $destPath"
			list_archive_contents "$archivePath" | while read file; do
			if [[ -f "$destPath"/"$file" ]]; then
				sed -i "s|/home/$creator|/home/$USER|g" "$destPath"/"$file"
			fi
			done
		fi
	fi
}

# --- Main section
ARGC=$#
choose="" # can be either 'backup' or 'restore'
pathFrom=""
pathTo=""
archive_info_msg="No message to display"
sed_home_path=0
to_preview=0
dont_run=0
while [ $# -gt 0 ]; do
	case $1 in
		-h | --help)
			help_message
			exit
			;;
		--profiles)
			list_profiles
			exit
			;;
		--no-confirm)
			config_no_confirm=1
			shift
			;;
		--no-color)
			NO_COLOR=1
			bash_lib_define_colors
			shift
			;;
		-b | --backup)
			if [[ $choose == "restore" ]]; then
				echo_error_msg "Can't do a backup and a restore at the same time"
				exit
			fi
			choose="backup"
			shift
			;;
		-r | --restore)
			if [[ $choose == "backup" ]]; then
				echo_error_msg "Can't do a backup and a restore at the same time"
				exit
			fi
			choose="restore"
			shift
			;;
		--sed-home-path)
			sed_home_path=1
			shift
			;;
		--dont-run)
			dont_run=1
			shift
			;;
		--preview)
			to_preview=1
			shift
			;;
		--only-preview)
			to_preview=1
			dont_run=1
			shift
			;;
		--profile)
			config_backup_profile="$2"
			shift 2 # shift 2 times to get rid of the option's value
			;;
		-f | --from)
			pathFrom="$2"
			shift 2 # shift 2 times to get rid of the option's value
			;;
		-t | --to)
			pathTo="$2"
			shift 2 # shift 2 times to get rid of the option's value
			;;
		-m | --message)
			archive_info_message="$2"
			shift 2 # shift 2 times to get rid of the option's value
			;;
		-- )
			echo "reached end of options"
			shift
			break
			;;
		*)
			echo_error_msg "Unknown option"
			help_message
			exit
			;;
	esac
done

case $choose in
	backup)
		[ -z "$pathTo" ] && echo_error_msg "No path to backup to was given" && help_message && exit
		[[ ! $pathTo =~ \.(zip|tar.gz) ]] && echo_error_msg "Archive type not supported, must be .zip or .tar.gz" && help_message && exit
		[[ -d "$(dirname $pathTo)" ]] || mkdir -p "$(dirname $pathTo)"
		# 'from' is optional
		if [ -z "$pathFrom" ]; then
			echo_warning_msg "Note: No path to start from was given, starting from current directory [$PWD]"
			pathFrom="$PWD"
		else
			if [[ ! -d $pathFrom ]]; then
				echo_error_msg "$pathFrom is not a directory"
				help_message
				exit
			fi
		fi
		echo_ok_msg "Backup detected and all options are valid"
		;;
	restore)
		[ -z "$pathFrom" ] && echo_error_msg "No path to restore from was given" && help_message && exit
		[ ! -f "$pathFrom" ] && echo_error_msg "$pathFrom is not a file [required by restore option]" && help_message && exit
		[ $(check_if_archive_is_valid "$pathFrom") ] || ( echo_error_msg "$pathFrom is not a valid archive to restore from [Note: an archive must contain certain things, look at the README.md]" && exit )
		# 'to' is optional
		if [ -z "$pathTo" ]; then
			echo_warning_msg "Note: No path to restore to was given, restoring to current directory [$PWD]"
			pathTo="$PWD"
		else
			if [[ ! -d $pathTo ]]; then
				echo_error_msg "$pathTo is not a directory"
				help_message
				exit
			fi
		fi
		echo_ok_msg "Restore detected and all options are valid"
		;;
	*)
		help_message
		exit
		;;
esac

if [[ ! -f "$SCRIPT_DIR"/profiles/"$config_backup_profile" ]]; then
	echo_error_msg "$config_backup_profile does not exist inside $SCRIPT_DIR/profiles/"
	exit
fi
pathFrom=$(get_full_path "$pathFrom")
pathTo=$(get_full_path "$pathTo")
if [[ $choose == "backup" ]]; then
	echo_msg "will backup to: $pathTo from $pathFrom"
elif [[ $choose == "restore" ]]; then
	echo_msg "will restore from: $pathFrom to $pathTo"
	if [[ $sed_home_path == 1 ]]; then
		echo_msg "will replace the old home path with the new one (if they are different)"
	fi
	if [[ $to_preview == 1 ]]; then
		echo_msg "Preview archive info:"
		echo -e "${BLUE}"
		preview_archive_details "$pathFrom"
		echo -e "${NC}"
	fi
fi

[[ $dont_run == 1 ]] && exit
[ $config_no_confirm == 0 ] && wait_for_any_key_press "press [ANY KEY] to continue.. "

if [[ $choose == "backup" ]]; then
	run_backup "$pathFrom" "$pathTo" "$archive_info_message"
elif [[ $choose == "restore" ]]; then
	run_restore "$pathFrom" "$pathTo"
fi
