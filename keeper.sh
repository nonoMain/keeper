#!/usr/bin/env -S bash -e

export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $SCRIPT_DIR/.keeper.lib.sh

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
		echo "Adding $entrie to $dirTo"
		add_path_to_tmp_dir "$dirFrom/$entrie" "$dirTo/$entrie"
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
	echo "Starting backup"
	local archivePath=$1
	cd $(dirname $archivePath)
	archivePath="$PWD/$(basename $archivePath)"
	cd $OLDPWD
	create_archive $archivePath
	# backup
	backup_profile
	# add all the files in $TMP_DIR to the archive
	add_path_to_archive "$archivePath" "$TMP_DIR"
}

# Test main:
echo "Hello $USER"
TMP_DIR=$(generate_tmp_dir)
run_backup "$1"
rm -rf $TMP_DIR
