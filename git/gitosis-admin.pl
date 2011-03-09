#! /usr/bin/perl -w

use Config::IniFiles;
use Data::Dumper;

use strict;

my $HELP_ARG = 0;
my $HELP_MSG = 1;
my $SUB = 2;

my %ini;
tie %ini, 'Config::IniFiles', ( -file =>  => './gitosis.conf', -nocase => 1 );

#my $ini = Config::IniFiles->new(
#    -file => './gitosis.conf'
#);

my %actions = (
    'help'   => [ '', 'Show help text', \&showHelp ],
    'help command' => [ '', '', \&showHelp ],
    'repos'  => [ '[match]', 'Show a list of repositories', \&showRepoList ],
    'groups' => [ '[match]', 'Show a list of groups', \&showGroupList ],
    'repo'   => [ "name\nrepo name +w|-w|+r|-r groupname", 'Print out the details for a repo, or modify permissions.', \&showRepo ],
    'group'  => [ "name\ngroup name +w|-w|+r|-r reponame\ngroup name +member -member", 'Print out the details for a repo, or modify permissions or members.', \&showGroup ],
    'add'    => [ "repo  name  owner    'description'\nadd group name 'members' 'description' [+r|+w reponame] [...]", "Create a new repo or group.", \&addSomething ],
);

showHelp() unless(scalar(@ARGV));

my $action = shift(@ARGV);

showHelp() unless(defined($actions{$action}));
$actions{$action}[$SUB](@ARGV);

exit(0);

sub showHelp {
    my ($cmd) = @_;
    my @commands = sort keys %actions;
    if (defined($cmd) && defined($actions{$cmd})) {
	@commands = ( $cmd );
    } elsif (defined($cmd)) {
	print "Unknown command $cmd\n";
    }
    print "Usage: ga command [opt] [opt...]\nCommands:\n";
    foreach my $action (@commands) {
	next if($action =~ / /);
	print $action . ' ' . $actions{$action}[$HELP_ARG] . "\n\t" . $actions{$action}[$HELP_MSG] . "\n";
    }
    exit(-1);
}

sub showList {
    my ($type, $match) = @_;
    foreach my $section (sort keys %ini) {
	next unless($section =~ /^$type (.+)$/i);
	my $name = $1;
	if (defined($match)) {
	    next unless($name =~ /$match/i);
	}
	print $name . "\n";
    }
}

sub showRepoList {
    my ($match) = @_;
    showList('repo', $match);
}

sub showGroupList {
    my ($match) = @_;
    showList('group', $match);
}

sub clearPerms {
    my ($repo, $group) = @_;
    my $groupKey = "group $group";
    if (defined($ini{$groupKey})) {
	my $qmrepo = quotemeta($repo);
	foreach my $perm (qw!readonly writable!) {
	    if (defined($ini{$groupKey}{$perm})) {
		my $oldAccess = $ini{$groupKey}{$perm};
		my $newAccess = $oldAccess;
		$newAccess =~ s/\b$qmrepo\b/ /;
                $newAccess =~ s/[ ]+/ /g;
		$newAccess =~ s/^\s+|\s+$//g;
		if ($oldAccess ne $newAccess) {
		    if ($newAccess eq '') {
			delete($ini{$groupKey}{$perm});
		    } else {
			$ini{$groupKey}{$perm} = $newAccess;
		    }
		}
	    }
	}
    }
} # clearPerms

sub showRepo {
    my ($name,$perm,$group) = @_;
    showHelp('repo') unless(defined($name));
    my $section = 'repo ' . $name;
    unless(defined($ini{$section})) {
	print "Repo '$name' not found.\n";
	exit(-1);
    }
    my %params = %{$ini{$section}};
    print "Repo: $name\n";
    print("Description: ${params{'description'}}\n") if(defined($params{'description'}));
    print("Owner: ${params{'owner'}}\n") if(defined($params{'owner'}));
    if (defined($perm) && defined($group)) {
	showHelp('repo') unless($perm =~ /^(\-|\+)(r|w)$/);
	my $permMod = $1;
	my $permAccess = $2;
	if(defined($ini{"group $group"})) {
	    setAccess($name, $group, $permMod, $permAccess);
	    tied(%ini)->RewriteConfig();
	} else {
	    print "Unknown group '$group'.\n";
	}
    }
    my @rGroups;
    my @wGroups;
    my %rUsers;
    my %wUsers;
    my $qmname = quotemeta($name);
    foreach my $sect (sort keys %ini) {
	next unless($sect =~ /^group (.+)$/i);
	my $groupName = $1;
	if(defined($ini{$sect}{'readonly'}) && ($ini{$sect}{'readonly'} =~ /$qmname/i)) {
	    if(defined($ini{"group $groupName"})) {
		if(defined($ini{"group $groupName"}{'members'})) {
		    foreach my $member (split(/\s+/, $ini{"group $groupName"}{'members'})) {
			$rUsers{lc($member)} = 1;
		    }
		}
	    } else {
		$groupName = "?$groupName?";
	    }
	    push(@rGroups, $groupName);
	}
	if(defined($ini{$sect}{'writable'}) && ($ini{$sect}{'writable'} =~ /$qmname/i)) {
	    if(defined($ini{"group $groupName"})) {
		if(defined($ini{"group $groupName"}{'members'})) {
		    foreach my $member (split(/\s+/, $ini{"group $groupName"}{'members'})) {
			$wUsers{lc($member)} = 1;
		    }
		}
	    } else {
		$groupName = "?$groupName?";
	    }
	    push(@wGroups, $groupName);
	}
    }
    print("Read Groups: " . join(' ', @rGroups) . "\n") if(scalar(@rGroups));
    print("Read Users: " . join(' ', sort keys %rUsers) . "\n") if(scalar(%rUsers));
    print("Write Groups: " . join(' ', @wGroups) . "\n") if(scalar(@wGroups));
    print("Write Users: " . join(' ', sort keys %wUsers) . "\n") if(scalar(%wUsers));
} # showRepo

sub addSomething {
    my ($thing, @args) = @_;
    if ($thing eq 'repo') {
	addRepo(@args);
    } elsif ($thing eq 'group') {
	addGroup(@args);
    } else {
	showHelp('add');
    }
} # addSomething

sub addRepo {
    my ($repo, $owner, $desc) = @_;
    my $repoKey = "repo $repo";
    showHelp('add') unless(defined($repo) && defined($owner) && defined($desc));
    if (defined($ini{$repoKey})) {
	print "Repo '$repo' already exists.\n";
	exit(-1);

    }
    $ini{$repoKey} = {};
    $ini{$repoKey}{'owner'} = $owner;
    $ini{$repoKey}{'gitweb'} = 'no';
    $ini{$repoKey}{'description'} = $desc;
    tied(%ini)->RewriteConfig();
    print ">>> Created repo '$repo' with owner '$owner'.\n";
} # addRepo

sub setAccess {
    my ($repo, $group, $mod, $access) = @_;
    clearPerms($repo, $group);
    if ($mod eq '+') {
	my $list = $ini{"group $group"}{$access eq 'r' ? 'readonly' : 'writable'} || '';
	$list =~ s/^\s+|\s+$//g;
	$list .= " " . $repo;
	$list =~ s/^\s+|\s+$//g;
	$ini{"group $group"}{$access eq 'r' ? 'readonly' : 'writable'} = $list;
	print ">>> Granted '$repo' " . ($access eq 'r' ? 'read-only' : 'write') . " access to '$group'.\n";
    } else {
	print ">>> Revoked '$repo' " . ($access eq 'r' ? 'read-only' : 'write') . " access from '$group'.\n";
    }
}

sub addGroup {
    my ($group, $members, $desc, @perms) = @_;
    my $key = "group $group";
    showHelp('add') unless(defined($group) && defined($members) && defined($desc));
    if (defined($ini{$key})) {
	print "Group '$group' already exists.\n";
	exit(-1);

    }
    $members = join(' ', sort split(/\s+/,$members));
    $ini{$key} = {};
    $ini{$key}{'members'} = $members;
    $ini{$key}{'description'} = $desc;
    print ">>> Created group '$group' with members '$members'.\n";
    while(scalar(@perms) > 0) {
	if (scalar(@perms) % 2) {
	    print "!!! Permissions should come in pairs: perm repo\n";
	} else {
	    my $perm = shift(@perms);
	    my $repo = shift(@perms);
	    if ($perm =~ /^(\-|\+)(r|w)$/) {
		my $permMod = $1;
		my $permAccess = $2;
		my $repoKey = "repo $repo";
		if(defined($ini{$repoKey})) {
		    setAccess($repo, $group, $permMod, $permAccess);
		} else {
		    print "!!! Repo '$repo' does not exist.\n";
		}
	    } else {
		print "!!! Unknown permission '$perm'.\n";
	    }
	}
    }
    tied(%ini)->RewriteConfig();
} # addRepo

sub showGroup {
    my ($group,@args) = @_;
    showHelp('group') unless(defined($group));
    my $section = 'group ' . $group;
    unless(defined($ini{$section})) {
	print "Group '$group' not found.\n";
	exit(-1);
    }
    my %params = %{$ini{$section}};
    print "Group: $group\n";
    print("Description: ${params{'description'}}\n") if(defined($params{'description'}));
    my $members = defined(${params{'members'}}) ? ${params{'members'}} : '';
    my %mems = ();
    foreach my $member (split(/\s+/, $members)) {
	$mems{$member} = 1;
    }
    my $needRewrite = 0;
    while (scalar(@args) > 0) {
	my $arg = shift(@args);
	showHelp('group') unless($arg =~ /^(\-|\+)([a-z0-9]+)$/);
	my $argMod = $1;
	my $argKey = $2;
	if (($argKey eq 'r') or ($argKey eq 'w')) {
	    my $repo = shift(@args);
	    showHelp('group') unless($repo);
	    my $repoKey = 'repo ' . $repo;
	    if(defined($ini{$repoKey})) {
		$needRewrite++;
		setAccess($repo, $group, $argMod, $argKey);
	    } else {
		print "!!! Repo '$repo' does not exist.\n";
	    }
	} else {
	    if ($argMod eq '+') {
		$mems{$argKey} = 1;
		$needRewrite++;
		print ">>> Added member $argKey.\n";
	    } else {
		if (defined($mems{$argKey})) {
		    delete($mems{$argKey});
		    $needRewrite++;
		    print ">>> Removed member $argKey.\n";
		} else {
		    print "!!! Member $argKey is not in the group.\n";
		}
	    }
	}
    }
    if ($needRewrite) {
	$ini{$section}{'members'} = join(' ', sort(keys(%mems)));
	tied(%ini)->RewriteConfig();
    }
    print("Members: ${ini{$section}{'members'}}\n");
    print("Read Repos: ${params{'readonly'}}\n") if(defined($params{'readonly'}));
    print("Write Repos: ${params{'writable'}}\n") if(defined($params{'writable'}));
} # showRepo
