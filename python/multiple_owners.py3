#!usr/bin/python
#
# This is an example of how to use the LiquidPlanner API in Python.
#

# You need the Requests library, found at:
# http://docs.python-requests.org/en/latest/index.html
# note that Requests version 1.0 or later is required
#
import sys

import requests

import json
import getpass

class LiquidPlanner:

    base_uri     = 'https://app.liquidplanner.com/api'
    workspace_id = None
    email        = None
    password     = None
    session      = None

    members_c    = None
    teams_c      = None

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

    # returns a dictionary with server capabilities information
    def help( self ):
      return self.get( '/help.json' ).json()

  
    # returns a list of dictionaries, each a workspace in which this user is a member
    def workspaces( self ):
        return self.get( '/workspaces' ).json()
    
    # returns a list of dictionaries, each a project in a workspace  
    def projects( self ):
        return self.get( '/workspaces/' + str(self.workspace_id) +
                         '/projects' ).json()
  
    # returns a list of dictionaries, each a task in a workspace  
    def tasks( self, query = "" ):
        return self.get( '/workspaces/' + str(self.workspace_id) +
                         '/tasks' + query ).json()

    # returns a list of dictionaries, each a event in a workspace  
    def events( self, query = "" ):
        return self.get( '/workspaces/' + str(self.workspace_id) +
                         '/events' + query ).json()
   
    # creates a task by POSTing data
    def create_task( self, data ):
        return self.post( '/workspaces/' + str(self.workspace_id) +
                          '/tasks', json.dumps({ 'task': data }) ).json()
    
    # updates a task by PUTing data
    def update_task( self, data ):
        return self.put( '/workspaces/' + str(self.workspace_id) +
                         '/tasks/' + str(data['id']), 
                         json.dumps({ 'task' : data }) ).json()

    def members( self ):
        return self.get( '/workspaces/' + str(self.workspace_id) +
                         '/members' ).json()

    def teams( self ):
        return self.get( '/workspaces/' + str(self.workspace_id) +
                         '/teams' ).json()

    def update_assignment( self, ti_id, assignment ):
        return self.post( '/workspaces/' + str(self.workspace_id) +
                          '/treeitems/'  + str( ti_id ) +
                          '/update_assignment', 
                          json.dumps( assignment ) ).json()

    def members_indexed_by_id( self ):
      members = {}

      for member in self.members():
        members[ member[ 'id' ] ] = member 

      return members

    def teams_indexed_by_id( self ):
      teams = {}

      for team in self.teams():
        teams[ team[ 'id' ] ] = team 

      return teams

    def assignments_for( self, ti ):
      return ti[ 'assignments' ]

    def owner_for( self, ti ):
      if 'person_id' in ti:
        return self.members_c[ ti[ 'person_id' ] ] 
      else:
        return self.teams_c[ ti[ 'team_id' ] ]

    def owners_for( self, ti ):
      return map( (lambda e: self.owner_for(e)), self.assignments_for( ti ) )

    def name_for( self, owner ):
      if owner[ 'type' ] == 'Member':
        return owner[ 'user_name' ]
      else:
        return owner[ 'name' ] 

    def inspect_ownership( self, ti ):
      id = str( ti[ 'id' ] ).rjust( 9 )
      name = ti[ 'name' ]
      owners = list( map( (lambda e: self.name_for( e )), self.owners_for( ti ) ) )

      print( "%(id)s: %(name)s => %(owners)s" % locals() )

    def event_owners( self, ti ):
      ids = { 
        'person_ids': [], 
        'team_ids': [] 
      }
      for owner in self.owners_for( ti ):
        if owner[ 'type' ] == "Member":
          ids[ 'person_ids' ].append( owner[ 'id' ] )
        else:
          ids[ 'team_ids' ].append( owner[ 'id' ] )
      return ids
      

    # demonstrates usage of the LP class
    @staticmethod
    def demo():
      email    = input( "Enter your e-mail address: " )
      password = getpass.getpass( "Enter your password: " )

      LP = LiquidPlanner( email, password )

      help = LP.help()

      if not ( ( 'Task' in help ) and ( 'assignments' in help[ 'Task' ] ) ):
        print( "LiquidPlanner does not yet support multiple owners" )
        sys.exit( 0 )

      workspace = LP.workspaces()[ 0 ]
      LP.set_workspace_id( workspace[ 'id' ] )
      LP.set_workspace_id( 1188 )

      LP.members_c = LP.members_indexed_by_id()
      LP.teams_c   = LP.teams_indexed_by_id()

      two_tasks = LP.tasks( "?limit=2" )
      two_events = LP.events( "?limit=2" )

      if ( len(two_tasks) < 2 or len(two_events) < 2 ):
        print( "Make sure you have at least two tasks and at least two events." )
        sys.exit(0)

      print( "We're going to swap ownership for the first two tasks, and the " +
             "two events: \n" )

      print( "Tasks: (before)" )
      for ti in two_tasks:
        LP.inspect_ownership( ti )
      print( "Events: (before)" )
      for ti in two_events:
        LP.inspect_ownership( ti )

      # Swap the Task owners
        
      assignment_1, assignment_2 = map( 
        (lambda task: LP.assignments_for( task )[0] ), 
        two_tasks )

      two_tasks[0] = LP.update_assignment( two_tasks[0][ 'id' ], {
        "assignment_id":  assignment_1[ 'id' ],
        "person_id":  assignment_2.get( 'person_id', [] ),
        "team_id":  assignment_2.get( 'team_id', [] ),
      })

      two_tasks[1] = LP.update_assignment( two_tasks[1][ 'id' ], {
        "assignment_id":  assignment_2[ 'id' ],
        "person_id":  assignment_1.get( 'person_id', [] ),
        "team_id":  assignment_1.get( 'team_id', [] ),
      })

      # Swap the Event owners

      assignment_1, assignment_2 = map( (lambda x: LP.event_owners( x )), two_events )

      two_events[0] = LP.update_assignment( two_events[0][ 'id' ], assignment_2 )
      two_events[1] = LP.update_assignment( two_events[1][ 'id' ], assignment_1 )

      print( "Tasks: (after)" )
      for ti in two_tasks:
        LP.inspect_ownership( ti )
      print( "Events: (after)" )
      for ti in two_events:
        LP.inspect_ownership( ti )

# invoke the demo, if you run this file from the command line
if __name__ == '__main__':
    LiquidPlanner.demo()

