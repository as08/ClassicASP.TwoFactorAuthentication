<%
	
	' Create cookies.
	
	Sub CreateCookies(ByVal NameArray, ByVal DataArray, HttpOnly)
		
		Dim CookieStr, CookieExpires
		
		' Validate the array parameters.
		
		If NOT IsArray(NameArray) OR NOT IsArray(DataArray) Then Exit Sub
		
		If NOT uBound(NameArray) = uBound(DataArray) Then Exit Sub
		
		' Set the cookie expiration date using the default constant value.
				
		CookieExpires = CookieExperationDate(CookieExperationDays)
		
		' If HttpOnly is true...
		
		If HttpOnly Then CookieStr = "HttpOnly; "
		
		' If the https protocol is being used, set the cookie as secure.
		
		If uCase(Request.ServerVariables("HTTPS")) = "ON" Then
			
			CookieStr = CookieStr & "SameSite=Strict; Secure; "
			
		End If
		
		' Loop through the cookies array and set each cookie.
		' Both the name and value should be encoded using the
		' Server.URLEncode() function before being passed, if
		' necessary.
		
		For i = 0 To uBound(NameArray)
		
			Response.AddHeader "Set-Cookie",NameArray(i) & "=" & DataArray(i) & "; Path=/; " & CookieStr & CookieExpires
		
		Next
		
	End Sub
	
	' Delete all cookies (except session cookies).
	
	Sub DeleteCookies()
		
		' There isn't a header command for deleting a cookie, instead, you
		' set the expiration date to a time that has already expired, and
		' the users browser will automatically delete the cookie.
		
		Const CookieDeleteDate = "Expires=Thu, 01 Jan 1970 00:00:00 UTC"
		
		' Loop through each cookie and set a header to delete it.
		' NOTE: Request.Cookies doesn't retrieve session cookies.
		
		For Each Item In Request.Cookies
			
			If NOT InStr(Item,"__") = 1 Then
			
				Response.AddHeader "Set-Cookie",Item & "=; Path=/; " & CookieDeleteDate
			
			End If
						
		Next
		
	End Sub
	
	' Certain QueryString functions should be validated with a token. It's not really
	' a necessary implimentation on a demo site such as this. But on a live site it
	' prevents QueryString commands (such as logout or demo reset) from being executed 
	' unless the user has requested the command from their own account and it includes
	' a valid token that can be verified from their Cookie data.
	
	' For example, on a public forum, if a user posts a link to domain.com/?do=logout, 
	' and another user clicks it, that user will be unexpectedly logged out. But by 
	' requiring a token this can be prevented.
	
	' It's also used as a method to prevent CSRF. The token must be included with all
	' form submissions, aJax or otherwise. If the token included with the POST request
	' doesn't match the token cookie sent in the request headers, then the request is
	' denied.
	
	Function GetToken()
	
		If NOT Request.Cookies("Token") = Empty AND _
		IsAlphaNumeric(Request.Cookies("Token")) AND _
		Len(Request.Cookies("Token")) = TokenLength*2 Then
			
			' Get token from cookie if available.
			
			GetToken = Request.Cookies("Token")
			
		ElseIf NOT IsEmpty(Session("Token")) Then
			
			' When AddHeader is used to generate a cookie, that cookie
			' is not available to request until the page is reloaded.
			
			' This isn't the case when you use Response.Cookies, but this
			' method has limitations as to what you can apply to the cookie
			' settings.
			
			' As a backup, when the Token cookie is created, we also create
			' a session value too. We use this session value as a backup if
			' the Token cookie is generated on a page that needs to impliment
			' it.
			
			' The GetToken() function should always be used to fetch the Token.
			
			GetToken = Session("Token")
			
			' Validation.OnLoadValidation() will remove the Token session on the
			' next page load.
			
		End If
	
	End Function
	
	' Checks to see If a string is alpha-numeric:
	' The Function will return true If the string contains letters, numbers or a mixture of both
	
	Function IsAlphaNumeric(ByVal theStr)

		Dim RegEx : Set RegEx = New RegExp
		
			RegEx.Pattern = "^[a-zA-Z0-9]*$"
			IsAlphaNumeric = RegEx.Test(theStr)
		
		Set RegEx = Nothing
		
	End Function
	
	' Regular expression to validate email addresses
	
	Function ValidEmailSyntax(ByVal emailAddress)
	
		If Len(emailAddress) => 6 AND Len(emailAddress) =< 255 Then ' min and max based on domain name limitations
			
			Dim RegEx : Set RegEx = New RegExp
			
				RegEx.Pattern = "^(([^<>()\[\]\\.,;:\s@""]+(\.[^<>()\[\]\\.,;:\s@""]+)*)|("".+""))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$"
				ValidEmailSyntax = RegEx.Test(emailAddress)
			
			Set RegEx = Nothing
			
		Else
		
			ValidEmailSyntax = False
			
		End If
		
	End Function
	
	Function ValidToken(ByVal theToken)
	
		If Len(Request.Cookies("Token")) = TokenLength*2 AND _
		IsAlphaNumeric(Request.Cookies("Token")) AND _
		theToken = Request.Cookies("Token") Then
			
			ValidToken = True
			
		Else
		
			ValidToken = False
		
		End If
	
	End Function
	
	' Prefix numbers less than 10 with a 0, (01,02,03 etc...) this is used for cookie date formating
	
	Function ZeroPad(ByVal theNumber)
		
		ZeroPad = theNumber
		
		If Len(theNumber) = 1 Then
		
			ZeroPad = cStr("0" & theNumber)
			
		End If
		
	End Function
	
	' Generate and format the cookie experation date
	
	Function CookieExperationDate(ExpireDays)
	
		Dim UTCtime, ActualLCID
		
		' Get the current UTC time.
		
		UTCtime = UTC_DateTime()
				
		' Change the LCID to 1033 as to be RFC 6265 compliant.
		
		ActualLCID = Response.LCID
		Response.LCID = 1033
		
			UTCtime = DateAdd("d",ExpireDays,UTCtime)
			
			' Format the cookie experation date
			
			CookieExperationDate = "Expires=" &_ 
			WeekDayName(WeekDay(UTCtime),True) & ", " &_ 
			ZeroPad(Day(UTCtime)) & " " &_ 
			MonthName(Month(UTCtime),True) & " " &_ 
			Year(UTCtime) & " " &_ 
			"00:00:00 UTC"			
		
		' Change the LCID back to what it originally was.
		
		Response.LCID = ActualLCID
		
	End Function
	
	' Generate a random string of letters and numbers.
	
	Function RandomString(StrLen)
    	
		' The amount of number of in the string pool is doubled.
		' This is to make sure there's a better mixture of letters and numbers.
		
		Const StrPool = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ12345678901234567890!""#$%&'()*+,-./:;<=>?@[\]^_`{|}~"
		
		Dim Length, rndChars

    	Length = Len(StrPool)
		
		Randomize()
		
		For i = 1 To StrLen
			rndChars = rndChars & Mid(StrPool,Int(Rnd()*Length+1),1)
		Next

    	RandomString = rndChars
		
	End Function
	
	' Generate a random string of bytes.
	
	Function RandomBytes(bLength)
		
		Dim utf8 : Set utf8 = Server.CreateObject("System.Text.UTF8Encoding")
		
			Randomize()
				
			For i = 1 To bLength			
				RandomBytes = RandomBytes & ChrB(Int(Rnd()*256))
			Next
			
			RandomBytes = utf8.GetBytes_4(RandomBytes)
					
		Set utf8 = Nothing
	
	End Function
	
	' MD5, SHA1, SHA256, SHA384 and SHA512 hashing.
	
	Function Hash(ByVal Input, HashAlgorithm)
		
		' Select the System.Security.Cryptography value.
		
		Select Case uCase(HashAlgorithm)
		
			Case "MD5"
			
				HashAlgorithm = "MD5CryptoServiceProvider"
				
			Case "SHA1"
			
				HashAlgorithm = "SHA1CryptoServiceProvider"
				
			Case "SHA2","SHA256"
			
				HashAlgorithm = "SHA256Managed"
				
			Case "SHA384"
			
				HashAlgorithm = "SHA384Managed"
				
			Case "SHA5","SHA512"
			
				HashAlgorithm = "SHA512Managed"
				
			Case Else
			
				HashAlgorithm = "SHA1CryptoServiceProvider"
		
		End Select
		
		' Convert the input to bytes if not already.
					
		If NOT VarType(Input) = 8209 Then
						
			Dim utf8 : Set utf8 = Server.CreateObject("System.Text.UTF8Encoding")
			
				Input = utf8.GetBytes_4(Input)
												
			Set utf8 = Nothing
			
		End If
		
		' Perform the hash.
					
		Dim hAlg : Set hAlg = Server.CreateObject("System.Security.Cryptography." & HashAlgorithm)
		Dim hEnc : Set hEnc = Server.CreateObject("MSXML2.DomDocument").CreateElement("encode")
			
			hEnc.dataType = "bin.hex"
			hEnc.nodeTypedValue = hAlg.ComputeHash_2((Input))
			Hash = hEnc.Text
				
		Set hEnc = Nothing
		Set hAlg = Nothing
		
	End Function

%>
<script language="javascript" type="text/javascript" runat="server">
	
	// Return the current UTC date and time regardless of what timezone the server is set to
	
	function UTC_DateTime() {
		
		var date = new Date();
		
		// date.getUTCMonth() returns a value from 0 - 11 (dunni why) so we need to  + 1
		
		var result = date.getUTCFullYear() + "-" + (date.getUTCMonth() + 1) + "-" + date.getUTCDate() + " " + date.getUTCHours() + ":" + date.getUTCMinutes() + ":" + date.getUTCSeconds();
		
		// Pad month/day/hour/minute/second values with a 0 If necessary
		
		return result.replace(/(\D)(\d)(?!\d)/g, "$10$2");
		
	}

</script>