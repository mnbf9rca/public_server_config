#!/bin/bash

usage() { echo "Usage: $0 -u <username> -p <password>" 1>&2; exit 1; }

if [[ $(id -u) -ne 0 ]] ; then echo "Please run as root" ; exit 1 ; fi

while getopts "u:p:" flag; do
    case "${flag}" in
        u) username=${OPTARG};;
        p) password=${OPTARG};;
        *) usage ;;
    esac
done

if [ -z "${username}" ] || [ -z "${password}" ]; then
    usage
fi

# create user
echo "Creating user $username"
useradd --create-home --password $password $username
retVal=$?
[[ $retVal -ne 0 ]] && {echo "... operation failed, error code $retVal"; exit 1}


echo ... done
