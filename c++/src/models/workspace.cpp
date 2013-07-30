#include <string>

#include "workspace.h"

namespace LiquidPlannerModels {

  std::string Workspace::name() {
    return m["name"].asString();
  }

}
