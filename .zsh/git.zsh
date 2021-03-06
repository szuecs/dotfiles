# git shortcuts
alias gsup="git svn fetch && git svn rebase"
alias gsd="git svn dcommit"
alias grevert="git reset --hard HEAD"
alias gl="git log --oneline"
alias gco="git checkout"
alias gcm="git commit -m"

#
# zsh - RPROMPT
#

typeset -ga preexec_functions
typeset -ga precmd_functions
typeset -ga chpwd_functions

setopt prompt_subst

export __CURRENT_GIT_BRANCH=
export __CURRENT_GIT_VARS_INVALID=1

zsh_git_invalidate_vars() {
  export __CURRENT_GIT_VARS_INVALID=1
}
zsh_git_compute_vars() {
  export __CURRENT_GIT_BRANCH="$(parse_git_branch)"
  export __CURRENT_GIT_VARS_INVALID=
}
parse_git_branch() {
  git branch --no-color 2> /dev/null | grep '^\* ' | awk '{print $2}'
}

chpwd_functions+='zsh_git_chpwd_update_vars'

zsh_git_chpwd_update_vars() {
  zsh_git_invalidate_vars
}

preexec_functions+='zsh_git_preexec_update_vars'

zsh_git_preexec_update_vars() {
  case "$(history $HISTCMD)" in
    *git*) zsh_git_invalidate_vars ;;
  esac
}

get_git_prompt_info() {
  test -n "$__CURRENT_GIT_VARS_INVALID" && zsh_git_compute_vars
  echo $__CURRENT_GIT_BRANCH
}
RPROMPT='$(get_git_prompt_info)'
