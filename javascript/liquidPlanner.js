var fs            = require('fs'),
    stream        = require('stream'),
    request       = require('request'),
    zlib          = require('zlib'),
                                                                  
    host          = 'https://app.liquidplanner.com';

function LiquidPlanner(email,password) {
  this.email = email;
  this.password = password;
}

var __ = LiquidPlanner.prototype; 

//------------------------------------------------------------------------------

//gets account information about the current user
__.account = function(cb) {
  this.get('account', cb);
};

//gets information about all workspaces of which the current user is a member
__.workspaces = function(cb) {
  this.get('workspaces', cb);
};

//gets information about all projects in the current workspace
__.projects = function(cb) {
  this.get("workspaces/" + this.spaceId + "/projects", cb);
};


//gets informations about all tasks in the current workspace
__.tasks = function(cb) {
  this.get("workspaces/" + this.spaceId + "/tasks", cb);
};

//creates a task by POSTing data
__.createTask = function(taskObject, cb) {
  this.post({
    url: "workspaces/" + this.spaceId + "/tasks",
    params: {
      task: taskObject
    }
  }, cb);
};

//------------------------------------------------------------------------------

__.setSpace = function(spaceOrSpaceId) {
  if (spaceOrSpaceId.id) {
    this.spaceId = spaceOrSpaceId.id;
  } else {
    this.spaceId = spaceOrSpaceId;
  }
};

__._addVerb = function(verb, opts, cb) {
  if (typeof opts == 'string') {
    opts = { url : opts };
  }

  opts.verb = verb;
  this.request(opts, cb);
};

__.get        = function(opts, cb) { this._addVerb('GET', opts, cb);    };
__.put        = function(opts, cb) { this._addVerb('PUT', opts, cb);    };
__.post       = function(opts, cb) { this._addVerb('POST', opts, cb);   };
__['delete']  = function(opts, cb) { this._addVerb('DELETE', opts, cb); };

//------------------------------------------------------------------------------

__.request =  function(opts, cb) {
  if (typeof opts == 'string') {
    opts = { url : opts };
  }

  var method        = opts.verb || 'GET',
      url           = host + '/api/' + opts.url,
      requestParams = {
        uri      : url,
        method   : method,
        opts     : opts.params,
        delegate : opts.delegate,
        auth     : { user: this.email, pass: this.password }
      },
      requestObject;

  if (opts.params) {
    this.attachParamsToRequest(method, requestParams, opts);
  }

  requestObject = request(requestParams, this.onResponse.bind(this, cb, requestParams))
    .on('response', function(resp) {
      if (resp.headers['content-encoding'] == 'gzip') {
        var out = '',
            s = new stream.Stream();

        s.write = function(chunk) {
          out += chunk.toString();
        };

        s.end = function() {
          resp.headers['content-encoding'] = undefined;
          this.onResponse( cb, requestParams, null, resp, out );
        }.bind(this);

        resp.pipe(zlib.createGunzip()).pipe(s);
      }
    }.bind(this));

  return requestObject;
};

//------------------------------------------------------------------------------

__.onResponse = function(cb, requestParams, error, response, body) {
  var self = this;

  if ( response.headers['content-encoding'] == 'gzip' ) {
    // ignore it, there will be another call when the listener catches and
    // gunzips it.
  } else {
    this.deliverResponse.apply(this, arguments);
  }
};

__.deliverResponse = function(cb, requestParams, error, response, body) {
  var contentType = response.headers['content-type'],
      ob;

  if (contentType && 
      contentType.match(/application\/json/) && 
      typeof body == 'string') {
    ob = JSON.parse(body); 
  } else {
    ob = body;
  }

  if (!error && ob && ob.type == 'Error') {
    error = body;
  }

  if (error && error.error != "Throttled") { 
    
    if (requestParams.delegate && requestParams.delegate.log) {
      requestParams.delegate.log("Error " + requestParams.uri);
      requestParams.delegate.log(JSON.stringify(error));
    } else {
      console.log(requestParams.uri, error);
    }
  }

  cb(ob, response, error);
};

//------------------------------------------------------------------------------

__.attachParamsToRequest = function(method, requestParams, opts) {
  if (method == 'GET') { 
    requestParams.qs = opts.params;
  } else {
    requestParams.json = opts.params;
  }
};

module.exports = LiquidPlanner
