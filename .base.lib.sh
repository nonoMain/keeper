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
