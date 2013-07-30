#ifndef _LIQUIDPLANNER_MODELS_PROJECT_H
#define _LIQUIDPLANNER_MODELS_PROJECT_H

#include "model.h"

namespace LiquidPlannerModels {

  class Project : public Model {
    public:  
      Project(Json::Value v) : Model(v) {}

      std::string name();
  };

  typedef Models<Project> Projects;

}

#endif
