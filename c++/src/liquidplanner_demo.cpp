#include <iostream>
#include <termios.h>

#include "liquidplanner.h"

/*
 * LiquidPlanner C++ Api-Example
 *
 * See liquidplanner.cpp & h for examples of adding new requests.
 * See models/model.h for for the base Model.
 * Use models/person.cpp & h as a pattern for adding additional models.
 */

using namespace std;

template <typename Type> void print(Type ts) {
  for (typename Type::iterator i = ts.begin(); i < ts.end(); i++) {
    cout << "\t" << i->name() << endl;
  }
}

void echoOff();
void echoOn();

int main ()
{
  string username;
  string password;

  cout << "Enter username: ";
  cin >> username;

  echoOff();

  cout << "Enter password: ";
  cin >> password;

  echoOn();

  cout << endl;

//------------------------------------------------------------------------------
//- connect to LiquidPlanner
//------------------------------------------------------------------------------

  LiquidPlanner lp(username, password);

//------------------------------------------------------------------------------
//- get current user
//------------------------------------------------------------------------------

  Person account = lp.getAccount();
  if (account.hasError()) { 
    cout << "there was an error " << account.error() 
         << "check your username and password" << endl;
    return 1;
  } else {
    cout << account.fullName() << endl;
  }

//------------------------------------------------------------------------------
//- list spaces and select the first space
//------------------------------------------------------------------------------

  Workspaces spaces = account.workspaces();
  cout << endl << "Workspaces:" << endl;
  print<Workspaces>(spaces);
   
  Workspace firstSpace = spaces[spaces.size()-1];
  lp.setSpace(firstSpace.id());
  cout << endl << "Using: " << firstSpace.name() << endl;
  
//------------------------------------------------------------------------------
//- list projects
//------------------------------------------------------------------------------

  Projects firstSpaceProjects = lp.getProjects();
  cout << endl << firstSpace.name() << " tasks:" << endl;
  print<Projects>(firstSpaceProjects);

//------------------------------------------------------------------------------
//- create a new task
//------------------------------------------------------------------------------

  Json::Value taskParams;
  taskParams["name"] = "Learn the API";

  Task task = lp.createTask(taskParams);

//------------------------------------------------------------------------------
//- list tasks
//------------------------------------------------------------------------------

  Tasks firstSpaceTasks = lp.getTasks();
  cout << endl << "After create: ";
  cout << firstSpace.name() << " tasks:" << endl;
  print<Tasks>(firstSpaceTasks);
  
//------------------------------------------------------------------------------
//- update the task by renaming it
//- and setting its owner_id to the id of the account fetched above
//------------------------------------------------------------------------------

  taskParams["name"] = "update the api example";
  taskParams["owner_id"] = account.id();

  lp.updateTask(task, taskParams);

//------------------------------------------------------------------------------
//- and list tasks
//------------------------------------------------------------------------------

  firstSpaceTasks = lp.getTasks();
  cout << endl << "After update: ";
  cout << firstSpace.name() << " tasks:" << endl;
  print<Tasks>(firstSpaceTasks);

//------------------------------------------------------------------------------
//- update the task to clean up 
//------------------------------------------------------------------------------

  lp.deleteTask(task);

//------------------------------------------------------------------------------
//- and list tasks
//------------------------------------------------------------------------------

  firstSpaceTasks = lp.getTasks();
  cout << endl << "After delete: ";
  cout << firstSpace.name() << " tasks:" << endl;
  print<Tasks>(firstSpaceTasks);

//------------------------------------------------------------------------------
//- that's all folks! 
//------------------------------------------------------------------------------

  return 0;
}


//------------------------------------------------------------------------------
//- helpers to mute keystrokes when entering the password
//------------------------------------------------------------------------------

void echoOff() {
  termios tty;

  tcgetattr(STDIN_FILENO, &tty);

  tty.c_lflag &= ~ECHO;

  tcsetattr(STDIN_FILENO, TCSANOW, &tty);
}

void echoOn() {
  termios tty;

  tcgetattr(STDIN_FILENO, &tty);

  tty.c_lflag |= ECHO;

  tcsetattr(STDIN_FILENO, TCSANOW, &tty);
}
