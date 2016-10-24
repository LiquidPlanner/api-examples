<?php
// This is an example of how to use the LiquidPlanner API in PHP.
class LiquidPlanner {
  private $_base_uri = "https://app.liquidplanner.com/api";
  private $_ch;
  public  $workspace_id;

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

  public function put($url, $body=null) {
    curl_setopt($this->_ch, CURLOPT_CUSTOMREQUEST, 'PUT');
    curl_setopt($this->_ch, CURLOPT_URL, $this->_base_uri.$url);
    curl_setopt($this->_ch, CURLOPT_POSTFIELDS, json_encode($body));
    return json_decode(curl_exec($this->_ch));
  }

  public function account() {
    return $this->get('/account');
  }

  public function workspaces() {
    return $this->get('/workspaces');
  }

  public function projects() {
    return $this->get("/workspaces/{$this->workspace_id}/projects");
  }

  public function tasks() {
    return $this->get("/workspaces/{$this->workspace_id}/tasks");
  }

  public function create_task($data) {
    return $this->post("/workspaces/{$this->workspace_id}/tasks", array("task"=>$data));
  }

  public function update_task($data) {
    return $this->put("/workspaces/{$this->workspace_id}/tasks/{$data['id']}", array("task"=>$data));
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
    
    $account = $lp->account();
    echo "You are $account->user_name ($account->id)".PHP_EOL;
    
    $workspaces = $lp->workspaces();
    $count = count($workspaces);
    $plural = $count == 1 ? '' : 's';
    echo "You have $count workspace$plural".PHP_EOL;
    foreach($workspaces as $ws) {
      echo " $ws->name\n";
    }

    $ws = $workspaces[0];
    $lp->workspace_id = $ws->id;

    $projects = $lp->projects();
    $count = count($projects);
    echo "These are the $count projects in your '$ws->name' workspace".PHP_EOL;
    foreach($projects as $i => $p) {
      echo ' '.($i+1).'. '.$p->name.PHP_EOL;
    }

    echo "Should I add a task to your first project? (y for yes) ";
    $add_task = fgets(STDIN);
    if('Y' == strtoupper(substr(trim($add_task), 0, 1))) {
      $task = array( 'name' => 'learn the API', 'parent_id' => $projects[0]->id );
      $result = $lp->create_task($task);
      $update = array( 'name' => 'learn more about the API', 'id' => $result->id );
      print_r($lp->update_task($update));
    }

  }

}

if ($argv[0] == 'liquidplanner.php') {
  LiquidPlanner::demo();
}

?>
