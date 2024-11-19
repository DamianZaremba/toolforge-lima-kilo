# Bash completion functions for helpers inside lima-kilo
COMPONENTS_DIR=$HOME/toolforge-deploy/components


_toolforge_deploy_mr.py() {
    # only complete the component name for now
	local cur="${COMP_WORDS[COMP_CWORD]}"
	COMPREPLY=()

	local cur_index="$COMP_CWORD"

    local components
    components="$(ls "$COMPONENTS_DIR") jobs-cli builds-cli envvars-cli toolforge-cli components-cli tools-webservice"

	case "$cur_index" in
		1)
			if [[ $cur == -* ]]; then
				mapfile -t COMPREPLY < <(compgen -W "--help" -- "${cur}")
			else
				mapfile -t COMPREPLY < <(compgen -W "$components" -- "${cur}")
			fi
			;;
	esac
}

complete -F _toolforge_deploy_mr.py toolforge_deploy_mr.py
