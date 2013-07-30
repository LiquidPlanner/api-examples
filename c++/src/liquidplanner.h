#ifndef _LIQUIDPLANNER_LIQUIDPLANNER_H
#define _LIQUIDPLANNER_LIQUIDPLANNER_H

#include <string>
#include <jsoncpp/json/json.h>

#include "restclient.h"

#include "models.h"

using namespace LiquidPlannerModels;

class LiquidPlanner {
  // storage for a LiquidPlanner::response
  typedef struct {
    int statusCode;
    Json::Value error;
    Json::Value json;
    RestClient::response response;
  } response;

  static std::string urlBase;

  std::string username;
  std::string password;
  int spaceId;

  public: 
    LiquidPlanner(std::string username, std::string password);

    void setSpace(int id);
    int getSpace();

    //Account
    Person getAccount();

    //Workspaces
    Workspaces getWorkspaces();

    //Projects
    Projects getProjects();

    //Tasks
    Tasks getTasks();
    Task getTask(int taskId);
    Task createTask(Json::Value task);
    Task updateTask(Task task, Json::Value update);
    void deleteTask(Task task);

  protected: 
    response get(std::string url);
    response del(std::string url);
    response post(std::string url, Json::Value data);
    response put(std::string url, Json::Value data);

    template <typename ModelType>
    ModelType model(response r);

    response processResponse(RestClient::response r);

    std::string unzip(std::string in); 

    std::string itos(int i);
};

#endif
