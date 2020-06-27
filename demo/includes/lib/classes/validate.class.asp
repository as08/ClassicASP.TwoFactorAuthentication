<%
	
	Class Validation
		
		Dim JsonParse
		Dim DataCookieArray
		Dim TokenStr
		Dim PasswordSalt
		Dim RecoveryPasswordSalt
		Dim Username_
		Dim Email_
		Dim Password_
		Dim RememberMe_
		Dim TOTP_
		
		Private Sub Class_Initialize()
		
			Set Aes = New AdvancedEncryptionStandard
			Set JSON = New JSONobject
			
			' An array of JSON fields to include in the Data cookie.
			
			DataCookieArray = Array(_
				"Username",_
				"Email",_
				"Password",_
				"PasswordSalt",_
				"RememberMe",_
				"2FAsecretKey",_
				"2FArecoveryPassword",_
				"2FArecoveryPasswordSalt",_
				"2FAenabled"_
			)
		
		End Sub
		
		Private Sub Class_Terminate()
								
			Set Aes = Nothing
			Set JSON = Nothing
			
		End Sub
		
		' OnLoadValidation() is called on every page load.
		' It ensures that the required cookies are present and sets them if not.
		
		Public Sub OnLoadValidation()
						
			' Check for / set a Token cookie.
			
			If Request.Cookies("Token") = Empty Then
				
				' No Token cookie, create one.
				
				TokenStr = Hash(RandomBytes(TokenLength),"Sha1")
				
				Session("Token") = TokenStr
				
				Call CreateCookies(_
					Array("Token"),_
					Array(TokenStr),_
					True _
				)
				
			ElseIf NOT Len(Request.Cookies("Token")) = TokenLength*2 OR NOT _
			IsAlphaNumeric(Request.Cookies("Token")) Then
				
				' Invalid Token cookie, create a new one.
				
				TokenStr = Hash(RandomBytes(TokenLength),"Sha1")
				
				Session("Token") = TokenStr
				
				Call CreateCookies(_
					Array("Token"),_
					Array(TokenStr),_
					True _
				)
			
			ElseIf NOT IsEmpty(Session("Token")) Then
			
				' Token session has a value, we don't need it at this point,
				' Delete it.
			
				Session.Contents.Remove("Token")
			
			End If
			
			' Check for / set the Data cookies.
			
			If IsEmpty(Session("DataCookieJson")) Then
						
				' No JSON data, check for a Data cookies.
						
				If NOT Request.Cookies("Data") = Empty Then
											
					' There's a Data cookie. Validate it.
							
					If Request.Cookies("DataToken") = Hash(Request.Cookies("Data") & AesSha256Secret,"Sha256") Then
				
						' Valid Data cookie.
				
						Session("DataCookieJson") = Aes.Decrypt(Request.Cookies("Data"))
						
						' Parse the DataCookieJson.
						
						Call ParseDataCookieJson()
												
					Else
					
						' Invalid cookies, create new ones.
											
						Call CreateNewDataCookies()
									
					End If
												
				Else
				
					' No Data cookies, create new ones.
				
					Call CreateNewDataCookies()
						
				End If
					
			End If
		
		End Sub
		
		' Create new Data cookies.
		
		Public Sub CreateNewDataCookies()
			
			' Create a JSON string using the fields in the DataCookieArray variable.
			' For each field, add a Null value.
			
			For i = 0 To uBound(DataCookieArray)
			
				JSON.Add DataCookieArray(i),Null
			
			Next
			
			Session("DataCookieJson") = JSON.Serialize()
			
			' Parse the DataCookieJson.
			
			Call ParseDataCookieJson()
			
			' Create the Data cookies.
			
			Call CreateCookies(_
				Array("Data","DataToken"),_
				Array(Aes.Encrypt(Session("DataCookieJson")),_
				Aes.sha256Token),_
				True _
			)
		
		End Sub
		
		Private Sub ParseDataCookieJson()
			
			' This should never happen, but just incase...
			
			If IsEmpty(Session("DataCookieJson")) Then
			
				Response.ContentType = "text/plain"
				Response.Write "Unable to initialize the require settings"
				Response.End()
			
			End If
			
			' Parse the Session("DataCookieJson") content.
		
			Set JsonParse = JSON.Parse(Session("DataCookieJson"))
				
				' Parse the data. Use the DataCookieArray variable to create session values
				' for each JSON field.
				
				For i = 0 To uBound(DataCookieArray)
													
					Session(DataCookieArray(i)) = JsonParse.Value(DataCookieArray(i))
				
				Next
				
				' If remember me is true, then log the user in.
				
				If Session("RememberMe") Then
				
					Session("LoggedIn") = True
					
					' Bypass any 2FA.
					
					Session.Contents.Remove("2FArequired")
					
				End If
								
			Set JsonParse = Nothing
		
		End Sub
		
		Public Sub ChangeDataCookieJson(ByVal jFields, ByVal jValues)
			
			If NOT IsEmpty(Session("DataCookieJson")) Then
				
				' Validate the array parameters.
				
				If NOT IsArray(jFields) OR NOT IsArray(jValues) Then Exit Sub
				
				If NOT uBound(jFields) = uBound(jValues) Then Exit Sub
			
				' First, parse the DataCookieJson Session.
				
				Set JsonParse = JSON.Parse(Session("DataCookieJson"))
				
					' Loop through the array values and change the JSON string
					
					For i = 0 To uBound(jFields)
					
						JsonParse.Change jFields(i),jValues(i)
						Session(jFields(i)) = jValues(i)
											
					Next
					
					' Serialize the changes and save the changed JSON string to the
					' DataCookieJson session.
					
					Session("DataCookieJson") = JsonParse.Serialize()
										
					' Update the Data cookies with the changed JSON.
					
					Call CreateCookies(_
						Array("Data","DataToken"),_
						Array(Aes.Encrypt(Session("DataCookieJson")),_
						Aes.sha256Token),_
						True _
					)
				
				Set JsonParse = Nothing
			
			End If
		
		End Sub
		
		Public Sub ValidTOTP(TOTP,FormType)
		
			If FormType = "2fa-test" Then
				
				' Only allow 2FA tests if the user is logged in
			
				If Session("2FArequired") OR NOT Session("LoggedIn") Then
					
					JSON.Add "error",True
					JSON.Add "description","You're not currently logged in. Please login to run 2FA tests"
					
					JSON.Write()
					Response.End()
				
				End If
				
			Else
				
				' Both 2FArequired and LoggedIn need to be true when verifying on the login page
				
				If NOT (Session("2FArequired") AND Session("LoggedIn")) Then
					
					JSON.Add "error",True
					JSON.Add "description","Something went wrong, please go back to the login page"
					
					JSON.Write()
					Response.End()
					
				End If
			
			End If
			
			If NOT Len(TOTP) = totpSize Then
				
				JSON.Add "error",True
				JSON.Add "description","Your 2FA code should be " & totpSize & " digits"
				
				JSON.Write()
				Response.End()
				
			ElseIf NOT isNumeric(TOTP) Then
				
				JSON.Add "error",True
				JSON.Add "description","Your 2FA code should consist of only numbers"
				
				JSON.Write()
				Response.End()
			
			Else
			
				' Go ahead and perform a validation
				
				Set TwoFA = Server.CreateObject("ClassicASP.TwoFactorAuthentication")
					
					TwoFA.SecretKeyLength(SecretKeyLength)
					TwoFA.HashMode(HashMode)
					TwoFA.totpSize(totpSize)
					
					If NOT TwoFA.Verify(Aes.Decrypt(Session("2FAsecretKey")),cStr(TOTP)) Then
											
						JSON.Add "error",True
						JSON.Add "description","Invalid 2FA code"
						
						JSON.Write()
						Response.End()
						
					Else
						
						If FormType = "2fa-test" Then
							
							' If testing, display a success message
														
							JSON.Add "success",True
							JSON.Add "description","Valid 2FA code!"
							
							JSON.Write()
							Response.End()
						
						Else
						
							' If logging in, remove the 2FArequired session and redirect to the account page
							
							Session.Contents.Remove("2FArequired")
							
							JSON.Add "error",False
							JSON.Add "redirect","/account/?newLogin=true"
							
							Session("2FAenabled") = True
							
							JSON.Write()
							Response.End()
																				
						End If
					
					End If
				
				Set TwoFA = Nothing
			
			End If

		End Sub
		
		Public Sub ValidUsername(Username)
		
			If Username = "" Then
				
				JSON.Add "error",True
				JSON.Add "description","Please enter a username"
				
				JSON.Write()
				Response.End()
									
			ElseIf Len(Username) < 3 Then
			
				JSON.Add "error",True
				JSON.Add "description","Your username must be at least 3 characters"
				
				JSON.Write()
				Response.End()
				
			ElseIf Len(Username) > 20 Then
			
				JSON.Add "error",True
				JSON.Add "description","Your username can't exceed 20 characters"
				
				JSON.Write()
				Response.End()
				
			ElseIf NOT IsAlphaNumeric(Username) Then
			
				JSON.Add "error",True
				JSON.Add "description","Your username can only contain letters and numbers"
				
				JSON.Write()
				Response.End()
				
			End If
		
		End Sub
		
		Public Sub ValidEmail(Email)
		
			If NOT ValidEmailSyntax(Email) Then

				JSON.Add "error",True
				JSON.Add "description","Please enter a valid email address"
				
				JSON.Write()
				Response.End()
					
			End If
		
		End Sub
		
		Public Sub ValidPassword(Password)
		
			If Password = "" Then

				JSON.Add "error",True
				JSON.Add "description","Please enter a password"
				
				JSON.Write()
				Response.End()
				
			ElseIf Len(Password) < 6 Then
			
				JSON.Add "error",True
				JSON.Add "description","Your password must be at least 6 characters"
				
				JSON.Write()
				Response.End()
				
			ElseIf Len(Password) > 50 Then
								
				JSON.Add "error",True
				JSON.Add "description","Your password can't exceed 50 characters"
				
				JSON.Write()
				Response.End()
				
			End If
		
		End Sub
		
		Public Function ValidLogin(Email,Password,RememberMe)
		
			ValidLogin = False ' Default
			
			' Exit and return false if Email or Password sessions are null.
			
			If IsNull(Session("Email")) OR _
			IsNull(Session("Password")) OR _ 
			IsNull(Session("PasswordSalt")) Then Exit Function
			
			If StrComp(Session("Email"),Email) = 0 AND _
			Hash(AesSha256Secret & Password & Session("PasswordSalt"),"Sha256") = Session("Password") Then
			
				' Email and Password match. Log the user in.
				
				Session("LoggedIn") = True
				
				ValidLogin = True
				
				' Require 2FA verification?
				
				If NOT IsNull(Session("2FAsecretKey")) Then Session("2FArequired") = True
				
				' Change the remember me option even if it hasn't changed.
				' This will also increase the experation date.
				
				Call ChangeDataCookieJson(Array("RememberMe"),Array(RememberMe))
				
				' Calling Class_Initialize() resets the JSON object.
				' This is important for confirming a successful login
				' without outputting login JSON.
				
				Call Class_Initialize() ' Reset everything
			
			End If
		
		End Function
		
		Public Sub Register(Username,Email,Password,RememberMe)
		
			' All parameters have been validated.
			
			' Generate a random password salt.
						
			PasswordSalt = RandomString(32)
						
			' Change the Data cookie data and log in.	
			
			' Use the AesSha256Secret constant as a pepper.		
			
			Call ChangeDataCookieJson(_
				DataCookieArray,_
				Array(_
					Username,_
					Email,_
					Hash(AesSha256Secret & Password & PasswordSalt,"Sha256"),_
					PasswordSalt,_
					RememberMe,_
					Null,_
					Null,_
					Null _
				)_
			)
			
			' Remove any 2FA session if set.
			
			If NOT IsEmpty(Session("2FArequired")) Then Session.Contents.Remove("2FArequired")
			If NOT IsEmpty(Session("2FAenabled")) Then Session.Contents.Remove("2FAenabled")
			
			' Log the user in.
			
			Session("LoggedIn") = True
			
			' Calling Class_Initialize() resets the JSON object.
			' This is important for confirming a successful registration
			' without outputting registration JSON.
			
			Call Class_Initialize()
		
		End Sub
	
	End Class

%>
