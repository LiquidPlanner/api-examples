#!/usr/bin/env ruby

# You'll need the httparty (and highline, for the demo) gem
#
require 'httparty'

class LiquidPlanner
  include HTTParty

  base_uri 'https://app.liquidplanner.com/api'
  format :json

  attr_accessor :workspace_id

  def initialize(email, password)
    @opts = { :basic_auth => { :username => email, :password => password },
              :headers    => { 'content-type' => 'application/json' },
            }
  end

  def get(url, options={})
    self.class.get(url, options.merge(@opts))
  end

  def post(url, options={})
    options[:body] = options[:body].to_json if options[:body]
    self.class.post(url, options.merge(@opts))
  end

  def put(url, options={})
    options[:body] = options[:body].to_json if options[:body]
    self.class.put(url, options.merge(@opts))
  end

  def account
    get('/account')
  end

  def help
    get('/help.json')
  end

  def workspace_url
    "/workspaces/#{workspace_id}"
  end

  def workspaces
    get('/workspaces')
  end

  def members
    get("#{workspace_url}/members")
  end

  def teams
    get("#{workspace_url}/teams")
  end

  def get_treeitem id
    get("#{workspace_url}/treeitems/#{id}")
  end

  def projects
    get("#{workspace_url}/projects")
  end

  def tasks query = nil
    get("#{workspace_url}/tasks#{query}")
  end

  def create_task(data)
    post("#{workspace_url}/tasks", :body => { :task => data })
  end

  def update_task(data)
    put("#{workspace_url}/tasks/#{data['id']}", :body => { :task => data })
  end

  def events query = nil
    get("#{workspace_url}/events#{query}")
  end

  def update_assignment ti_id, assignment
    post("#{workspace_url}/treeitems/#{ti_id}/update_assignment", :body => assignment)
  end

  def self.connection
    email    = ask("LiquidPlanner email: ")
    password = ask("LiquidPlanner password for #{email}: ") {|q| q.echo = false}

    LiquidPlanner.new(email, password)
  end

  def self.demo
    lp = connection

    account = lp.account
    puts "You are #{account['user_name']} (#{account['id']})"

    workspaces = lp.workspaces
    puts "You have #{workspaces.length} workspace#{workspaces.length == 1 ? '' : 's'}"
    workspaces.each {|ws| puts " #{ws['name']}"}

    ws = workspaces.first
    lp.workspace_id = ws['id']

    projects = lp.projects
    puts "These are the #{projects.length} projects in your '#{ws['name']}' workspace"
    projects.each_with_index do |p, i|
      puts " #{i+1}. #{p['name']}"
    end

    add_task = ask "Should I add a task to your first project? (y for yes) "
    if 'Y' == add_task.strip[0].upcase
      task = { 'name' => 'learn the API', 'parent_id' => projects.first['id'] }
      result = lp.create_task(task)
      update = { 'name' => 'learn more about the API', 'id' => result['id'] } 
      puts lp.update_task(update).inspect
    end

  end

  def self.demo_multiple_owners
    lp = connection

    workspaces = lp.workspaces
    ws         = workspaces.first

    lp.workspace_id = ws['id']

    MultipleOwnerDemo.new lp
  end

end

class MultipleOwnerDemo
  attr_accessor :lp
  attr_accessor :members
  attr_accessor :teams

  def initialize( lp ) 
    self.lp = lp
    demo 
  end

  def members_indexed_by_id
    lp.members.inject( {} ) do |index, member| 
      index[ member[ 'id' ] ] = member
      index
    end
  end

  def teams_indexed_by_id
    lp.teams.inject( {} ) do |index, team| 
      index[ team[ 'id' ] ] = team
      index
    end
  end

  def assignments_for ti
    ti[ 'assignments' ]
  end

  def owners_for ti
    assignments_for( ti ).map do |assignment|
      members[ assignment[ 'person_id' ] ] || 
      teams[ assignment[ 'team_id' ] ] 
    end
  end

  def name_for owner
    case owner[ 'type' ];
      when "Member" then owner[ 'user_name' ]
      when "Team"   then owner[ 'name' ]
    end
  end

  def inspect_ownership ti
    id = ti[ 'id' ].to_s.rjust( 6 )
    name = ti[ 'name' ]
    owners = owners_for( ti ).map{ |e| name_for e }

    puts "#{ id }: #{ name } => #{ owners }"
  end

  def demo

    help = lp.help

    unless help[ "Task" ] && help[ "Task" ][ "assignments" ]
      puts "LiquidPlanner does not yet support multiple owners"
      exit
    end

    self.members = members_indexed_by_id
    self.teams = teams_indexed_by_id

    two_tasks  = lp.tasks( "?limit=2" )
    two_events = lp.events( "?limit=2" )

    if two_tasks.length < 2 || two_events.length < 2
      puts "Make sure you have at least two tasks and at least two events."
      exit
    end

    puts "We're going to swap ownership for the first two tasks, and the " +
         "two events: \n"

    puts "Tasks: (before)"
    two_tasks.each { |ti| inspect_ownership ti }
    puts "Events: (before)"
    two_events.each { |ti| inspect_ownership ti }

    # Swap the task owners

    assignment_1, assignment_2 = two_tasks.map { |task| 
      assignments_for( task ).first
    }

    two_tasks[0] = lp.update_assignment( two_tasks[0][ 'id' ], {
      :assignment_id => assignment_1[ 'id' ],
      :person_id     => assignment_2[ 'person_id' ],
      :team_id       => assignment_2[ 'team_id' ],
    })

    two_tasks[1] = lp.update_assignment( two_tasks[1][ 'id' ], {
      :assignment_id => assignment_2[ 'id' ],
      :person_id     => assignment_1[ 'person_id' ],
      :team_id       => assignment_1[ 'team_id' ],
    })

    # Swap the event owners

    assignment_1, assignment_2 = two_events.map { |task| 
      owners_for( task ).inject( {
        :person_ids => [],
        :team_ids => []
      } ) do |ids, owner| 
        case owner[ 'type' ];
          when "Member" then ids[ :person_ids ] << owner[ 'id' ]
          when "Team"   then ids[ :team_ids ] << owner[ 'id' ]
        end
        ids
      end
    }

    two_events[0] = lp.update_assignment( two_events[0][ 'id' ], assignment_2 )
    two_events[1] = lp.update_assignment( two_events[1][ 'id' ], assignment_1 )

    puts "\n\nTasks: (after)"
    two_tasks.each { |ti| inspect_ownership ti }
    puts "Events: (after)"
    two_events.each { |ti| inspect_ownership ti }

  end

end

if $0 == __FILE__
  require 'highline/import'
  if ARGV.length == 1 && ARGV[ 0 ] == "owners"
    LiquidPlanner.demo_multiple_owners
  else
    LiquidPlanner.demo
  end
end

