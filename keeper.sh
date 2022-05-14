#!/usr/bin/env -S bash -e

# --- Do not touch section

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
	local archivePath=$1
	TMP_DIR=$(generate_tmp_dir)
	echo "Starting backup"
	archivePath=$(get_full_path "$archivePath")
	create_archive $archivePath
	# backup
	backup_profile "default"
	# add all the files in $TMP_DIR to the archive
	add_path_to_archive "$archivePath" "$TMP_DIR"
	rm -rf $TMP_DIR
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
