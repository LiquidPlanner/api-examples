#ifndef _LIQUIDPLANNER_MODELS_MODEL_H
#define _LIQUIDPLANNER_MODELS_MODEL_H

#include <jsoncpp/json/json.h>

using namespace std;

namespace LiquidPlannerModels {

  /*
   * The Model is the base class representing objects returned from the api.
   * models serve to localize responsbility for knowing the specifc structure
   * and relationsships of a response type in to a single point of 
   * responsibility.
   */
  class Model {
    protected:
      Json::Value m;

    public: 
      Model(Json::Value model) { 
        m = model; 
      }

      int id() {
        return m["id"].asInt();
      }

      bool hasError() {
        return !m["error"].isNull();
      }

      Json::Value error() {
        return m["error"];
      }

      friend ostream& operator<<(ostream& out, Model m) {
        out << m.m;
        return out;
      }
  };

  /*
   * The Models class is a subclass of the std::vector used to contain a 
   * collection of Models based on a JSON array.
   */
  template <class ModelClass> 
  class Models : public vector<ModelClass> {

    public:
      Models(Json::Value v) : vector<ModelClass>() { 
        for(int i = 0; i < v.size(); i++) {
          push_back(ModelClass(v[i]));
        }
      }
  };
}

template <class T> 
ostream& operator<<(ostream& out, const LiquidPlannerModels::Models<T> m) {
  out << "testing";

  for (int i = 0; i < m.size(); i++) {
    out << " " << m[i] << " ";
  }

  return out;
}

#endif
