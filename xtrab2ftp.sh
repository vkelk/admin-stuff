#!/bin/bash
HOST=''
USER=""
PASS=""
RDIR='/'    #  Remote DIR
datetime="$(date +%FT%T)"
top_dir='/home/xtrabackup/tmp'
name="db-backup-${datetime//:/-}"
backup_name="${top_dir}/${name}"

function main
{
  getoptions $*
  [ "$UID" != "0" ] && { echo 'You need to run this script as a root user! Aborting...'; exit 1; }
  echo "Started the backup process on: $(date)"
  process_dbs
  curl_upload "${name}.tar.gz"
  echo "Finished the backup process on: $(date)"
  echo "Uploaded file name is: ${name}.tar.gz"
 rm -rf ${backup_name}{,.tar.gz}
 rm -R ${backup_name}

}
function process_dbs
{
  xtrabackup --backup --user=xtrabackup --password=xtrabackup --target-dir=${backup_name}  >& /dev/null
  xtrabackup --prepare --user=xtrabackup --password=xtrabackup --target-dir=${backup_name} >& /dev/null
  compress_dbs
}

function compress_dbs
{
  tar cvzf ${backup_name}.tar.gz ${backup_name} >& /dev/null
}
function ftp_upload
{
  FILE="$1" 
ftp -n $HOST <<XOK
  quote USER $USER
  quote PASS $PASS
  cd $RDIR
  lcd ${top_dir}
  put $FILE 
  quit
XOK
}
function curl_upload
{
  FILE="$1" 
  lcd ${top_dir}
  curl -T $FILE ftp://$USER:$PASS@$HOST/$RDIR
}
function getoptions 
{
  while getopts "h:u:p:d:rf:" opt
  do
   case "${opt}" in
     h ) HOST=${OPTARG};;
     u ) USER=${OPTARG};;
     p ) PASS=${OPTARG};;
     d ) RDIR=${OPTARG};;
   esac
  done
}

main $*



