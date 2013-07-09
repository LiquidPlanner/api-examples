<?
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

  public function comment_stream($limit=3) {
    return $this->get("/workspaces/{$this->workspace_id}/comment_stream?limit={$limit}");
  }

}

?>
<?

  // LP config
  $email        = '';
  $password     = '';
  $workspace_id = '';

  // GeckoBoard config
  $gecko_api_key    = '';
  $gecko_widget_key = '';

  // Get most recent comments
  $lp = new LiquidPlanner($email, $password);
  $lp->workspace_id = $workspace_id;
  $comments = $lp->comment_stream();

  // translates an LP comment to the format GeckoBoard expects
  function gecko_text($lp_comment) {
    return array(
      "text" => $lp_comment->comment,
      "type" => 0,
    );
  }

  // apply translation across the comments we received
  $gecko_data = array(
    "api_key" => $gecko_api_key,
    "data" => array( "item" => array_map("gecko_text", $comments) )
  );

  $gecko_json = json_encode($gecko_data);

  $gecko_curl = curl_init();
  curl_setopt($gecko_curl, CURLOPT_POST, true);
  curl_setopt($gecko_curl, CURLOPT_URL, "https://push.geckoboard.com/v1/send/{$gecko_widget_key}" );
  curl_setopt($gecko_curl, CURLOPT_POSTFIELDS, $gecko_json);
  curl_exec($gecko_curl);

?>
