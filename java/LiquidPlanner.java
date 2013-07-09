// This is an example class which uses the LiquidPlanner API in Java
// You will need the Google Gson JSON library (available at http://code.google.com/p/google-gson/) in your classpath

import com.google.gson.*;
import com.google.gson.reflect.*;
import java.net.*;
import java.io.*;
import javax.net.ssl.*;
import java.util.HashMap;
import java.util.Map;
import java.util.ArrayList;

public class LiquidPlanner {

  private String base_uri = "https://app.liquidplanner.com/api";
  private String email;
  private String pass;
  private Integer workspace_id;
  private Gson gson;  
  private TypeToken returnType = new TypeToken<HashMap<String, Object>>() {};
  
  public LiquidPlanner(String username, String password) {
    this.email = username;
    this.pass = password;
    gson = new Gson();
    Authenticator.setDefault (new Authenticator() {
      protected PasswordAuthentication getPasswordAuthentication() {
        return new PasswordAuthentication (email, pass.toCharArray());
      }
    });
  }
   
  public int get_workspace_id() {
    return this.workspace_id;
  }
  
  public void set_workspace_id(int workspace_id) {
    this.workspace_id = workspace_id;
  }
  
  private ArrayList<HashMap> json_to_hashmap(String json) {
    JsonParser parser = new JsonParser();
    JsonArray array = parser.parse(json).getAsJsonArray();
    ArrayList<HashMap> list = new ArrayList<HashMap>();
    for (JsonElement element : array) {
       list.add((HashMap) gson.fromJson(element, returnType.getType()));
    }
    return list;
  }
   
  private ArrayList<HashMap> get(String url) {
    try{
     HttpsURLConnection connection = (HttpsURLConnection) new URL(this.base_uri + url).openConnection();
     connection.setRequestProperty("Content-Type", "application/json");
     BufferedReader br = new BufferedReader( new InputStreamReader(connection.getInputStream()));
     String line;
     StringBuilder sb = new StringBuilder();
     while ( (line = br.readLine()) != null) {
      sb.append(line);
     }
     return json_to_hashmap(sb.toString());
    } catch (MalformedURLException e) {
      System.out.println("Bad URL: " + base_uri + url);
    } catch (IOException e) {
      System.out.println(e.toString());
      System.out.println("IO error " + base_uri + url);
    }
    return null;
  }
   
  private String post(String url, String options) {
    try{
      HttpsURLConnection connection = (HttpsURLConnection) new URL(this.base_uri + url).openConnection();
      connection.setDoOutput(true);
      connection.setRequestProperty("Content-Type", "application/json");
      OutputStream out = connection.getOutputStream();
      out.write(options.getBytes());
      BufferedReader br = new BufferedReader( new InputStreamReader(connection.getInputStream()));
      String line;
      StringBuilder sb = new StringBuilder();
      while ( (line = br.readLine()) != null) {
       sb.append(line);
      }
      return sb.toString();
    } catch (MalformedURLException e) {
      System.out.println("Bad URL: " + base_uri + url);
    } catch (IOException e) {
      System.out.println(e.toString());
      System.out.println("IO error " + base_uri + url);
    }
    return null;
  }
  
  //gets account information about the current user
  public ArrayList<HashMap> account() {
    return get("/account");
  }
  
  //gets information about all workspaces of which the current user is a member
  public ArrayList<HashMap> workspaces() {
    return get("/workspaces");
  }
  
  //gets information about all projects in the current workspace
  public ArrayList<HashMap> projects() {
    return get("/workspaces/" + this.workspace_id.toString() + "/projects");
  }
  
  //gets informations about all tasks in the current workspace
  public ArrayList<HashMap> tasks() {
    return get("/workspaces/" + this.workspace_id.toString() + "/tasks");
  }
  
  //creates a task by POSTing data
  public String createTask(String task) {
    return post("/workspaces/" + this.workspace_id.toString() + "/tasks", "{\"task\": " + task + "}");
  }
}
