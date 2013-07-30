#ifndef _LIQUIDPLANNER_MODELS_PERSON_H
#define _LIQUIDPLANNER_MODELS_PERSON_H

#include "model.h"
#include "workspace.h"

namespace LiquidPlannerModels {

  /*
   * Person model demonstrates both an accessor (fullname), as well as how to
   * represent nested resources (account contains workspaces:[]).
   */
  class Person : public Model {
    public:  
      Person(Json::Value v) : Model(v) {}

      std::string fullName();

      Workspaces workspaces();
  };

}

#endif
