
Git Monitor
===========

Git Monitor is an extremely simple Bash script to allow monitoring of a
git repository.  It is expected to be run from cron.  It sends a diff
output to the specified e-mail address

Usage
-----

You must first have a local copy of a git repository from which you can perform 'git log', 'git pull' commands.

On the command line you need to specify three arguments:
    - The local directory of checked out git repo
    - The name of the repo
    - The e-mail address to which changes should be sent

e.g.

    ./git_monitor.sh /home/me/git/devstack DevStack git_devstack@myaddr.com


Setting up cron:
----------------

I'm currently running the script once per hour under cron to monitor the
DevStack repository.

To do that I first cloned the repo with the commands:

    mkdir -p /home/mike/src/git/devstack
    cd /home/mike/src/git/devstack
    git clone git://github.com/openstack-dev/devstack.git

Then I created a crontab entry in /home/mike/usr/cron/crontab as:

    ######################################################################
    ## GIT scraping:

    GIT_MONITOR=/home/mike/z/bin/Deployed/git_monitor.sh

    #Every hour:
    55 * * * *  $GIT_MONITOR /home/mike/src/git/devstack DevStack email@mike.com

Then enabled cron:
    crontab /home/mike/usr/cron/crontab

Then I sit back and wait for others to work on DevStack ...


Sendmail.pl
-----------

Sendmail.pl is a utility script used to send mail of it's stdin.

It should be invoked as:

    echo "My message to you" | sendmail.pl -s "SUBJECT" -t "to@address.com"

You'll probably need to at least specify the G_smtp variable to be the
SMTP address of your service provider, or specify this value with the -stmp option.

*Note: I should probably cite the author of the sendmail.pl script but it's something I've used for about 15 years and at each usage I've modified it ... so it's origin is unknown ...  *


