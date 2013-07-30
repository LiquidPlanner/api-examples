#ifndef _LIQUIDPLANNER_MODELS_TASK_H
#define _LIQUIDPLANNER_MODELS_TASK_H

#include "model.h"

namespace LiquidPlannerModels {

  class Task : public Model {
    public:  
      Task(Json::Value v) : Model(v) {}

      std::string name();
  };

  typedef Models<Task> Tasks;

}

#endif
