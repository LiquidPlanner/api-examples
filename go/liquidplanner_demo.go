package main

import (
  "bufio"
  "fmt"
  "os"
  "strings"

  "code.google.com/p/gopass"

  lp "github.com/liquidplanner/liquidplanner_go"
)

func main() {
  promptForEmailAndPassword();

//------------------------------------------------------------------------------
//-- Fetch your account
//------------------------------------------------------------------------------

  person, response := lp.GetAccount()

  if response.Error != nil {
    fmt.Println( "There was an error. Check your email and password?" );
    os.Exit(1);
  }

  fmt.Println( "Account:" )
  fmt.Println( "\t" + person.FullName() )

//------------------------------------------------------------------------------
//-- List your workspaces
//------------------------------------------------------------------------------

  workspaces := person.Workspaces

  fmt.Println( "\nWorkspaces:" )

  for _,space := range workspaces {
    fmt.Println( "\t" + space.Name )
  }

//------------------------------------------------------------------------------
//-- Select the first space
//------------------------------------------------------------------------------

  workspace := workspaces[len(workspaces)-1]

  lp.SetSpace( workspace )

//------------------------------------------------------------------------------
//-- List Projects 
//------------------------------------------------------------------------------

  projects := lp.GetProjects()

  fmt.Println( "\n" + workspace.Name + " projects:" )

  for _,project := range projects {
    fmt.Println( "\t" + project.Name )
  }

//------------------------------------------------------------------------------
//-- Create a task
//------------------------------------------------------------------------------

  fmt.Println( "\n-- Create a Task")

  task := lp.CreateTask(lp.Task {
    Name: "Learn the API", 
  })

  fmt.Println( "\n" + workspace.Name + " tasks:" )

  for _,task := range lp.GetTasks() {
    fmt.Println( "\t" + task.Name )
  }

//------------------------------------------------------------------------------
//-- Update the task
//------------------------------------------------------------------------------

  fmt.Println( "\n-- Update the Task")

  task.Name = "update with the API"

  lp.UpdateTask(&task)

  fmt.Println( "\n" + workspace.Name + " tasks:" )

  for _,task := range lp.GetTasks() {
    fmt.Println( "\t" + task.Name )
  }

//------------------------------------------------------------------------------
//-- Delete task
//------------------------------------------------------------------------------

  fmt.Println( "\n-- Delete the Task")

  lp.DeleteTask( &task )

  fmt.Println( "\n" + workspace.Name + " tasks:" )

  for _,task := range lp.GetTasks() {
    fmt.Println( "\t" + task.Name )
  }

//------------------------------------------------------------------------------
//-- That's all folks!
//------------------------------------------------------------------------------

}





func promptForEmailAndPassword() {
  reader := bufio.NewReader(os.Stdin)

  // get username and password
  fmt.Print( "Enter email: " )
  user,_ := reader.ReadString('\n')

  pass,_ := gopass.GetPass("Enter Password: ")

  user = strings.TrimSuffix(user, "\n")
  pass = strings.TrimSuffix(pass, "\n")

  lp.Login(user,pass)
}
