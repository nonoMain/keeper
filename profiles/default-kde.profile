# this is a merge between the default and the kde (written in BASH)
# backup profiles

source $SCRIPT_DIR/profiles/default.profile
source $SCRIPT_DIR/profiles/kde.profile

use_profile_backup ()
{
	# default profile
	default_home_dotfiles
	default_config_files
	default_share_files
	# kde profile
	kde_config_files
}
