#!/usr/bin/env bash

#makeCA V1.0
#Author: RH363
#Date: 10/01/2024

ROOT_UID=0                                                                                                   
USER_UID=$(id -u)                                                                                            
ERR_NOTROOT=86
ERR_INV_OPTION=90
ERR_INV_DAYS=91

CANAME=serverCA
DAYS=4096
# Regular Colors
Color_Off='\033[0m'       # Text Reset

Red='\033[0;31m'          # Red
Blue='\033[0;34m'         # Blue
Yellow='\033[0;33m'       # Yellow

usage() {
 echo "Usage: $0 [OPTIONS]"
 echo "Colors:"
 echo -e "${Red} ERROR" 
 echo -e "${Yellow} WARNING"
 echo -e "${Blue} INFO ${Color_Off}"
 echo "Options:"
 echo " -h, --help            Display this help message"
 echo ' -c, --ca              CA NAME(DEFAULT="serverCA") Define CA cert name '
 echo " -d, --days            DAYS(DEFAULT=4096) Define how much days this cert must be valid"
}


while (($# > 0)); do
    case "$1" in
        "-h"|"--help")
            usage
            exit
        ;;
        "-c"|"--ca")
            if [ -z "$2" ];then
                echo -e "${Red}CA NAME OPTION REQUIRE AN ARGUMENT${Color_Off}"
                exit $ERR_INV_OPTION
            fi
            CANAME=$2
            shift 2
        ;;
        "-d"|"--days")
            if [ -z "$2" ];then
                echo -e "${Red}DAYS OPTION REQUIRE AN ARGUMENT${Color_Off}"
                exit $ERR_INV_OPTION
            fi
            if ! [[ $2 =~ ^[0-9]+$ ]]; then 
                echo -e "${Red}ERROR: $2 INVALID NUMBER${Color_Off}"
                exit $ERR_INV_DAYS
            fi
            DAYS=$2
            shift 2
        ;;
        *)
            echo -e "${Red}INVALID OPTION: $1${Color_Off}"
            exit $ERR_INV_OPTION
        ;;
    esac
done

if [ "$USER_UID" -ne "$ROOT_UID" ]                                                                           
    then
    echo -e "${Red}MUST BE ROOT TO RUN THIS SCRIPT${Color_Off}"
    exit $ERR_NOTROOT
    fi

if [ "$PWD" != "$CANAME" ];then 
    mkdir "$CANAME"
fi

case "$(lsb_release -is)" in
    "Ubuntu"|"Debian")
        apt-get -y install openssl 
    ;;
    "Almalinux")
        dnf -y install openssl
    ;;
    *)

    ;;
esac
echo "${Blue}CREATE KEY${Color_Off}"
openssl genrsa -aes256 -out "$CANAME/$CANAME".key "$DAYS"
if [ $? != 0 ];then
    rm -rf "$CANAME"
    exit
fi
echo "${Blue}KEY CREATED${Color_Off}"
echo "${Blue}CREATE CA CERT${Color_Off}"
openssl req -x509 -new -nodes -key "$CANAME/$CANAME".key -sha256 -days "$DAYS" -out "$CANAME/$CANAME".crt
if [ $? != 0 ];then
    rm -rf "$CANAME"
    exit
fi
echo "${Blue}CA CERT CREATED${Color_Off}"
cp "$CANAME/$CANAME".crt "$CANAME/$CANAME.pem"
