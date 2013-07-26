package LiquidPlanner;

use REST::Client;
use MIME::Base64;
use IO::Uncompress::Gunzip 'gunzip';
use JSON qw(encode_json decode_json);

use feature qw(say);

# Create an authenticated client 
#
sub new  {
  my $class = shift;
  my ( $email, $pass ) = @_;

  my $self = { }; bless $self, $class;

  $self->{_client} = $self->create_client( $email, $pass );

  return $self;
}

sub set_space {
  my $self = shift;
  my ( $space ) = @_;

  $self->{_space} = $space->{id};
}


##------------------------------------------------------------------------------
##-- Api Calls
##------------------------------------------------------------------------------

sub get_account {
  my $self = shift;

  return $self->get_json("account");
}

sub get_workspaces {
  my $self = shift;

  return $self->get_json("workspaces");
}

sub get_projects {
  my $self = shift;

  return $self->get_json('workspaces/' . $self->{_space} . '/projects');
}

sub get_tasks {
  my $self = shift;

  return $self->get_json('workspaces/' . $self->{_space} . '/tasks');
}

sub create_task {
  my $self = shift;
  my ( $task ) = @_;

  return $self->post_json(
    'workspaces/' . $self->{_space} . '/tasks',
    { task => $task }
  );
}

sub update_task {
  my $self = shift;
  my ( $task_id, $task ) = @_;

  return $self->put_json(
    'workspaces/' . $self->{_space} . '/tasks/' . $task_id,
    { task => $task }
  );
}

sub delete_task {
  my $self = shift;
  my ( $task_id ) = @_;

  return $self->delete_json(
    'workspaces/' . $self->{_space} . '/tasks/' . $task_id
  );
}

##------------------------------------------------------------------------------
##-- Verbs
##------------------------------------------------------------------------------

# GET a request and parse the resulting JSON
#
sub get_json {
  my $self = shift;
  my ( $url ) = @_;

  $url = '/api/' . $url;

  return $self->process_json_response( 
    $self->{_client}->GET( $url )
  );
}

# PUT a request and parse the resulting JSON
#
sub put_json {
  my $self = shift;
  my ( $url, $data ) = @_;

  $url = '/api/' . $url;

  return $self->process_json_response( 
    $self->{_client}->PUT( 
      $url,
      encode_json( $data ),
      { 'content-type' => 'application/json' }
    )
  );
}

# POST a request and parse the resulting JSON
#
sub post_json {
  my $self = shift;
  my ( $url, $data ) = @_;

  $url = '/api/' . $url;

  return $self->process_json_response( 
    $self->{_client}->POST( 
      $url,
      encode_json( $data ),
      { 'content-type' => 'application/json' }
    )
  );
}

# DELETE a request and parse the resulting JSON
#
sub delete_json {
  my $self = shift;
  my ( $url, $data ) = @_;

  $url = '/api/' . $url;

  return $self->process_json_response( 
    $self->{_client}->DELETE( $url )
  );
}

## handle json_response
#
sub process_json_response {
  my $self = shift;
  my ( $client ) = @_;
  my $response_json;

  if ( ( $client->responseHeader('Content-Encoding') =~ /gzip/i ) == 1 ) {
    gunzip \$client->responseContent() => \$response_json; 
  } else {
    $response_json = $client->responseContent();
  }

  return decode_json( $response_json )
}

##------------------------------------------------------------------------------
##-- Client Connection
##------------------------------------------------------------------------------

# Create an authenticated client 
#
sub create_client {
  my $self = shift;
  my ( $email, $pass ) = @_;

  my $basic_auth = MIME::Base64::encode_base64("$email:$pass");
    
  my $client = REST::Client->new({ host => "https://app.liquidplanner.com" });

  $client->addHeader('Authorization', "Basic $basic_auth");
  
  return $client;
}

1;
