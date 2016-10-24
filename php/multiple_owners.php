<?php
// This is an example of how to use the LiquidPlanner API in PHP.
class LiquidPlanner {
  private $_base_uri = "https://app.liquidplanner.com/api";
  private $_ch;

  public $workspace_id;
  public $member_lookup;
  public $team_lookup;

  function __construct($email, $password) {
    $this->_ch = curl_init();
    curl_setopt($this->_ch, CURLOPT_HEADER, false);
    curl_setopt($this->_ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($this->_ch, CURLOPT_USERPWD, "$email:$password");
    curl_setopt($this->_ch, CURLOPT_HTTPHEADER, array('content-type: application/json'));
    curl_setopt($this->_ch, CURLOPT_ENCODING, 'gzip');
  }

  public function get($url) {
    curl_setopt($this->_ch, CURLOPT_HTTPGET, true);
    curl_setopt($this->_ch, CURLOPT_URL, $this->_base_uri.$url);
    return json_decode(curl_exec($this->_ch));
  }

  public function post($url, $body=null) {
    curl_setopt($this->_ch, CURLOPT_POST, true);
    curl_setopt($this->_ch, CURLOPT_URL, $this->_base_uri.$url);
    curl_setopt($this->_ch, CURLOPT_POSTFIELDS, json_encode($body));
    return json_decode(curl_exec($this->_ch));
  }

  public function help() {
    return $this->get('/help.json');
  }

  public function workspaces() {
    return $this->get('/workspaces');
  }

  public function tasks( $query = "" ) {
    return $this->get( "/workspaces/{$this->workspace_id}/tasks" . $query );
  }

  public function events( $query = "" ) {
    return $this->get( "/workspaces/{$this->workspace_id}/events" . $query );
  }

  public function members() {
    return $this->get( "/workspaces/{$this->workspace_id}/members" );
  }

  public function teams() {
    return $this->get( "/workspaces/{$this->workspace_id}/teams" );
  }

  public function update_assignment( $ti_id, $data ) {
    return $this->post( "/workspaces/{$this->workspace_id}/treeitems" .
                        "/{$ti_id}/update_assignment", $data );
  }

  public function workspace_members() {
    $members = $this->members();
    $ret = array();
    foreach( $members as &$member ) {
      $ret[ $member->id ] = $member;
    }
    return $ret;
  }

  public function workspace_teams() {
    $teams = $this->teams();
    $ret = array();
    foreach( $teams as &$team ) {
      $ret[ $team->id ] = $team;
    }
    return $ret;
  }

  public function owners_for( $ti ) {
    $that = $this;
    return array_map( function( $assignment ) use ( $that ) {
      if ( isset( $assignment->person_id ) ) {
        return $that->member_lookup[ $assignment->person_id ] ?: NULL;
      } else if ( isset( $assignment->team_id ) ) {
         return $that->team_lookup[ $assignment->team_id ] ?: NULL;
      }
    }, $ti->assignments );
  }

  public function name_for( $owner ) {
    if ( $owner->type == "Member" ) {
      return $owner->user_name;
    } else {
      return $owner->name;
    }
  }

  public function event_owners( $event ) {
    $person_ids = array();
    $team_ids = array();

    $owners = $this->owners_for( $event );
    foreach( $owners as &$owner ) {
      if ( $owner->type == "Member" ) {
        $person_ids[] = $owner->id;
      } else {
        $team_ids[] = $owner->id;
      }
    }
    return array(
      'person_ids' => $person_ids,
      'team_ids' => $team_ids
    );
  }

  public function inspect_ownership( $ti ) {
    $self = $this;
    $id = str_pad( $ti->id, 10, " ", STR_PAD_LEFT );
    $name = $ti->name;
    $owners = join( ',', array_map( array( $this, "name_for" ),
                         $this->owners_for( $ti ) ) );

    print( $id . ": " . $name . " => " . $owners . PHP_EOL );
  }

  public static function demo() {
    echo "LiquidPlanner email: ";
    $email = trim(fgets(STDIN));
    echo "LiquidPlanner password for $email: ";
    system('stty -echo');
    $password = trim(fgets(STDIN));
    system('stty echo');
    echo PHP_EOL;

    $lp = new LiquidPlanner($email, $password);

    $workspaces = $lp->workspaces();
    $lp->workspace_id = $workspaces[0]->id;

    $help = $lp->help();

    if ( !isset( $help->Task ) || !isset( $help->Task->assignments ) ) {
      print( "LiquidPlanner does not yet support multiple owners" . PHP_EOL );
      exit();
    }

    $two_tasks  = $lp->tasks( "?limit=2" );
    $two_events = $lp->events( "?limit=2" );

    if ( count( $two_tasks ) < 2 || count( $two_events ) < 2 ) {
      print( "Make sure you have at least two tasks and at least two events." . PHP_EOL );
      exit();
    }

    $lp->member_lookup = $lp->workspace_members();
    $lp->team_lookup   = $lp->workspace_teams();

    print( "We're going to swap ownership for the first two tasks, and the " .
           "two events: " . PHP_EOL );

    print( "Tasks: (before)" . PHP_EOL );
    foreach( $two_tasks as &$task ) { $lp->inspect_ownership( $task ); }
    print( "Events: (before)" . PHP_EOL );
    foreach( $two_events as &$event ) { $lp->inspect_ownership( $event ); }

    list( $assignment_1, $assignment_2 ) = array_map( function( $task ) {
      return $task->assignments[0];
    }, $two_tasks );

    $two_tasks[0] = $lp->update_assignment( $two_tasks[0]->id, array(
      "assignment_id" => $assignment_1->id,
      "person_id"     => isset( $assignment_2->person_id ) ? $assignment_2->person_id : NULL,
      "team_id"       => isset( $assignment_2->team_id )   ? $assignment_2->team_id   : NULL,
    ) );

    $two_tasks[1] = $lp->update_assignment( $two_tasks[1]->id, array(
      "assignment_id" => $assignment_2->id,
      "person_id"     => isset( $assignment_1->person_id ) ? $assignment_1->person_id : NULL,
      "team_id"       => isset( $assignment_1->team_id )   ? $assignment_1->team_id   : NULL,
    ) );

    list( $assignment_1, $assignment_2 ) = array_map( function( $event ) use ( $lp ) {
      return $lp->event_owners( $event );
    }, $two_events );

    $two_events[0] = $lp->update_assignment( $two_events[0]->id, $assignment_2 );
    $two_events[1] = $lp->update_assignment( $two_events[1]->id, $assignment_1 );

    print( "Tasks: (after)" . PHP_EOL );
    foreach( $two_tasks as &$task ) { $lp->inspect_ownership( $task ); }
    print( "Events: (after)" . PHP_EOL );
    foreach( $two_events as &$event ) { $lp->inspect_ownership( $event ); }

  }

}

if ($argv[0] == 'multiple_owners.php') {
  LiquidPlanner::demo();
}

?>
