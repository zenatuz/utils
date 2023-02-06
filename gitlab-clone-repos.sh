#!/bin/bash

############################################################
# Filename   : gitlab-clone-repos.sh                       #
# Author     : Renato Batista                              #
# Author URL : https://renatobatista.com.br                #
# Purpose    : Clone all repos in a given Gitlab Group     #
# Depends    : curl, git, jq                               #
# Arguments  : -g, -h                                      #
############################################################

# GNU All-Permissive License {{{
#############################################################
# Copyright © 2022 Renato Batista                           #
#                                                           #
# Copying and distribution of this file, with or without    #
# modification, are permitted in any medium without         #
# royalty, provided the copyright notice and this notice    #
# are preserved.                                            #
#                                                           #
# This file is offered as-is, without any warranty.         #
#############################################################
# End license }}}


# Change for any other Gitlab:
# Ex.: 
# GITLAB_URL=https://any.gitlab.net ./gitlab-clone-repos.sh -g 10
# 
# If not provided https://gitlab.com will be used as default.

GITLAB_URL="${GITLAB_URL:-https://gitlab.com}"

HELP(){
   # Display Help
   echo "This script clone all projects in a given Gitlab group. It expects to receive the GITLAB_TOKEN as an ENV_VARIABLE."
   echo
   echo "Syntax: GITLAB_TOKEN="RANDOM-TOKEN" gitlab-clone-repos -g 999 [-g|h]"
   echo "options:"
   echo "g     Pass the GROUP_ID and execute the script."
   echo "h     Print this Help."
   
   echo
}

CHECKS(){
    # Check Token Variable
    if [[ -z "${GITLAB_TOKEN}" ]]; then
        echo "GITLAB_TOKEN is not provided, you should provide GITLAB_TOKEN. Ex.: 'GITLAB_TOKEN=\"RANDOM-TOKEN\" gitlab-clone-repos.sh -g 999'"
        exit 1;
    fi

    # Check GITLAB_URL
    STATUS_CODE=$(curl --output /dev/null --silent --write-out "%{http_code}" $GITLAB_URL)

    if [[ $STATUS_CODE != 302 ]]; then
        echo "The provided GITLAB_URL ($GITLAB_URL) is wrong  or unavailable, please verify the providen GITLAB_URL."      
        exit 1;
    fi

    # Test token against API
    TOKEN_RESULT=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" $GITLAB_URL/api/v4/groups)

    if [[ "$TOKEN_RESULT" == *"401"* ]]; then
        echo "GITLAB_TOKEN provided is not valid, cannot list groups, please review the token and token permissions."
        echo $TOKEN_RESULT
        exit 1;
    fi

    # Test group against API
    GROUP_RESULT=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" $GITLAB_URL/api/v4/groups/$GROUP_ID)

    if [[ "$GROUP_RESULT" == *"404"* ]]; then
        echo "The provided GROUP_ID is not valid, please review the group ID."
        echo $GROUP_RESULT
        exit 1;
    fi
}

CLONE_REPOS (){
    if [[ -z "${GROUP_ID}" ]]; then
        echo "GROUP_ID cannot be empty, you should provide GROUP_ID with -g parameter. Ex.: '-g 10'"
        exit 1;
    fi

    for repo in $(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" $GITLAB_URL/api/v4/groups/$GROUP_ID | jq -r ".projects[].ssh_url_to_repo");
        do git clone $repo;
    done;
}

# Get the options
while getopts ":gh" option; do
   case $option in
        g) # execute verifications and clone
            GROUP_ID=$2
            CHECKS
            CLONE_REPOS
            exit;;
        h) # display Help
            HELP
            exit;;
   esac
done

# Print help if no parameter is given
HELP
