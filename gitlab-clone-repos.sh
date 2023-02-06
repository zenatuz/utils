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

# Colors
R='\033[0;31m'
G='\033[0;32m'
O='\033[0;33m'
Y='\033[1;33m'
NOCOLOR='\033[0m'

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

RUN_CHECKS(){
    # Check Token Variable
    if [[ -z "${GITLAB_TOKEN}" ]]; then
        echo -e $R"GITLAB_TOKEN is not provided, you should provide GITLAB_TOKEN.: $Y Ex.: 'GITLAB_TOKEN=\"RANDOM-TOKEN\" gitlab-clone-repos.sh -g 999'"$NOCOLOR
        exit 1;
    fi

    # Check GITLAB_URL
    STATUS_CODE=$(curl --output /dev/null --silent --write-out "%{http_code}" $GITLAB_URL)

    if [[ $STATUS_CODE == 200 ]] || [[ $STATUS_CODE == 301 ]] || [[ $STATUS_CODE == 302 ]] ; then
        echo -e $G"The URL server ($GITLAB_URL) is valid. :)"$NOCOLOR
    else
        echo -e $R"The provided GITLAB_URL ($GITLAB_URL) is wrong  or unavailable, please verify the providen GITLAB_URL." $NOCOLOR
        exit 1;
    fi

    # Test token against API
    TOKEN_RESULT=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" $GITLAB_URL/api/v4/groups)

    if [[ "$TOKEN_RESULT" == *"401"* ]]; then
        echo -e $R"GITLAB_TOKEN provided is not valid, cannot list groups, please review the token and token permissions." $NOCOLOR
        echo -e $Y $TOKEN_RESULT $NOCOLOR
        exit 1;
    fi

    # Test group against API
    GROUP_RESULT=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" $GITLAB_URL/api/v4/groups/$GROUP_ID)

    if [[ "$GROUP_RESULT" == *"404"* ]]; then
        echo -e $R "The provided GROUP_ID is not valid, please review the group ID." $NOCOLOR
        echo -e $Y $GROUP_RESULT $NOCOLOR
        exit 1;
    fi
}

CLONE_REPOS (){
    if [[ -z "${GROUP_ID}" ]]; then
        echo -e $Y "GROUP_ID cannot be empty, you should provide GROUP_ID with -g parameter. Ex.: '-g 10'" $NOCOLOR
        exit 1;
    fi

    for repo in $(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" $GITLAB_URL/api/v4/groups/$GROUP_ID | jq -r ".projects[].ssh_url_to_repo");do    
        echo -e "\n##############################"
        echo -e "Clonning $Y $repo" $NOCOLOR
        git clone $repo;
    done;
}

# Get the options
while getopts ":gh" option; do
   case $option in
        g) # execute verifications and clone
            GROUP_ID=$2
            RUN_CHECKS
            CLONE_REPOS
            exit;;
        h) # display Help
            HELP
            exit;;
   esac
done

# Print help if no parameter is given
HELP
