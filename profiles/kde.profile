# this is a kde basic backup profile (written in BASH)
# @brief add .config/ files

kde_config_files()
{
	local dirFrom=".config"
	local dirTo=".config"
	local paths=(
		'plasma-org.kde.plasma.desktop-appletsrc'
		'plasmarc'
		'plasmashellrc'
		'kdeglobals'
		'kwinrc'
		'kwinrulesrc'
		'lattedockrc'
		'latte'
		'dolphinrc'
		'ksmserverrc'
		'kcminputrc'
		'kglobalshortcutsrc'
		'klipperrc'
		'kscreenlockerrc'
		'systemsettingsrc'
		'Kvantum'
		'kdegraphicsrc'
		'discoverrc'
		'baloofilerc'
		'kactivitymanagerd-statsrc'
		'kactivitymanagerdrc'
		'kalendaracrc'
		'kateschemarc'
		'kconf_updaterc'
		'kded5rc'
		'kfontinstuirc'
		'kgammarc'
		'khotkeysrc'
		'kmixrc'
		'knotesrc'
		'krunnerrc'
		'ksplashrc'
		'kwalletrc'
		'kxkbrc'
		'autostart'
	)
	add_entries_to_archive "$dirFrom" "$dirTo" "${paths[@]}"
}

kde_share_files()
{
	local dirFrom="$HOME/.local/share"
	local dirTo=".local/share"
	local paths=(
		'plasma'
		'color-schemes'
		'icons'
		'wallpapers'
		'fonts'
	)
	add_entries_to_archive "$dirFrom" "$dirTo" "${paths[@]}"
}

use_profile_backup ()
{
	kde_config_files
	kde_share_files
}
