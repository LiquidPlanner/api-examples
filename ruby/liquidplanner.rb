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

  def workspaces
    get('/workspaces')
  end

  def projects
    get("/workspaces/#{workspace_id}/projects")
  end

  def tasks
    get("/workspaces/#{workspace_id}/tasks")
  end

  def create_task(data)
    options = { :body => { :task => data } }
    post("/workspaces/#{workspace_id}/tasks", :body => { :task => data })
  end

  def update_task(data)
    options = { :body => { :task => data } }
    put("/workspaces/#{workspace_id}/tasks/#{data['id']}", :body => { :task => data })
  end

  def self.demo
    email    = ask("LiquidPlanner email: ")
    password = ask("LiquidPlanner password for #{email}: ") {|q| q.echo = false}

    lp = LiquidPlanner.new(email, password)

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

end

if $0 == __FILE__
  require 'highline/import'
  LiquidPlanner.demo
end

