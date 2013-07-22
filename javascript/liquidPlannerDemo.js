var LiquidPlanner = require('./liquidPlanner'),
    read          = require('read'),
    flow          = require('flow');

var user, password, lp;

flow.exec(
  function getEmailAndPassword() { var done = this;

    read({ prompt: 'Enter your e-mail address: ' }, function(er, _email) {
      user = _email;

      read({ prompt: 'Enter your password: ', silent: true }, function(er, _password) {
        password = _password;
        
        done();
      });
    });

  },
  function connectToLiquidPlanner() {

    lp = new LiquidPlanner( user, password );

    this();

  },
  function workspaces() { var done = this;

    console.log("Defaulting to your first workspace...");
    lp.workspaces(function( workspaces ) {
      lp.setSpace(workspaces[0]);
      done(); 
    });

  }, 
  function showProjects() { var done = this;

    console.log("Here is a list of all your projects...");
    lp.projects(function( projects ) {
      for (var i = 0; i < projects.length; i++) {
        console.log(projects[i].name);
      }

      done();
    });

  }, 
  function addATask() {

    console.log("Adding a task...");
    lp.createTask({ name: "learn the API" }, this); 

  }, 
  function listAllTasks() { var done = this;

    console.log("Here is a list of all your tasks: ");
    lp.tasks(function(tasks) {
      for (var i = 0; i < tasks.length; i++) {
        console.log(tasks[i].name);
      }

      done();
    });

  }
);
