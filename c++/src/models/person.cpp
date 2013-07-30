#include <string>

#include "person.h"

namespace LiquidPlannerModels {

  std::string Person::fullName() {
    return m["first_name"].asString() + " " + m["last_name"].asString();
  }

  Workspaces Person::workspaces() {
    if (!m["workspaces"].isNull()) {
      return Workspaces(m["workspaces"]);
    }
  }

}
