import java.util.ArrayList;
import java.util.List;
import java.util.HashMap;
import java.util.Map;
import java.io.Console;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

public class MultipleOwners extends LiquidPlanner {

  public Map<Integer,Map> memberLookup,
                          teamLookup;

  public MultipleOwners( String user, String pass ) { super( user, pass ); } 

  public ArrayList<HashMap> getTwoItems( String type ) {
    return get( "/workspaces/" + this.get_workspace_id() + 
                "/" + type + "?limit=2" );
  }

  public Map help() {
    return getObject( "/help.json" );
  }

  public Map update_assignment( Integer ti_id, Map data ) {
    Gson gson = new GsonBuilder().create();

    return (Map)json_to_object( post( "/workspaces/" + this.get_workspace_id() + 
                                   "/treeitems/" + ti_id + "/update_assignment", 
                                   gson.toJson( data ) ) );
  }

  public Map workspace_members() {
    HashMap ret = new HashMap();
    for( HashMap member : members() ) {
      ret.put( member.get( "id" ), member );
    }
    return ret;
  }

  public Map workspace_teams() {
    HashMap ret = new HashMap();
    for( HashMap team : teams() ) {
      ret.put( team.get( "id" ), team );
    }
    return ret;
  }

  public ArrayList<Map> assignmentsFor( Map item ) {
    return (ArrayList<Map>)item.get( "assignments" );
  }

  public Map ownerFor( Map assignment ) {
    if ( assignment.containsKey( "person_id" ) ) { 
      return this.memberLookup.get( assignment.get( "person_id" ) );
    } 
    return this.teamLookup.get( assignment.get( "team_id" ) );
  }

  public ArrayList<Map> ownersFor( Map item ) {
    ArrayList<Map> assignments = assignmentsFor( item );
    ArrayList<Map> ret = new ArrayList<Map>();

    for ( Map assignment : assignments ) {
      ret.add( this.ownerFor( assignment ) );
    }

    return ret;
  }

  public String nameFor( Map owner ) {
    if ( owner.get( "type" ).equals( "Member" ) ) {
      return (String)owner.get( "user_name" );
    } else { 
      return (String)owner.get( "name" );
    }
  }

  public Map<String,Integer> reassignAssignment( Map assignment, Integer newOwner ) {
    Map<String,Integer> update = new HashMap<String,Integer>();

    update.put( "assignment_id", newOwner );
    if ( assignment.containsKey( "person_id" ) ) {
      update.put( "person_id",
                  ((Double)assignment.get( "person_id" )).intValue() );
    }
    if ( assignment.containsKey( "team_id" ) ) {
      update.put( "team_id",
                  ((Double)assignment.get( "team_id" )).intValue() );
    }

    return update;
  }

  public Map eventOwners( Map event ) {
    List<Integer> personIds       = new ArrayList<Integer>();
    List<Integer> teamIds         = new ArrayList<Integer>();
    Map<String,List<Integer>> ret = new HashMap<String,List<Integer>>();

    ArrayList<Map>owners = this.ownersFor( event );
    for( Map owner : owners ) {
      if ( owner.get( "type" ).equals( "Member" ) ) {
        personIds.add( ((Double)owner.get( "id" )).intValue() );
      } else {
        teamIds.add( ((Double)owner.get( "id" )).intValue() );
      }
    }

    ret.put( "person_ids", personIds );
    ret.put( "team_ids", teamIds );
    return ret;
  }

  public void inspectOwnership( Map item ) {
    
    String id        = item.get( "id" ).toString();
    String name      = item.get( "name" ).toString();
    ArrayList owners = new ArrayList();

    for ( Map owner : ownersFor( item ) ) {
      owners.add( nameFor( owner ) );
    }

    System.out.printf( "%10s %-15s %s %n", id, name, owners.toString() );
  }

  public static void main(String[] args) {  
  
    String email = null;
    Console console = System.console();
    
    System.out.print("Enter your e-mail address: ");
    email = console.readLine();
    System.out.print("Enter your password: ");
    char[] password = console.readPassword();

    MultipleOwners LP = new MultipleOwners( email, new String( password ) );

    Map help = LP.help();
    if ( !help.containsKey( "Task" ) || 
         !((Map)help.get( "Task" )).containsKey( "assignments" ) ) {
      System.out.println( "LiquidPlanner does not yet support multiple owners" );
      System.exit( 0 );;
    }

    LP.set_workspace_id(((Double)LP.workspaces().get(0).get("id")).intValue());

    LP.memberLookup = LP.workspace_members();
    LP.teamLookup   = LP.workspace_teams();

    ArrayList<HashMap> twoTasks  = LP.getTwoItems( "tasks" );
    ArrayList<HashMap> twoEvents = LP.getTwoItems( "events" );

    System.out.println( "Tasks: (before)" );
    for ( Map task : twoTasks ) {
      LP.inspectOwnership( task );
    }
    System.out.println( "Events: (before)" );
    for ( Map event : twoEvents ) {
      LP.inspectOwnership( event );
    }


    //swap task owners

    Map assignment_1 = LP.assignmentsFor( twoTasks.get( 0 ) ).get( 0 );
    Map assignment_2 = LP.assignmentsFor( twoTasks.get( 1 ) ).get( 0 );

    Map<String,Integer> update;
    
    update = LP.reassignAssignment( assignment_2,
                                    ((Double)assignment_1.get( "id" )).intValue() );

    twoTasks.set( 0, (HashMap)LP.update_assignment( ((Double)twoTasks.get( 0 ).get( "id" )).intValue(), update ) );

    update = LP.reassignAssignment( assignment_1,
                                    ((Double)assignment_2.get( "id" )).intValue() );

    twoTasks.set( 1, (HashMap)LP.update_assignment( ((Double)twoTasks.get( 1 ).get( "id" )).intValue(), update ) );


    //swap event owners

    assignment_1 = LP.eventOwners( twoEvents.get( 0 ) );
    assignment_2 = LP.eventOwners( twoEvents.get( 1 ) );

    twoEvents.set( 0, (HashMap)LP.update_assignment( ((Double)twoEvents.get( 0 ).get( "id" )).intValue(), assignment_2 ) );
    twoEvents.set( 1, (HashMap)LP.update_assignment( ((Double)twoEvents.get( 1 ).get( "id" )).intValue(), assignment_1 ) );
    

    System.out.println( "Tasks: (before)" );
    for ( Map task : twoTasks ) {
      LP.inspectOwnership( task );
    }
    System.out.println( "Events: (before)" );
    for ( Map event : twoEvents ) {
      LP.inspectOwnership( event );
    }

  }
}
