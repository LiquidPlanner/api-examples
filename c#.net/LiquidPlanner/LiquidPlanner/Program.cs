using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using System.IO;
using System.Net;
using Newtonsoft.Json;

/*
 * LiquidPlanner
 * 
 * Uses the JSON.net library
 * available at: http://json.codeplex.com/releases/view/89222
 * 
 */

namespace LiquidPlanner
{
    class LpResponse 
    {
        public String response { get; set; }
        public Exception error { get; set; }
    }

    class LpObject
    {
        public Int32 id { get; set; }
    }

    class Member : LpObject
    {
        public String name       { get; set; }
        public String first_name { get; set; }
        public String last_name  { get; set; }

        public override String ToString()
        {
            return "User: "+this.id + "> " + this.name + "> " + this.first_name + " " + this.last_name;
        }
    }

    class Workspace : LpObject
    {
        public String name { get; set; }
        
        public override String ToString()
        {
            return "Space: " + this.id + "> " + this.name;
        }
    }

    class Assignment : LpObject
    {
        public Int32? person_id { get; set; }
        public Int32? team_id   { get; set; }
    }

    class Item : LpObject
    {
        public String name      { get; set; }
        public String type      { get; set; }
        public Int32  parent_id { get; set; }

        public List<Assignment> assignments { get; set; }

        public override String ToString()
        {
            return "Item: " + this.id +"("+ this.type + ")> " + this.name;
        }
    }

    class LiquidPlanner
    {
        public  string  Hostname { get; set; }

        private String _password;

        public  String  Username    { get; set; }
        public  String  Password    { get { return null; } set { _password = value; } }
        public  Int32   WorkspaceId { get; set; }

        public LiquidPlanner(string username, string password)
        {
            this.Username = username;
            this.Password = password;
        }

        private LpResponse request(String verb, String url, Object data)
        {
            HttpWebRequest request;
            String      uri;
            LpResponse  lp_response;

            uri = "https://app.liquidplanner.com/api" + url;           

            request = WebRequest.Create(uri) as HttpWebRequest;
            request.Credentials = CredentialCache.DefaultCredentials;
            request.Method = verb;
            request.AutomaticDecompression = DecompressionMethods.GZip | DecompressionMethods.Deflate;
            request.Headers.Set("Authorization", Convert.ToBase64String(Encoding.ASCII.GetBytes(this.Username + ":" + this._password)));
            
            if (null != data) {
                request.ContentType = "application/json";
                String jsonPayload = JsonConvert.SerializeObject(data);
                Console.WriteLine(jsonPayload);
                byte[] jsonPayloadByteArray = Encoding.ASCII.GetBytes(jsonPayload.ToCharArray());
                request.GetRequestStream().Write(jsonPayloadByteArray, 0, jsonPayloadByteArray.Length);
            }


            lp_response = new LpResponse();
            try
            {
                using (WebResponse response = request.GetResponse()) 
                {
                  using (StreamReader reader = new StreamReader(response.GetResponseStream())) {
                    lp_response.response = reader.ReadToEnd();
                  }
                }
            }
            catch (Exception e)
            {
                lp_response.error = e;
            }
            return lp_response;
        }

        public LpResponse get(String url)
        {
            return request("GET", url, null);
        }
        public LpResponse post(String url, Object data)
        {
            return request("POST", url, data);
        }
        public LpResponse put(String url, Object data)
        {
            return request("PUT", url, data);
        }

        public t GetObject<t>(LpResponse response) {
            if (null != response.error)
                throw response.error;
            Console.WriteLine(response.response);
            return JsonConvert.DeserializeObject<t>(response.response);
        }

        public Member GetAccount()
        {
            return GetObject<Member>(get("/account"));
        }
        public List<Workspace> GetWorkspaces()
        {
            return GetObject<List<Workspace>>(get("/workspaces"));
        }
        public List<Item> GetProjects()
        {
            return GetObject<List<Item>>(get("/workspaces/" + this.WorkspaceId + "/projects"));
        }
        public List<Item> GetTasks()
        {
            return GetObject<List<Item>>(get("/workspaces/" + this.WorkspaceId + "/tasks"));
        }

        public Item CreateTask(LpObject data)
        {
            return GetObject<Item>(post("/workspaces/" + this.WorkspaceId + "/tasks", new
            {
                task = data
            }));
        }
        public Item UpdateTask(LpObject data)
        {
            return GetObject<Item>(put("/workspaces/" + this.WorkspaceId + "/tasks/" + data.id, new
            {
                task = data
            }));
        }
    }

    class CommandLineDemo
    {
        static void Main(string[] args)
        {
            String username, password;
            if (args.Length < 2)
            {
                Console.Write("Enter email address: ");
                username = Console.ReadLine();
                Console.Write("Enter password: ");
                password = Console.ReadLine();
            }
            else
            {
                username = args[0];
                password = args[1];
            }

            LiquidPlanner liquidplanner = new LiquidPlanner(username, password);
            
            Member myAccount = liquidplanner.GetAccount();
            Console.WriteLine(myAccount.ToString());

            List<Workspace> spaces = liquidplanner.GetWorkspaces();
            foreach (Workspace space in spaces)
            {
                Console.WriteLine(space.ToString());
            }

            liquidplanner.WorkspaceId = spaces[0].id;
            List<Item> firstSpaceTasks = liquidplanner.GetTasks();
            foreach (Item task in firstSpaceTasks)
            {
                Console.WriteLine(task.ToString());
            }

            List<Item> firstSpaceProjects = liquidplanner.GetProjects();
            foreach (Item task in firstSpaceProjects)
            {
                Console.WriteLine(task.ToString());
            }

            // Create a new - unassigned task -in the first project of the first space.
            Item aTask = liquidplanner.CreateTask(new Item()
            {
                name = "My new Task Name",
                parent_id = firstSpaceProjects[0].id,
                assignments = new List<Assignment>()
                {
                    new Assignment() { person_id = myAccount.id }
                }
            });

        }
    }
}
