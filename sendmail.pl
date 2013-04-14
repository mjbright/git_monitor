#!/usr/bin/env perl
#------------------------------------------------------------

use strict;

# Stripped for public use: mjb, 2013-04-14
# Modified: mjb, 2011-09-27
#
# Defaults:
#

#NOTE: May need to change this 'From' ADDRESS to correspond to the SMTP server used,

my $ADDRESS="my.return.address\@home.com";
my $G_from="mjb";
my $G_reply=$ADDRESS;
my $G_to=$ADDRESS;
my $G_work_smtp="smtp3.work.com";
my $G_smtp="smtp.free.fr";
my $G_subject="$0 - No subject";
my $G_message="";
my $G_html=0;

my $verbose=1;

use Net::SMTP;   # Used for sendmail()


sub sendmail
{
    my ($P_from, $P_reply, $P_to, $P_mailhost, $P_subject, $P_message) = @_;

    my $L_smtp = Net::SMTP->new($P_mailhost);
    if (!defined($L_smtp)) {
        die "Failed to open SMTP connection to '$P_mailhost'";
    }

    my @CC=split(/\s*,\s*/, $P_to);
    $P_to = shift(@CC);
    my $P_cc="";
    for my $cc ( @CC ) {
        $P_cc .= "CC: $cc\r\n";
    }

    #$L_smtp->mail($P_from);
    $L_smtp->mail($P_reply);
    $L_smtp->to($P_to);

    #my $ctype="Content-Type: text/plain; charset=ISO-8859-1";
    my $ctype="Content-Type: text/plain";

    my $mimev=undef;
    if ($G_html) {
        $ctype="Content-Type: text/html; charset=ISO-8859-1";
        $mimev="MIME-Version: 1.0";
    }


    if ($verbose) {
        print "Sending mail via $P_mailhost\n";
        print "To:      $P_to\n";
        print "From:    $P_from\n";
        print "Subject: $P_subject\n";
        print $P_cc;
        print "$ctype\n";
        if ($G_html) {
            #print "$ctype\n";
            print "$mimev\n";
        }
    }

    $L_smtp->data();
    $L_smtp->datasend("Return-Path: <$P_reply>\n");
    $L_smtp->datasend("Reply-To: <$P_reply>\n");
    $L_smtp->datasend("X-Mailer: $0 (Net::SMTP)\n");
    #$L_smtp->datasend("CC: susan@example.com\r\n");
    if ($P_cc ne "") { $L_smtp->datasend($P_cc); }
    $L_smtp->datasend("Subject: $P_subject\n");
    if ($G_html) {
        $L_smtp->datasend($ctype);
        $L_smtp->datasend($mimev);
    }
    $L_smtp->datasend("\n");
    $L_smtp->datasend($P_message);
    $L_smtp->dataend();

    $L_smtp->quit;
}

sub writeToFile
{
    my ($P_from, $P_reply, $P_tofile, $P_mailhost, $P_subject, $P_message) = @_;

    my @L_days = qw(Sun Mon Tue Wed Thu Fri Sat);
    my @L_months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

    my ($L_sec, $L_min, $L_hour, $L_mthDay, $L_month, $L_year,
        $L_weekDay, $L_yearDay, $L_daylight) = localtime(time);

    $P_mailhost .= ".grenoble.work.com";

    my $L_day="$L_days[$L_weekDay]";
    my $L_mName="$L_months[$L_month]";

    my $L_fromdate="$L_day $L_mName $L_mthDay $L_hour:$L_min:$L_sec $L_year";
    my $L_dateline="$L_day $L_mName $L_mthDay $L_hour:$L_min:$L_sec +200";

    #fromdate=`date '+%a %b %d %H:%M:%S %Y'`
    #dateline=`date '+%a, %d %b %Y %H:%M:%S +0200'`

    #$P_from="mjb";
    my $L_mailfrom="$P_from\@$P_mailhost";
    my $L_mailto="mjb-cronpl\@$P_mailhost";

    `/bin/ll $P_tofile`;
    open(MAILBOX, ">> $P_tofile") || die "Cannot open $P_tofile for writing($@)";

    # Newline first just in case:
    #print MAILBOX "\n";

    # From mjb@work.com Fri Jul 19 10:28:35 1996
    print MAILBOX "From $L_mailfrom $L_fromdate\n";

    # print MAILBOX "Received: by $P_mailhost\n";
    # print MAILBOX " (1.37.109.16/15.5+ECS 3.3) id AA167384915; $L_dateline\n";

    print MAILBOX "Date: $L_dateline\n";
    print MAILBOX "From: Mike 'cron' Bright <$L_mailfrom>\n";
    print MAILBOX "Return-Path: <$L_mailfrom>\n";
    print MAILBOX "Message-Id: <199607190828.AA167384915\@$P_mailhost>\n";
    print MAILBOX "To: $L_mailto\n";
    print MAILBOX "Reply-To: $P_reply\n";
    print MAILBOX "Subject: $P_subject\n";
    print MAILBOX "X-Mailer: $0 (writeToFile)\n";
    print MAILBOX "Status: RO\n";
    print MAILBOX "\n";
    print MAILBOX $P_message,"\n";

    close(MAILBOX);
}

#
# main:
#
#
while ($_ = <STDIN>) { $G_message .= $_; }

my $G_smsub=\&sendmail;

sub setSmtpForHomeOrWork {
    my $RET="home";

    my @IPCONFIG = `ipconfig`;

    while ($_ = shift(@IPCONFIG)) {
        if (/IPv4.*:\s+(\d+)\.(\d+)\.(\d+)\.(\d+)/) {
            my $ipv4_1=$1;
            my $ipv4=$1.".".$2.".".$3.".".$4;

            if ($ipv4_1 == 169) { next; } # Ignore auto-config address

            if ($ipv4_1 == 15) { return "work"; }
            if ($ipv4_1 == 16) { return "work"; }
            if ($ipv4_1 == 155) { return "work"; } # eds.com
            if ($ipv4_1 == 192) { return "home"; }

            warn "Failed to determine if ip address($ipv4) is home or work";
            return "unknown";
        }
    }

    print "return $RET;\n";
    return $RET;
}

my $forceSmtp=0;

while ($_ = shift) {
    if (/-(s|subject)$/i) { $G_subject=shift; next; }

    if (/-(work)$/i) { $forceSmtp=1;$G_smtp=$G_work_smtp; next; }
    if (/-home/i)       { $forceSmtp=1; next; }

    if (/-(sm|smtp)$/i) { $G_smtp=shift; next; }

    if (/-free/i)       { $G_smtp="smtp.free.fr"; next; } # blocked?
    if (/-amen/i)       { $G_smtp="smtp.amen.fr"; next; } # untested
    if (/-google/i)     { $G_smtp="smtp.google.fr"; next; } # untested

    if (/-html/) { $G_html=1; next; }
    if (/-from/) { $G_from=shift; next; }

    $G_to=$_;

    if ($G_to =~ /\//) { # This is a file name
        $G_smsub=\&writeToFile;
    }
}

if (!$forceSmtp) {
    my $locn=setSmtpForHomeOrWork();
    if ($locn eq "work") { $G_smtp=$G_work_smtp; }
}

if ($verbose) { print "&$G_smsub($G_from, $G_reply, $G_to, $G_smtp, $G_subject, \$G_message);\n"; }
&$G_smsub($G_from, $G_reply, $G_to, $G_smtp, $G_subject, $G_message);

