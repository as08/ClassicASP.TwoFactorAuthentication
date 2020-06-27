<%@ Language = "VBScript" %>
<%

	Option Explicit
	
	'******************'
	' General settings '
	'******************'
	
	Server.ScriptTimeout = 20 ' seconds
	Session.Timeout = 60 ' minutes
	Response.CodePage = 65001
	Response.LCID = 2057
	Response.Charset = "UTF-8"
	
	'******************'
	' Global variables '
	'******************'
	
	Dim JSON, Aes, TwoFA, Test2FA, Validate, Item, i
	
	'*****************************************************************************'
	' Run OnLoadValidation() to ensure the necessary cookies and sessions are set '
	'*****************************************************************************'
	
	Set Validate = New Validation
	
		Call Validate.OnLoadValidation()
	
	Set Validate = Nothing
	
	'*******************************************************************************'
	' 2FA settings                                                                  '
	'*******************************************************************************'
	' * sha1, sha256 and sha512 all work with Google Authenticator, but most other  '
	' 2FA apps use sha1 by default, and will generate invalid totp codes if you use '
	' anthing other than sha1.                                                      '
	'                                                                               '
	' ** Not all 2FA apps support more than 6 digits. It's recommended that you use '
	' a 6 digit totp code with sha1.                                                '
	'*******************************************************************************'

	Const SecretKeyLength = 20 ' bytes
	Const HashMode = "sha1" ' sha1, sha256, sha512 *
	Const totpSize = 6 ' digits, between 6 and 8 **
	Const QRpixels = 320 ' should be a multiple of 64: 64, 128, ‭192‬, ‭256‬, 320, 384 etc..
	Const Issuer = "2fa.as08.co.uk" ' your website url (no protocol or slashes)
	Const RecoveryPasswordLength = 18 ' characters
	
	'***********************************************************************************'
	' AES keys                                                                          '
	'***********************************************************************************'
	' 256 bit keys, generate custom (non-hex) keys from:                                '
	' https://www.allkeysgenerator.com/Random/Security-Encryption-Key-Generator.aspx    '
	'                                                                                   '
	' As this is a demo site, no data is stored in a database. Instead, data is stored  '
	' in a 256 bit AES encrypted cookie called "Data". The data content is formatted as '
	' JSON before being encrypted and encoded with base64.                              '
	'                                                                                   '
	' The encrypted data is verified by a cookie called "DataToken". This cookie is a   '
	' sha256 hash and is generated using the following formula:                         '
	'                                                                                   '
	' 	> DataToken = Sha256((Encrypted & Encoded Data content) + SecretKey)            '
	'                                                                                   '
	' The encrypted Data cookie will only be decrypted and parsed if the DataToken can  '
	' be validated. The validation check is performed by simply taking the Data cookie  '
	' content, and generating the expected DataToken hash re-using the above formula.   '
	' If the expected DataToken hash matches the actual DataToken hash, then we can be  '
	' sure the Data cookie is valid, and go a head and decrypt the JSON and parse it.   '
	' If the validation fails then the Data cookie is reset with null values. This is   '
	' basically the same as a demo reset.                                               '
	'                                                                                   '
	' NOTE: The keys below are just example keys, they're not the keys used on the live '
	' demo site, and you SHOULD replace them with your own.                             ' 
	'***********************************************************************************'

	Const AesEncryptionKey = "TjWnZq4t7w!z%C*F-JaNdRgUkXp2s5u8"
	Const AesMacKey = "bQeThWmZq3t6w9z$C&F)J@NcRfUjXn2r"
	Const AesSha256Secret = "G+KbPeShVmYq3s6v9y$B&E)H@McQfTjW"
	
	'****************'
	' Misc constants '
	'****************'
	
	Const TokenLength = 20 ' bytes
	Const CookieExperationDays = 90 ' how many days to store cookies
	Const PasswordSaltLength = 32 ' characters
	
	'************************'
	' Handle logout requests '
	'************************'
	
	' The user must be logged in and provide a valid token.
	
	If Request.QueryString("do") = "logout" AND _
	Session("LoggedIn") AND ValidToken(Request.QueryString("token")) Then
		
		' Remove the LoggedIn session status.
		
		Session.Contents.Remove("LoggedIn")
		
		' Remove 2FA sessions. But leave them in the Data cookie.
		
		Session.Contents.Remove("2FArequired")
		Session.Contents.Remove("2FAenabled")
		
		' RememberMe is removed if you logout.
		
		Set Validate = New Validation
		
			Call Validate.ChangeDataCookieJson(_
				Array("RememberMe"),_
				Array(Null)_
			)
		
		Set Validate = Nothing
				
		' Redirect to the homepage.
		
		Response.Redirect "/"
		
	End If
	
	'****************************'
	' Handle demo reset requests '
	'****************************'
	
	If Request.QueryString("do") = "reset" AND NOT _
	IsNull(Session("Username")) AND ValidToken(Request.QueryString("token")) Then
		
		' Display the reset link if the DataCookieJson session is populated.
		' A username value is mandatory, if it's set then the user has created
		' an account. If not, then the DataCookieJson sessions are null. 
		' So performing a reset won't make any difference.
		
		' Delete all cookies.
		
		Call DeleteCookies()
		
		' Abandon the session. This will remove all session values including
		' the DataCookieJson session, which will be reset after the redirect.
		
		Session.Abandon()
		
		' Redirect to the homepage.
		
		Response.Redirect "/"
				
	End If
	
	'***************************'
	' Handle "DisplayVariables" '
	'***************************'
	
	' The user must be logged in and provide a valid token.
	
	If Request.QueryString("do") = "DisplayVariables" AND _
	Session("LoggedIn") AND ValidToken(Request.QueryString("token")) Then
				
		Dim VariablesTbl
		
		VariablesTbl = "		<table class=""table table-hover table-secondary"">" & VBlf
		
		' Sessions header.
		
		VariablesTbl = VariablesTbl &_
		"		    <tr>" & VBlf &_
		"		      <th class=""bg-dark text-light h4"">Session values</th>" & VBlf &_
		"		    </tr>" & VBlf
						
		' Loop through each session value.
		
		For Each Item In Session.Contents
			
			' Ignore the DataCookieJson session and any session with a "tmp_" prefix.
				
			If NOT Item = "DataCookieJson" AND NOT InStr(Item,"tmp_") = 1 Then
				
				' If a session is null, no value will be returned.
				' Check for null sessions and output "Null" as the value.
				
				If IsNull(Session.Contents(Item)) Then
					
					VariablesTbl = VariablesTbl &_
					"		    <tr>" & VBlf &_
					"		      <td>Session(""" & Item & """)<br><strong>Null</strong></td>" & VBlf &_
					"		    </tr>" & VBlf
						
				Else
				
					VariablesTbl = VariablesTbl &_
					"		    <tr>" & VBlf &_
					"		      <td>Session(""" & Item & """)<br><strong>" & Server.HTMLEncode(Session.Contents(Item)) & "</strong></td>" & VBlf &_
					"		    </tr>" & VBlf
									
				End If
				
			End If
						
		Next
		
		' Cookies header.
		
		VariablesTbl = VariablesTbl &_
		"		    <tr>" & VBlf &_
		"		      <th class=""bg-dark text-light h4"">Cookie values</th>" & VBlf &_
		"		    </tr>" & VBlf
				
		' Loop through each cookie value.
		
		For Each Item In Request.Cookies
			
			' Ignore cookies names that start with an underscore.
			
			If NOT InStr(Item,"_") = 1 Then
		
				VariablesTbl = VariablesTbl &_
				"		    <tr>" & VBlf &_
				"		      <td>Request.Cookies(""" & Item & """)<br><strong>" & Server.HTMLEncode(Request.Cookies(Item)) & "</strong></td>" & VBlf &_
				"		    </tr>" & VBlf
							
			End If
			
		Next
		
		VariablesTbl = VariablesTbl &_
		"		</table>"
	
	End If
	
	'********************'
	' Handle 2FA disable '
	'********************'
	
	' The user must be logged in, NOT have 2FA required (this means they've passed the
	' Email/Password verification, but haven't entered a valid TOTP yet) and provide a 
	' valid token.
	
	If Request.QueryString("do") = "disable-2fa" AND _
	Session("LoggedIn") AND NOT _
	Session("2FArequired") AND ValidToken(Request.QueryString("token")) Then
		
		Set Validate = New Validation
			
			' Remove all 2FA sessions.
			
			Session.Contents.Remove("2FArequired")
			Session.Contents.Remove("2FAenabled")
			
			' Remove the 2FA data from the Data cookie so it isn't re-parsed.
			
			Call Validate.ChangeDataCookieJson(_
				Array("2FAsecretKey","2FArecoveryPassword","2FArecoveryPasswordSalt","2FAenabled"),_
				Array(Null,Null,Null,False)_
			)
			
			' Redirect to the account page (the user is still logged in).
			
			Response.Redirect "/account/"
		
		Set Validate = Nothing
		
	End If

%>
<!--#include file = "lib/classes/json.class.asp" -->
<!--#include file = "lib/classes/aes.class.asp" -->
<!--#include file = "lib/classes/validate.class.asp" -->
<!--#include file = "lib/functions.asp" -->
