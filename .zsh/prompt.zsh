function _git_compute_vars() {
    export __ZSH_GIT_STATE=
    export __ZSH_GIT_DIR=

    local git_dir state branch

    git_dir=$(git rev-parse --git-dir 2> /dev/null) || return

    if test -d "$git_dir/../.dotest"; then
        if test -f "$git_dir/../.dotest/rebasing"; then
            state="rebase"
        elif test -f "$git_dir/../.dotest/applying"; then
            state="am"
        else
            state="am/rebase"
        fi
        branch="$(git symbolic-ref HEAD 2>/dev/null)"
    elif test -f "$git_dir/.dotest-merge/interactive"; then
        state="rebase-i"
        branch="$(cat "$git_dir/.dotest-merge/head-name")"
    elif test -d "$git_dir/.dotest-merge"; then
        state="rebase-m"
        branch="$(cat "$git_dir/.dotest-merge/head-name")"
    elif test -f "$git_dir/MERGE_HEAD"; then
        state="merge"
        branch="$(git symbolic-ref HEAD 2>/dev/null)"
    else
        test -f "$git_dir/BISECT_LOG" && state="bisect"
        branch="$(git symbolic-ref HEAD 2>/dev/null)" || \
            branch="$(git describe --exact-match HEAD 2>/dev/null)" || \
            branch="$(cut -c1-7 "$git_dir/HEAD")..."
    fi

    branch="${branch#refs/heads/}"

    if test "$state" ; then
        state=":$state"
    fi

    case $git_dir in 
        .git) git_dir="$(pwd)/.git";;
    esac 

    export __ZSH_GIT_STATE="%{$fg[cyan]%}(${branch}${state})"
    export __ZSH_GIT_DIR="${${git_dir:h}/$HOME/~}"
}

function _prompt_compute_vars() {
    _git_compute_vars

    local git_dir
    git_dir=${${__ZSH_GIT_DIR}%% }

    local short
    short="${PWD/$HOME/~}"

    right_line_size=$((${COLUMNS} - ${#short} - 4))
    if test $right_line_size -lt 0 ; then 
        right_line_size=$((${right_line_size} + ${COLUMNS}))
    fi
    if test "$git_dir" = "$short" ; then
        right_line_size=$((${right_line_size} - 1))
    fi
    right_line=${(l.${right_line_size}..-.)}
    export __ZSH_RPROMPT_DIR_RIGHT_LINE="$right_line"

    if test -z "$git_dir" ; then
        export __ZSH_RPROMPT_DIR="$short"
        return
    fi

    local lead rest
    lead=$git_dir
    rest=${${short#$lead}#/}

    export __ZSH_RPROMPT_DIR="$lead%{$fg[cyan]%}/$rest"
}

function _git_preexec_update_vars() {
    case "$(history $HISTCMD)" in 
        *git*) _git_compute_vars ;;
    esac
}

setopt prompt_subst

autoload -U colors
colors

_prompt_compute_vars

PROMPT='%{$fg[magenta]%}-<%{$fg[yellow]%}${__ZSH_RPROMPT_DIR}%{$fg[magenta]%}>-${__ZSH_RPROMPT_DIR_RIGHT_LINE}%{$reset_color%}
%{$fg[green]%}%#%{$reset_color%} '

RPROMPT='${WINDOW:+"[$WINDOW]"}%{$fg[green]%}${USER}%{$fg[blue]%}@%{$fg[red]%}`hostname -s`${__ZSH_GIT_STATE}%{$fg[yellow]%}[%{$fg[red]%}%!%{$fg[yellow]%}]%{$reset_color%}'

