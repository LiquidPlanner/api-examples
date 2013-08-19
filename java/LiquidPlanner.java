// This is an example class which uses the LiquidPlanner API in Java
// You will need the Google Gson JSON library (available at http://code.google.com/p/google-gson/) in your classpath

import com.google.gson.*;
import com.google.gson.reflect.*;
import java.net.*;
import java.io.*;
import javax.net.ssl.*;
import java.util.HashMap;
import java.util.ArrayList;
import java.util.regex.Pattern;
import java.util.zip.GZIPInputStream;

@SuppressWarnings("rawtypes")
public class LiquidPlanner {
	
  private static final int POST = 1;
  private static final int PUT = 2;

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
  
  private ArrayList<HashMap> json_to_hashmap(String json, boolean isArray) {
    JsonParser parser = new JsonParser();
    JsonArray array;
    if(isArray) {
    	array = parser.parse(json).getAsJsonArray();
    }
    else {
    	String newString = "[" + json + "]";
    	array = parser.parse(newString).getAsJsonArray();
    }
    ArrayList<HashMap> list = new ArrayList<HashMap>();
    for (JsonElement element : array) {
       list.add((HashMap) gson.fromJson(element, returnType.getType()));
    }
    return list;
  }
   
  private ArrayList<HashMap> get(String url, boolean isArray) {
    try{
     HttpsURLConnection connection = (HttpsURLConnection) new URL(this.base_uri + url).openConnection();
     connection.setRequestProperty("Content-Type", "application/json");
     BufferedReader br = new BufferedReader( new InputStreamReader(connection.getInputStream()));
     String line;
     StringBuilder sb = new StringBuilder();
     while ( (line = br.readLine()) != null) {
      sb.append(line);
     }
     return json_to_hashmap(sb.toString(), isArray);
    } catch (MalformedURLException e) {
      System.out.println("Bad URL: " + base_uri + url);
    } catch (IOException e) {
      System.out.println(e.toString());
      System.out.println("IO error " + base_uri + url);
    }
    return null;
  }
   
  private String sendData(String url, String options, int sendMethod) {
    try{
      HttpsURLConnection connection = (HttpsURLConnection) new URL(this.base_uri + url).openConnection();
      connection.setDoOutput(true);
      connection.setRequestProperty("Content-Type", "application/json");
      if(sendMethod == POST) {
    	connection.setRequestMethod("POST");
      }
      else if(sendMethod == PUT) {
    	connection.setRequestMethod("PUT");  
      }
      OutputStream out = connection.getOutputStream();
      out.write(options.getBytes());
      String encoding = connection.getHeaderField("Content-Encoding");
      boolean isGzip = false;
      if(encoding != null)
    	  isGzip = Pattern.matches("gzip", encoding);
      InputStream inputStream = connection.getInputStream();
      if (isGzip) {
        inputStream = new GZIPInputStream( inputStream );
      }
      BufferedReader br = new BufferedReader( new InputStreamReader( inputStream ) );
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
  
  public ArrayList<HashMap> account() {
    return get("/account", true);
  }
  
  public ArrayList<HashMap> workspaces() {
    return get("/workspaces", true);
  }
  
  public ArrayList<HashMap> projects() {
    return get("/workspaces/" + this.workspace_id.toString() + "/projects", true);
  }
  
  public ArrayList<HashMap> tasks() {
    return get("/workspaces/" + this.workspace_id.toString() + "/tasks", true);
  }
  
  public ArrayList<HashMap> comments() {
	  return get("/workspaces/" + this.workspace_id.toString() + "/comments", true);
  }
  
  public Boolean isTaskDone(int taskID) {
	  HashMap theTask = get("/workspaces/" + this.workspace_id.toString() + "/tasks/" + taskID, false).get(0);
	  return (Boolean) theTask.get("is_done");
  }
  
  public ArrayList<HashMap> commentsForTask(int taskID) {
	  return get("/workspaces/" + this.workspace_id.toString() + "/tasks/" + taskID + "/comments", true);
  }

  public String createTask(String task) {
	  return sendData("/workspaces/" + this.workspace_id.toString() + "/tasks", "{\"task\": " + task + "}", POST);
  }

  public String createComment(int itemID, String comment) {
	  return sendData("/workspaces/" + this.workspace_id.toString() + "/tasks/" + itemID + "/comments", "{\"comment\": " + comment + "}", this.POST);
  }

  public String updateTask(String task, int taskID) {
	  return sendData("/workspaces/" + this.workspace_id.toString() + "/tasks/" + taskID, "{\"task\": " + task + "}", PUT);
  }
}
