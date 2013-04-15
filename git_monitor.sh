#!/bin/bash

MAILER=~/z/bin/Deployed/sendmail.pl

PROG=$0
die() {
    echo "$PROG: die - $*" >&2
    exit 1
}

[ -z "$1" ] && die "Missing src dir arg"
SRC_DIR=$1; shift
[ -z "$1" ] && die "Missing repo name arg"
REPO_NAME=$1; shift
[ -z "$1" ] && die "Missing e-mail address arg"
EMAIL=$1; shift

[ ! -x $MAILER ] && die "No such mailer as '$MAILER'"

[ ! -d $SRC_DIR ] && die "No such src dir as '$SRC_DIR'"
cd $SRC_DIR || die "Failed to chdir $SRC_DIR"

# Get hash for last commit before doing a pull:
LASTHASH=`git log --pretty=format:'%H' -n 1`
LAST_COMMITER_INFO=` git log --pretty=format:'%ad %ae' -n 1`

# Pull latest code:
git pull 2>&1 | grep -q "Already up-to-date." \
    && { echo "Already up-to-date"; exit 0; } || \
    echo "Changes seen."

sendGroupedUpdates() {
    # Create log-diff of all changes since hash $LASTHASH:
    # Send o/p by e-mail:
    SUBJECT="[git:grouped] $REPO_NAME diff-log since hash $LASTHASH [$LAST_COMMITER_INFO]"
    git log ${LASTHASH}..HEAD -p | \
      $MAILER -s "$SUBJECT" -t $EMAIL
}

sendIndividualUpdates() {
    export LASTHASH

    HASHLIST=`git log | perl -ne '
      if (/^commit (\w+)/) {
        if ($1 eq "$ENV{LASTHASH}") {
            print join(" ", reverse @HASHES);
            exit(0);
        };
        push(@HASHES, $1);
        #print $1." ";
      }'`

    PREVHASH=$LASTHASH
    for HASH in $HASHLIST;do
        #LAST_COMMITER_INFO=` git log --pretty=format:'%ad %ae' -n 1`
        LAST_COMMITER_INFO=`git log ${PREVHASH}..${HASH} --pretty=format:'%ad %ae' -n 1`

        SUBJECT="[git] $REPO_NAME diff-log with hash $HASH [$LAST_COMMITER_INFO]"
        git log ${PREVHASH}..${HASH} -p | \
          $MAILER -s "$SUBJECT" -t $EMAIL

        PREVHASH=$HASH
    done
}

sendGroupedUpdates

sendIndividualUpdates


