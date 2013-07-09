import java.util.List;
import java.util.HashMap;
import java.io.Console;

public class LiquidPlannerDemo {
  public static void main(String[] args) {  
  
    String email = null;
    Console console = System.console();
    
    System.out.print("Enter your e-mail address: ");
    email = console.readLine();
    System.out.print("Enter your password: ");
    char[] password = console.readPassword();
    LiquidPlanner LP = new LiquidPlanner(email, new String(password));
    LP.workspaces();
    System.out.println("Defaulting to your first workspace...");

    LP.set_workspace_id(((Double)LP.workspaces().get(0).get("id")).intValue());
    List<HashMap> projects = LP.projects();
    
    System.out.println("Here is a list of all your projects...");
    Integer project_id = ((Double)projects.get(0).get("id")).intValue();
    for (HashMap project : projects) {
      System.out.println(project.get("name"));
    }
    System.out.println("Adding a task...");
    LP.createTask("{\"name\":\"learn the API\",\"parent_id\":" + project_id.toString() + "}");
		
    System.out.println("Here is a list of all your tasks: ");
    List<HashMap> tasks = LP.tasks();
    
    for (HashMap<String, Object> task : tasks) {
      System.out.println(task.get("name"));
    }

  }
}
