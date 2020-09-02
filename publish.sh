#!/usr/bin/env zsh
source env
TIME=`date +"%Y-%m-%d-%H.%M.%S"`
TARGET=${FOLDER}${TIME}
PROGRESS=$(rsync --version | sed -n "1s/^.*version 3.[1-9].*$/--info=progress2/g;1p")
rsync -a ${PROGRESS} ${PWD}/root/ ${USER}@${SERVER}:${TARGET}/ \
    && ssh ${SSH_USER}@${SERVER} "chown -R ${USER}:${GROUP} ${TARGET}\
 && rm ${ROOT}\
 && ln -s ${FOLDER}${TIME} ${ROOT}"
