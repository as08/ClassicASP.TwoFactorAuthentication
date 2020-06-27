<!--#include file = "../../includes/config.asp" -->
<%

	If NOT Session("LoggedIn") OR Session("2FArequired") Then Response.Redirect "/"
	
	If Request.QueryString("do") = "downloadRC" AND NOT _
	IsEmpty(Session("2FArecoveryPassword")) AND _
	ValidToken(Request.QueryString("token")) Then
	
		Response.AddHeader "Content-Disposition", "attachment;filename=2fa.as08.co.uk.recovery.password." & Session("Username") & ".txt"  
		Response.ContentType = "text/plain" 
		
		Response.Write "Email: " & Session("Email") & VBlf
		Response.Write "Recovery Password: " & Session("tmp_2FArecoveryPassword")
		
		Response.End()
		
	End If
	
%><!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
<meta name="description" content="Two Factor Authentication Demo coded in Classic ASP">
<meta name="author" content="2fa.as08.co.uk">
<link rel="icon" href="/img/favicon.png">
<title>Enable 2FA</title>
<link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css">
</head>
<body class="bg-light">
<!--#include file = "../../includes/lib/JavaScriptWarning.asp" -->
<div class="container">  
  <div class="py-5 text-center">
  <a href="/account/"><img src="/img/logo.png" alt="Two Factor Authentication"></a>
    <% If (Request.QueryString("do") = "confirmQR" AND NOT _
	IsEmpty(Session("tmp_2FAsecretKey")) AND NOT _
	IsEmpty(Session("tmp_2FArecoveryPassword")) AND _
	ValidToken(Request.QueryString("token"))) OR _
	(Session("2FAenabled") AND _
	Request.QueryString("do") = "testQR" AND _
	ValidToken(Request.QueryString("token"))) Then
	
	' Set the 2FA cookies if the 2FA setup is being confirmed
	
	If Request.QueryString("do") = "confirmQR" AND NOT Session("2FAenabled") Then
	
		' create the 2FA credential cookies
		
		Set Aes = New AdvancedEncryptionStandard		
		Set Validate = New Validation
		
			Dim RecoveryPasswordSalt : RecoveryPasswordSalt = RandomString(PasswordSaltLength)
			
			' Use the AesSha256Secret constant as a pepper.
			
			Call Validate.ChangeDataCookieJson(_
				Array("2FAsecretKey","2FArecoveryPassword","2FArecoveryPasswordSalt"),_
				Array(Aes.Encrypt(Session("tmp_2FAsecretKey")),Hash(AesSha256Secret & Session("tmp_2FArecoveryPassword") & RecoveryPasswordSalt,"Sha256"),RecoveryPasswordSalt)_
			)
						
			Session("2FAenabled") = True
		
		Set Validate = Nothing
		Set Aes = Nothing
		
	End If
	
	Test2FA = True
	
	%>
    <h2>Two Factor Authentication</h2>
	<% If Request.QueryString("do") = "confirmQR" Then %>
    <p class="lead mt-4"><strong>Congratulations!</strong> 2FA has been successfully enabled on your account</p>
	<% End If %>
    <p class="lead mt-4">Test your 2FA is working correctly, if not, you can <a href="?do=disable-2fa&token=<%=GetToken()%>" class="confirm">disable 2FA</a> and generate a new QR code</p>
<!--#include file = "../../includes/lib/2FAform.asp" -->
    <p class="mt-4">You can also test your 2FA by <a href="?do=logout&token=<%=GetToken()%>">logging out of your account</a> and logging back in again</p>
	<% 
	
	ElseIf Session("2FAenabled") Then
		
		' Redirect back to the accounts page if 2FA is already enabled.
		
		Response.Redirect "/account/"
		
	ElseIf Request.QueryString("do") = "generateQR" AND _
	Request.QueryString("token") = Request.Cookies("Token") Then
    			
    	' Go ahead and generate the 2FA QR code / SecretKey
	
		Set TwoFA = Server.CreateObject("ClassicASP.TwoFactorAuthentication")
		
			TwoFA.SecretKeyLength(SecretKeyLength)
			TwoFA.HashMode(HashMode)
			TwoFA.totpSize(totpSize)
			
			Dim SecretKey, RecoveryPassword, GenerateQR
						
			SecretKey = TwoFA.GenerateSecretKey()
			RecoveryPassword = TwoFA.RecoveryPassword(RecoveryPasswordLength)
			
			' Store as session values until the user clicks the completed button.
			
			Session("tmp_2FAsecretKey") = SecretKey
			Session("tmp_2FArecoveryPassword") = RecoveryPassword
									
			GenerateQR = "<img src=""https://chart.googleapis.com/chart" &_
			"?chs=" & QRpixels & "x" & QRpixels &_
			"&chld=H|0" &_
			"&cht=qr" &_
			"&chl=" & Server.URLencode("otpauth://totp/" & Session("Email") &_ 
			"?secret=" & SecretKey &_ 
			"&issuer=" & Issuer &_ 
			"&algorithm=" & uCase(HashMode) &_ 
			"&digits=" & totpSize &_ 
			"&period=30") & "&choe=UTF-8"" " &_
			"class=""img-fluid border-info border mt-4 QRframe"" " &_
			"width=""" & QRpixels & "px"" height=""" & QRpixels & "px"">"
				
		Set TwoFA = Nothing
    %>
    <h2>Enable Two Factor Authentication</h2>
    <p class="lead mt-4">Scan the QR code using your 2FA App</p>
	<style type="text/css">
	.QRframe{
		background-image: url('/img/loader.gif');
		background-repeat: no-repeat;
		background-position: <%=Round((QRpixels/2)-85,0)%>px <%=Round((QRpixels/2)-85,0)%>px;
	}
	</style>
    <%=GenerateQR%>
    <p class="lead mt-4">Or setup manually using the key below:</p>
    <div class="input-group col-md-7 m-auto mb-4">
    <input id="SecretKey" type="text" class="form-control" value="<%=SecretKey%>" readonly onClick="this.select();">
    <div class="input-group-append">
    <button class="btn btn-primary copySC" type="button" data-clipboard-target="#SecretKey">copy</button>
    </div>
    </div>
    <p class="lead mt-4"><strong>Recovery Password</strong></p>
    <p>Store this recovery password somewhere safe</p>
    <div class="input-group col-md-7 m-auto">
    <input id="RecoveryPassword" type="text" class="form-control" value="<%=RecoveryPassword%>" readonly onClick="this.select();">
    <div class="input-group-append">
    <button class="btn btn-primary copyRP" type="button" data-clipboard-target="#RecoveryPassword">copy</button>
    </div>
    </div>
    <p class="small mt-2"><a href="?do=downloadRC&token=<%=GetToken()%>" target="_blank">Download as a .txt file</a></p>
    <hr class="mt-4">
    <p class="mt-4">
      <a href="?do=confirmQR&token=<%=GetToken()%>" class="btn btn-success btn-lg" href="/account/" role="button">My 2FA Setup Is Complete!</a>
    </p>
    <p class="small mt-2">You must click this button to finalize the setup process and enable 2FA on your account</p>
	<% Else %>
    <h2>Enable Two Factor Authentication</h2>
    <p class="lead mt-4"><strong>Step 1</strong> - Download a Two factor Authentication App</p>
    <p>We recommend either <strong>Google Authenticator</strong> or <strong>Authy</strong></p>
    <p class="mt-4">
        <img src="/img/google-authenticator.svg" class="rounded mr-2 img-fluid" alt="Google Authenticator" width="80" height="80">
        <img src="/img/authy.svg" class="rounded ml-2 img-fluid" alt="Authy" width="80" height="80">
  	</p>
    <p class="lead mt-4"><strong>Step 2</strong> - Use your 2FA App to scan a unique QR code</p>
    <p>If the QR code is being generated on a mobile device, you can setup Two factor Authentication manually by entering a private key</p>
    <p class="mt-4">
        <img src="/img/2fa-icon.png" class="img-fluid border-info border mt-4 mb-4" alt="Scan the QR Code">
  	</p>
    <p class="lead mt-4"><strong>Step 3</strong> - Enter the numeric passcode generated by your 2FA app when you next login</p>
    <p>Your 2FA app will generate a time-based one-time passcode (TOTP) which updates every 30 seconds</p>
    <p class="mt-4">
        <img src="/img/totp-1.png" class="img-fluid border-info border mt-4 mb-4" alt="time-based one-time passcode">
  	</p>
    <p class="lead mt-4"><strong>Account Recovery</strong></p>
    <p>When your QR code is generated, you will also be issued a recovery password. This can be used to recover your account and disable 2FA if you are unable to generate a TOTP. This password should be saved somewhere safe (such as a password manager)</p>
    <hr class="mt-4">
    <p class="mt-4">
      <a href="?do=generateQR&token=<%=GetToken()%>" class="btn btn-success btn-lg" href="/account/" role="button">Generate My QR Code</a>
    </p>
    <% End If %>
  </div>
<!--#include file = "../../includes/lib/PayPalFooter.asp" -->
</div>
<!--#include file = "../../includes/lib/scripts.asp" -->
</body>
</html>