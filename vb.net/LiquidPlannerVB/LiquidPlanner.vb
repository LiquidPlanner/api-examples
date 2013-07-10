Imports System.Net          ' provides WebRequest et al
Imports Newtonsoft.Json
Imports System.Text         ' provides Encoding
Imports System.IO           ' provides Stream


' LiquidPlanner
'
' Uses the JSON.net library
' available at: http://json.codeplex.com/releases/view/89222

Module LiquidPlanner

    Class LpResponse
        Property response As String
        Property anError As Exception
    End Class

    Class LpObject
        Property id As Integer
    End Class

    Class Member
        Inherits LpObject

        Property name As String
        Property first_name As String
        Property last_name As String

        Overrides Function ToString() As String
            Return "User: " & id & "> " & name & "> " & first_name & " " & last_name
        End Function
    End Class

    Class Workspace
        Inherits LpObject

        Property name As String

        Public Overrides Function ToString() As String
            Return "Space: " & id & "> " & name
        End Function
    End Class

    Class Item
        Inherits LpObject

        Property name As String
        Property type As String
        Property owner_id As Integer
        Property parent_id As Integer

        Public Overrides Function ToString() As String
            Return "Item: " & id & "(" & type & ")> " & name
        End Function
    End Class

    ' api connection class
    Class LiquidPlanner
        Private _password As String

        Property Username As String
        WriteOnly Property Password As String
            Set(ByVal value As String)
                _password = Value
            End Set
        End Property
        Property WorkspaceId As Integer

        Public Sub New(ByVal theUsername As String, ByVal thePassword As String)
            Username = theUsername
            Password = thePassword
        End Sub

        Private Function request(ByVal verb As String, ByVal url As String, ByRef data As Object) As LpResponse
            Dim theRequest As HttpWebRequest
            Dim response As WebResponse
            Dim uri As String
            Dim lp_response As LpResponse

            uri = "https://app.liquidplanner.com/api" & url

            theRequest = WebRequest.Create(uri)
            theRequest.AutomaticDecompression = DecompressionMethods.Deflate Or DecompressionMethods.GZip
            theRequest.Credentials = CredentialCache.DefaultCredentials
            theRequest.Method = verb
            theRequest.Headers.Set("Authorization", Convert.ToBase64String(Encoding.ASCII.GetBytes(Username + ":" + _password)))

            If Not IsNothing(data) Then
                theRequest.ContentType = "application/json"
                Dim jsonPayload As String = JsonConvert.SerializeObject(data)
                Dim jsonPayloadByteArray = Encoding.ASCII.GetBytes(jsonPayload.ToCharArray)
                theRequest.GetRequestStream.Write(jsonPayloadByteArray, 0, jsonPayloadByteArray.Length)
            End If

            lp_response = New LpResponse()
            Try
                response = theRequest.GetResponse
                Dim reader As StreamReader = New StreamReader(response.GetResponseStream)
                lp_response.response = reader.ReadToEnd
            Catch ex As Exception
                lp_response.anError = ex
            End Try

            Return lp_response
        End Function

        Public Function DoGet(ByVal url As String) As LpResponse
            Return request("GET", url, Nothing)
        End Function
        Public Function DoPost(ByVal url As String, ByRef data As Object)
            Return request("POST", url, data)
        End Function
        Public Function DoPut(ByVal url As String, ByRef data As Object)
            Return request("PUT", url, data)
        End Function

        Public Function GetObject(Of t)(ByRef response As LpResponse) As t
            If Not IsNothing(response.anError) Then
                Throw response.anError
            End If
            Return JsonConvert.DeserializeObject(Of t)(response.response)
        End Function

        Public Function GetAccount() As Member
            Return GetObject(Of Member)(DoGet("/account"))
        End Function
        Public Function GetWorkspaces() As List(Of Workspace)
            Return GetObject(Of List(Of Workspace))(DoGet("/workspaces"))
        End Function
        Public Function GetProjects() As List(Of Item)
            Return GetObject(Of List(Of Item))(DoGet("/workspaces/" & WorkspaceId & "/projects"))
        End Function
        Public Function GetTasks() As List(Of Item)
            Return GetObject(Of List(Of Item))(DoGet("/workspaces/" & WorkspaceId & "/tasks"))
        End Function

        Public Function CreateTask(ByRef data As LpObject) As Item
            Return GetObject(Of Item)(DoPost("/workspaces/" & WorkspaceId & "/tasks", New With {Key .task = data}))
        End Function

        Public Function UpdateTask(ByRef data As LpObject) As Item
            Return GetObject(Of Item)(DoPut("/workspaces/" & WorkspaceId & "/tasks/" & data.id, New With {Key .task = data}))
        End Function

    End Class


    Sub Main()
        Dim liquidplanner As LiquidPlanner
        Dim username As String
        Dim password As String
        Dim args() As String = System.Environment.GetCommandLineArgs()

        If args.Count < 2 Then
            Console.Write("Enter email adress: ")
            username = Console.ReadLine
            Console.Write("Enter password: ")
            password = Console.ReadLine
        Else
            username = args(1)
            password = args(2)
        End If

        liquidplanner = New LiquidPlanner(username, password)

        Dim myAccount As Member = liquidplanner.GetAccount
        Console.WriteLine(myAccount.ToString)

        Dim spaces As List(Of Workspace) = liquidplanner.GetWorkspaces
        For Each space As Workspace In spaces
            Console.WriteLine(space.ToString)
        Next

        liquidplanner.WorkspaceId = spaces.Item(0).id
        Dim firstSpaceProjects As List(Of Item) = liquidplanner.GetProjects
        For Each project As Item In firstSpaceProjects
            Console.WriteLine(project.ToString)
        Next

        'create a new - unassigned task -in teh first project of the first space.
        Dim aTask As Item = liquidplanner.CreateTask(New Item With {
                                                     .name = "test",
                                                     .parent_id = firstSpaceProjects.Item(0).id
                                                 })

        'now assign the task to you
        aTask.owner_id = myAccount.id
        aTask = liquidplanner.UpdateTask(aTask)
    End Sub

End Module