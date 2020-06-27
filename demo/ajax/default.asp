<!--#include file = "../includes/config.asp" -->
<%
	
	Response.ContentType = "application/json"
	
	If Request.Form <> "" Then
	
		If ValidToken(Request.Form("Token")) Then
	
			Set Validate = New Validation
			
				Dim Username, Email, Password, RecoveryPassword, RememberMe, TOTP
			
				If Request.Form("form-type") = "register" Then
					
					Username = Trim(Request.Form("username"))
					Email = Trim(Request.Form("email"))
					Password = Request.Form("password")
					RememberMe = Request.Form("remember")
					
					If RememberMe = "on" Then RememberMe = True Else RememberMe = False
					
					Call Validate.ValidUsername(Username)
					Call Validate.ValidEmail(Email)
					Call Validate.ValidPassword(Password)
					
					Call Validate.Register(Username,Email,Password,RememberMe)
					
					JSON.Add "error",False
					JSON.Add "redirect","/account/"
					
					' Output the redirect JSON.
					
					JSON.Write()
					Response.End()
									
				ElseIf Request.Form("form-type") = "login" Then
				
					Email = Trim(Request.Form("email"))
					Password = Trim(Request.Form("password"))
					RememberMe = Request.Form("remember")
					
					If RememberMe = "on" Then RememberMe = True Else RememberMe = False
					
					Call Validate.ValidEmail(Email)
					Call Validate.ValidPassword(Password)
					
					If Validate.ValidLogin(Email,Password,RememberMe) Then
						
						JSON.Add "error",False
						
						If Session("2FArequired") Then
						
							JSON.Add "redirect","2FA/"
							
						Else
						
							JSON.Add "redirect","/account/"
						
						End If
						
						' Output the JSON before calling ChangeDataCookieJson().
						' ChangeDataCookieJson() will generate a new JSON string,
						' and we don't want to output that.
						
						JSON.Write()
												
						Response.End()
					
					Else
					
						JSON.Add "error",True
						JSON.Add "description","Invalid login credentials"
						
						JSON.Write()
						Response.End()
					
					End If
				
				ElseIf Request.Form("form-type") = "2fa" OR Request.Form("form-type") = "2fa-test" Then
					
					TOTP = Trim(Request.Form("totp"))
					TOTP = Replace(TOTP," ","")
					
					Call Validate.ValidTOTP(TOTP,Request.Form("form-type"))
																						
				ElseIf Request.Form("form-type") = "recover" Then
										
					RecoveryPassword = Request.Form("RecoveryPassword")
					
					' RecoveryPassword session has already been set by this point,
					' all we need to is validate the length and compare the form
					' value to the RecoveryPassword session value
					
					If NOT (Len(RecoveryPassword) = RecoveryPasswordLength AND _
					Hash(AesSha256Secret &_ 
					RecoveryPassword &_ 
					Session("2FArecoveryPasswordSalt"),_
					"Sha256") = Session("2FArecoveryPassword")) Then
												
						JSON.Add "error",True
						JSON.Add "description","Invalid recovery password"
						
						JSON.Write()
						Response.End()
						
					Else
						
						' Remove the 2FArequired session and remove the 2FA data from the DataCookieJson.
						
						Session.Contents.Remove("2FArequired")
						Session.Contents.Remove("2FAenabled")
						
						Call Validate.ChangeDataCookieJson(_
							Array("2FAsecretKey",_
							"2FArecoveryPassword",_
							"2FArecoveryPasswordSalt"),_
							Array(Null,Null,Null)_
						)
						
						' Recovery password match. Log the user in.
				
						Session("LoggedIn") = True
						
						' Redirect to the account page
						
						JSON.Add "error",False
						JSON.Add "redirect","/account/?recovered=true"
						
						JSON.Write()
						Response.End()
											
					End If
					
				End If
			
			Set Validate = Nothing
			
		End If
		
	Else
		
		Response.Redirect "/"
	
	End If
	
%>