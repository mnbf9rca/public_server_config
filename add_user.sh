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

hashed = mak

# create user
echo "Creating user $username"
adduser --gecos "" --disabled-password $username
retVal=$?
echo "return {$retVal}"
[[ $retVal -ne 0 ]] && {echo "... operation failed, error code $retVal"; exit 1}

echo "setting password"
echo "{$username}":"{$password}" | chpasswd -e
retVal=$?
echo "return {$retVal}"
[[ $retVal -ne 0 ]] && {echo "... operation failed, error code $retVal"; exit 1}

echo ... done
