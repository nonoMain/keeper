# this is a default basic backup profile (written in BASH)

# @brief add $HOME .rc files
default_home_dotfiles()
{
	local dirFrom="$HOME"
	local dirTo=""
	local paths=(
		'.aliases'
		'.editorconfig'
		# rc files
		'.bashrc'
		'.zshrc'
		'.vimrc'
	)
	add_entries_to_archive "$dirFrom" "$dirTo" "${paths[@]}"
}

# @brief add .config/ files
default_config_files()
{
	local dirFrom="$HOME/.config"
	local dirTo=".config"
	local paths=(
		# rc files
		'.bash_profile'
		'.tmux.conf'
		'.screenrc'
		'.gitconfig'
		'.fonts'
		'.themes'
		'.icons'
		'latte'
		'lattedockrc'
		# tools
		'lsd'
		'htop'
		'btop'
		'alacritty'
		'nvim'
		'xournalpp'
		'vlc'
		'vlcrc'
		'GIMP'
		'libreoffice'
		'VirtualBoxVMrc'
		'VirtualBoxrc'
		# Desktop enviorment related
		'gtkrc*'
		'gtk-*'
		'fontconfig'
	)
	add_entries_to_archive "$dirFrom" "$dirTo" "${paths[@]}"
}

default_share_files()
{
	local dirFrom="$HOME/.local/share"
	local dirTo=".local/share"
	local paths=(
		'fonts'
		'color-schemes'
		'icons'
		'wallpapers'
		'vlc'
	)
	add_entries_to_archive "$dirFrom" "$dirTo" "${paths[@]}"
}

use_profile_backup ()
{
	default_home_dotfiles
	default_config_files
	default_share_files
}
