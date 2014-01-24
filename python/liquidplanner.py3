#!usr/bin/python
#
# This is an example of how to use the LiquidPlanner API in Python.
#

# You need the Requests library, found at:
# http://docs.python-requests.org/en/latest/index.html
# note that Requests version 1.0 or later is required
#
import requests

import json
import getpass

class LiquidPlanner:

    base_uri     = 'https://app.liquidplanner.com/api'
    workspace_id = None
    email        = None
    password     = None
    session      = None

    def __init__( self, email, password ):
        self.email    = email
        self.password = password
  
    def get_workspace_id( self ):
        return self.workspace_id
    
    def set_workspace_id( self, workspace_id ):
        self.workspace_id = workspace_id
  
    def get( self, uri, options={} ):
        return requests.get( self.base_uri + uri, 
          data    = options,
          headers = { 'Content-Type': 'application/json' },
          auth    = ( self.email, self.password )
        )
    
    def post( self, uri, options={} ):
        return requests.post( self.base_uri + uri, 
          data    = options,
          headers = { 'Content-Type': 'application/json' },
          auth    = ( self.email, self.password )
        )
    
    def put( self, uri, options={} ):
        return requests.put( self.base_uri + uri, 
          data    = options,
          headers = { 'Content-Type': 'application/json' },
          auth    = ( self.email, self.password )
        )
  
    # returns a dictionary with information about the current user  
    def account( self ):
        return self.get( '/account' ).json()
  
    # returns a list of dictionaries, each a workspace in which this user is a member
    def workspaces( self ):
        return self.get( '/workspaces' ).json()
    
    # returns a list of dictionaries, each a project in a workspace  
    def projects( self ):
        return self.get( '/workspaces/' + str(self.workspace_id) +
                         '/projects' ).json()
  
    # returns a list of dictionaries, each a task in a workspace  
    def tasks( self ):
        return self.get( '/workspaces/' + str(self.workspace_id) +
                         '/tasks' ).json()
   
    # creates a task by POSTing data
    def create_task( self, data ):
        return self.post( '/workspaces/' + str(self.workspace_id) +
                          '/tasks', json.dumps({ 'task': data }) ).json()
    
    # updates a task by PUTing data
    def update_task( self, data ):
        return self.put( '/workspaces/' + str(self.workspace_id) +
                         '/tasks/' + str(data['id']), 
                         json.dumps({ 'task' : data }) ).json()

    # demonstrates usage of the LP class
    @staticmethod
    def demo():
        email    = input( "Enter your e-mail address: " )
        password = getpass.getpass( "Enter your password: " )
        add_task = 'Y' == input( "Add a task? (Y for yes): " )[0].upper()
        LP = LiquidPlanner( email, password )

        workspace = LP.workspaces()[ 0 ]
        print( "Defaulting to your first workspace, '%s'..." % ( workspace[ 'name' ] ) )
        LP.set_workspace_id( workspace[ 'id' ] )

        print( "Here is a list of all of your projects:" )
        projects = LP.projects()
        for project in projects:
            print( project[ 'name' ] )

        if add_task:
            print( "Adding a new task to your first project..." )
            project_id = projects[ 0 ][ 'id' ]
            new_task = LP.create_task({ 
              "name"      : "learn the API",
              "parent_id" : int(project_id) 
            })
            print( "Added task %(name)s with id %(id)s" % new_task )
        else:
            print( "Skipped adding a new task" )

        print( "Here is a list of your tasks:" )
        tasks = LP.tasks()
        for task in tasks:
            print( task[ 'name' ] )

# invoke the demo, if you run this file from the command line
if __name__ == '__main__':
    LiquidPlanner.demo()

