#include <string>

#include "project.h"

namespace LiquidPlannerModels {

  std::string Project::name() {
    return m["name"].asString();
  }

}
