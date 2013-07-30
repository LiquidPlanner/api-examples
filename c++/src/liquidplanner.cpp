#include <boost/iostreams/filtering_stream.hpp>
#include <boost/iostreams/filter/gzip.hpp>
#include <boost/lexical_cast.hpp>

#include "liquidplanner.h"

using namespace std;
using namespace LiquidPlannerModels;
namespace bio = boost::iostreams;

string LiquidPlanner::urlBase = "https://app.liquidplanner.com/api/";

//------------------------------------------------------------------------------
//-- Constructor
//------------------------------------------------------------------------------

LiquidPlanner::LiquidPlanner(string _username, string _password) {
  username = _username;
  password = _password;
}

/*
 *  These are the api requests that are made. Additonal api request can be
 *  added by following the examples below.
 */

//------------------------------------------------------------------------------
//-- Account
//------------------------------------------------------------------------------

Person LiquidPlanner::getAccount() {
  return model<Person>( 
    get("account")
  );
}
    
//------------------------------------------------------------------------------
//-- Workspace
//------------------------------------------------------------------------------

Workspaces LiquidPlanner::getWorkspaces() {
  return model<Workspaces>(
    get("workspaces") 
  );
}

//------------------------------------------------------------------------------
//-- Projects
//------------------------------------------------------------------------------

Projects LiquidPlanner::getProjects() {
  return model<Projects>(
    get("workspaces/" + itos(spaceId) + "/projects")
  );
}

//------------------------------------------------------------------------------
//-- Tasks
//------------------------------------------------------------------------------

// Get all
Tasks LiquidPlanner::getTasks() {
  return model<Tasks>(
    get("workspaces/" + itos(spaceId) + "/tasks")
  );
}

// Get one
Task LiquidPlanner::getTask(int taskId) {
  return model<Task>(
    get("workspaces/" + itos(spaceId) + "/tasks/" + itos(taskId))
  );
}

// Create
Task LiquidPlanner::createTask(Json::Value task) {
  Json::Value taskWrapper;
  taskWrapper["task"] = task;

  return model<Task>( 
    post("workspaces/" + itos(spaceId) + "/tasks", taskWrapper) 
  );
}

// Update
Task LiquidPlanner::updateTask(Task task, Json::Value taskUpdate) {
  Json::Value taskWrapper;
  taskWrapper["task"] = taskUpdate;

  return model<Task>(
    put(
      "workspaces/" + itos(spaceId) + "/tasks/" + itos(task.id()), 
      taskWrapper
    ) 
  );
}

// Destroy
void LiquidPlanner::deleteTask(Task task) {
  del("workspaces/" + itos(spaceId) + "/tasks/" + itos(task.id()));
}

//------------------------------------------------------------------------------
//-- Setters and getters for spaceId
//------------------------------------------------------------------------------

void LiquidPlanner::setSpace(int id) {
  spaceId = id;
}

int LiquidPlanner::getSpace() {
  return spaceId;
}

//------------------------------------------------------------------------------
//-- given an reponse, create a model
//------------------------------------------------------------------------------

template <typename ModelType>
ModelType LiquidPlanner::model(response r) {

  if (r.error.isNull()) {
    return ModelType(r.json);
  } else {
    Json::Value error;
    error["error"] = r.error;
    return ModelType(error);
  }

};

//------------------------------------------------------------------------------
//-- Rest Requests
//------------------------------------------------------------------------------

// GET
LiquidPlanner::response LiquidPlanner::get(string url) {
  RestClient::setAuth(username, password);

  RestClient::response r = RestClient::get(LiquidPlanner::urlBase + url);

  LiquidPlanner::response resp = processResponse(r);

  return resp;
}

// DELETE
LiquidPlanner::response LiquidPlanner::del(string url) {
  RestClient::setAuth(username, password);

  RestClient::response r = RestClient::del(LiquidPlanner::urlBase + url);

  LiquidPlanner::response resp = processResponse(r);

  return resp;
}

// POST
LiquidPlanner::response LiquidPlanner::post(string url, Json::Value data) {
  RestClient::setAuth(username, password);
  
  Json::FastWriter writer;

  RestClient::response r = RestClient::post(
    LiquidPlanner::urlBase + url,
    "application/json", 
    writer.write(data)
  );

  LiquidPlanner::response resp = processResponse(r);

  return resp;
}

// PUT
LiquidPlanner::response LiquidPlanner::put(string url, Json::Value data) {
  RestClient::setAuth(username, password);
  
  Json::FastWriter writer;

  RestClient::response r = RestClient::put(
    LiquidPlanner::urlBase + url,
    "application/json", 
    writer.write(data)
  );

  LiquidPlanner::response resp = processResponse(r);

  return resp;
}


//------------------------------------------------------------------------------
//-- Helpers
//------------------------------------------------------------------------------

LiquidPlanner::response LiquidPlanner::processResponse(RestClient::response r) {
  LiquidPlanner::response resp;
  resp.response = r;

  // Check response encoding. In some cases, the response comes back gzipped. 
  string encoding = r.headers["Content-Encoding"];
  size_t gzipPos = encoding.find("gzip");

  if (gzipPos != string::npos) {
    r.body = unzip(r.body);
  }

  // Check if response is json
  string contentType = r.headers["Content-Type"];
  size_t jsonPos = contentType.find("json");

  if (jsonPos != string::npos) {
    Json::Value parsedJson;
    Json::Reader reader;
    reader.parse(r.body, parsedJson);

    resp.json = parsedJson;
  }

  // Check status code
  int statusCode = atoi(r.headers["Status"].c_str());

  if (statusCode >= 200 && statusCode < 300) {
    // OK
  } else if (statusCode >= 300 && statusCode < 400) { 
    // Redirect
  } else if (statusCode >= 400 && statusCode < 600) { 
    // BadRequest 4XX
    // or Error 5XX
    if (resp.json.isNull()) {
      resp.error = Json::Value(r.body);
    } else {
      resp.error = resp.json;
      resp.json = Json::Value();
    } 
  }

  return resp;
}

// decompress a gzipped string
string LiquidPlanner::unzip(string in) {
  bio::filtering_ostream os;
  string out;

  os.push(bio::gzip_decompressor());
  os.push(bio::back_inserter(out));

  os << in;

  return out;
}

// toString
string LiquidPlanner::itos(int i) {
  return boost::lexical_cast<string>(i);
}
