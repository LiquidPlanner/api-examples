use LiquidPlanner;
use Term::ReadKey;
use JSON qw(encode_json decode_json);

use feature qw(say);

##------------------------------------------------------------------------------

print "Enter email address: ";
my $email = <STDIN>; 
chomp ($email);

ReadMode( "noecho" );

print "Enter password: ";
my $pass  = <STDIN>; 
chomp ($pass);

ReadMode( "original" );

##------------------------------------------------------------------------------

# connect to LiquidPlanner
my $lp = new LiquidPlanner($email, $pass);

# load account
my $account = $lp->get_account();
# describe it a bit
say 'Account:';
say sprintf "  %-11s : %s", $account->{id}, $account->{user_name};

# get spaces
my @spaces = @{ $lp->get_workspaces() };
# describe them
say "\nSpaces:";
for $space ( @spaces) {
  say sprintf "  %-11s : %s", $space->{id}, $space->{name};
}

# select the first space
$lp->set_space( @spaces[0] );

# list projects in the space
my @projects = @{ $lp->get_projects() };

say "\nProjects:";
for $project ( @projects) {
  say sprintf "  %-11s : %s", $project->{id}, $project->{name};
}

my $first_project = @projects[0];

# add a task to the first space
my $task = $lp->create_task({
  name      => "learn the perl api",
  parent_id => $first_project->{id}
});

# update the newly created task
$lp->update_task( $task->{id}, {
  name     => "update the api",
  owner_id => $account->{id}
} );

# list all the tasks
my @tasks = @{ $lp->get_tasks() };
say "\nTasks:";
for $task ( @tasks ) {
  say sprintf "  %-11s : %s", $task->{id}, $task->{name};
}


# clean up by deleting the task
$lp->delete_task( $task->{id} );
