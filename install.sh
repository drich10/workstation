#!/usr/bin/env bash

set -e

WORKSPACE="$HOME/workspace"
POST_INSTALL="\n\n$(tput setaf 2)************\n* Success! *\n************\n$(tput setaf 6)"

function clone() {
    local remote="$1"
    local destination="$2"

    if [[ "$destination" == "" ]]; then
      destination="$WORKSPACE/$(echo "$remote" | sed "s/.*\///" | sed "s/.git$//")"
    fi

    if [ -d "$destination" ]; then
      return 0
    fi

    git clone "$remote" "$destination"
}

function bash-profile() {
    ln -fs "$PWD/.bash_profile" "$HOME/"
    source "$HOME/.bash_profile"
}

function make-workspace() {
    mkdir "$HOME/workspace" 2> /dev/null || true
}

function homebrew() {
    set +e
    which brew > /dev/null
    local exit_code="$?"
    set -e

    if [[ "$exit_code" -eq 0 ]]; then
      return 0
    fi

    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

function brewfile() {
    brew bundle --file="$PWD/Brewfile"
}

function git-config() {
    git config --global url."git@github.com:".pushInsteadOf https://github.com/
    git config --global submodule.fetchJobs 16

    git config --global alias.co checkout
    git config --global alias.ci duet-commit
    git config --global alias.st status
    git config --global alias.di diff
    git config --global alias.br branch
    git config --global alias.lol "log --graph --decorate --pretty=oneline --abbrev-commit"
    git config --global alias.lol "log --graph --decorate --pretty=oneline --abbrev-commit --all --date=local"

    ln -fs "$PWD/.git-authors" "$HOME/"
}

function bash-it-setup() {
    clone https://github.com/revans/bash-it ~/.bash_it

    set +e

    bash-profile

    bash-it update

    bash-it enable completion system
    bash-it enable completion git
    bash-it enable completion ssh

    bash-it enable plugin fzf
    bash-it enable plugin fasd
    bash-it enable plugin history

    bash-it enable alias general
    bash-it enable alias git

    ln -fs "$PWD"/bash_it/* "$BASH_IT/custom/"

    bash-profile

    set -e
}

function pivotal_ide_prefs() {
    clone https://github.com/pivotal/pivotal_ide_prefs

    pushd "$WORKSPACE/pivotal_ide_prefs" > /dev/null
        cli/bin/ide_prefs install --ide=intellij
        cli/bin/ide_prefs install --ide=gogland
    popd
}

function credalert() {
    echo "Installing cred alert cli"

    set +e
    which cred-alert-cli > /dev/null
    local exit_code="$?"
    set -e

    #cli
    if [[ "$exit_code" -ne 0 ]]; then
        wget -q -O /usr/local/bin/cred-alert-cli https://s3.amazonaws.com/cred-alert/cli/current-release/cred-alert-cli_darwin
        chmod +x /usr/local/bin/cred-alert-cli
    else
        cred-alert-cli update
    fi

    #githooks repo
    echo "Setting up git-hooks-core-repo"
    clone https://github.com/pivotal-cf-experimental/git-hooks-core
    git config --global core.hooksPath "$WORKSPACE/git-hooks-core"
}

function post-install() {
    echo -e "$POST_INSTALL"
}

function case_insensitive_bash_completion() {
    cp .inputrc ~/.inputrc
}

function main() {
    make-workspace
    homebrew
    brewfile
    git-config
    bash-it-setup
    pivotal_ide_prefs
    credalert
    case_insensitive_bash_completion
    post-install
}

main
