#include <string>

#include "task.h"

namespace LiquidPlannerModels {

  std::string Task::name() {
    return m["name"].asString();
  }

}
