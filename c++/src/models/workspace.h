#ifndef _LIQUIDPLANNER_MODELS_WORKSPACE_H
#define _LIQUIDPLANNER_MODELS_WORKSPACE_H

#include "model.h"

namespace LiquidPlannerModels {

  class Workspace : public Model {
    public:  
      Workspace(Json::Value v) : Model(v) {}

      std::string name();
  };

  typedef Models<Workspace> Workspaces;

}

#endif
