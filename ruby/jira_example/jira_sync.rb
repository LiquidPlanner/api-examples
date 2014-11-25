require 'liquidplanner'
require 'jira'
require 'yaml'


################################################################################
##                                                                            ##
## Demo: LiquidPlanner & JIRA integration in Ruby.                            ##
##                                                                            ##
## Inspired by Wim Deblauwe's blog post.                                      ##
##                                                                            ##
################################################################################



#===============================================================================
# Load connection optionsg

lp_opts   = YAML::load_file( 'opts.yml' ).symbolize_keys
jira_opts = { :context_path   => "",
              :auth_type      => :basic,
              :rest_base_path => "/rest/api/latest" 
            }.merge! YAML::load_file( 'jira_opts.yml' ).symbolize_keys

#===============================================================================



#===============================================================================
# Define the two sync points

space_id = lp_opts.delete   :space_id

unless space_id
  puts "Error: expected opts.yml to contain a space_id property"
  exit
end

#===============================================================================



#===============================================================================
# Create client connections

lp = LiquidPlanner::Base.new( lp_opts )

jira = JIRA::Client.new( jira_opts )

workspace = lp.workspaces( space_id )

#===============================================================================



#===============================================================================
# Get LiquidPlanner members and index them by email ( or name for virtuals ).

lp_members         = workspace.members
lp_members_i_id    = lp_members.index_by( &:id )
lp_members_i_email = lp_members.index_by do |member|
  member.is_virtual ? member.user_name : member.email 
end

#===============================================================================



#===============================================================================
# Get Active JIRA Projects
# Index Projects by key

projects = jira.Project.all

projects_i_key = projects.index_by( &:key )

#===============================================================================



#===============================================================================
# Get LiquidPlanner projects that contain '/' in their external reference.

sync_items = workspace.projects( :all, 
                                 :filter=>[ 'external_reference contains /',
                                            'is_done is false' ] )

sync_items_i_project = sync_items.index_by { |item| 
  item.external_reference.split( '/' )[1]
}

#===============================================================================



#===============================================================================
# Create Missing Projects in LiquidPlanner for JIRA Projects

projects.each do |project|
  sync_items_i_project[ project.key ] ||=
    workspace.create_project( :name               => project.name,
                              :external_reference => "/#{project.key}")
end

sync_items = sync_items_i_project.values

#===============================================================================



#===============================================================================
# Prepare estimate rollup tables

estimate_rollups = {}

workspace.tasks( :all, :filter => [ 
                   'external_reference starts_with time:',
                   'is_done is false' 
                 ] ).inject( {} ) do |hash, task|
  _, project, person = task.external_reference.split( ':' )
  
  project = estimate_rollups[ project.to_i ] ||= {}
  project[ lp_members_i_id[ person.to_i ] ] = task

  hash
end

estimate_rollup = lambda { |project, person|
  project = project.id if project.is_a? LiquidPlanner::Resources::Project

  estimate_rollups[ project ] ||= {}
  estimate_rollups[ project ][ person ] ||= workspace.create_task(
    :name      => "Expected effort for #{ person.user_name }",
    :parent_id => project,
    :owner_id  => person.id,

    :external_reference => "time:#{project}:#{person.id}"
  )
}

#===============================================================================



#===============================================================================
# Lookup JIRA Issues for each matching project

sync_items.each do |item|
  project = item.external_reference.split( '/' )[1]

  matching_issues = jira.Issue.jql <<-JQL
    project = "#{ project }"
    AND resolution = "unresolved"
  JQL

  rollups = {} 

  matching_issues.each do |issue|
    assigned = issue.fields[ 'assignee' ]
    email    = assigned[ 'emailAddress' ] if assigned

    if email.blank?
      puts "WARNING issue is unassigned: #{issue.summary}"
      next
    end

    assigned_lp_user = lp_members_i_email[ email ]

    unless assigned_lp_user
      puts "WARNING: no LiquidPlanner user found for #{email}"
      next
    end

    estimate = estimate_rollup.call( item.id, assigned_lp_user )

    time = issue.fields[ 'timeestimate' ]
    if time
      rollups[ estimate ] ||= 0
      rollups[ estimate ] += time / 1.hour
    end
  end

  rollups.each do |task, rollup|
    unless task.low_effort_remaining == rollup
      task.create_estimate( :low  => rollup, :high => rollup )
    end
  end

end

#===============================================================================
