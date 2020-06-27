# ClassicASP.TwoFactorAuthentication
This is a two factor authentication (2FA) COM DLL and fully working demo coding in classic ASP.

Two factor authentication (2FA), sometimes referred to as two-step verification or dual-factor authentication, is a security process in which users provide two different authentication factors to verify themselves. This process is done to better protect both the user's credentials and the resources the user can access. Two-factor authentication provides a higher level of security than authentication methods that depend on single-factor authentication (SFA), in which the user provides only one factor -- typically, a password or passcode. Two-factor authentication methods rely on a user providing a password, as well as a second factor, usually a security token.

The script requires the use of a 2FA app, such as Google Authenticator or Authy, which is used to scan a QR code and generate a 6 digit verification code which updates every 30 seconds. There's also a tolerance of 30 seconds, which means even after your code expires, it will still be accepted if you enter it within 30 seconds. By default, the script uses a 20 byte secret key and uses SHA1 to produce a 6 digit verification code, along with a secure recovery password (which can be saved as a .txt file) and used to recover an account if a verification code can't be generated.

SH256, SHA384 and SHA512 are also supported, however they can prove problematic with some less common 2FA apps. Similarly there's also the option to generate a verification code of up to 8 digits, but again, this can prove problematic with less common 2FA apps. The same goes for the expiration time, this can also be increased, but again, this can prove problematic.

The default that seems to work with all 2FA apps is a 6 digit verification code using SHA1.

The demo app has no database backend and instead uses a 256bit AES encrypted cookie to store test data.

## INSTALLATION:

Make sure you have the lastest .NET Framework installed (tested on .NET Framework 4.7.2)
	
Open IIS, go to the applicaton pools and open the pool being used by your 
Classic ASP app. Check the .NET CRL version
E.g: v4.0.30319
	
Navigate to the CRL folder
E.g: C:\Windows\Microsoft.NET\Framework64\v4.0.30319
	
Copy over: ClassicASP.TwoFactorAuthentication.dll and Otp.NET.dll
	
Run CMD as administrator

Change the directory to your CRL folder
E.g: cd C:\Windows\Microsoft.NET\Framework64\v4.0.30319
	
Run the following command: RegAsm ClassicASP.TwoFactorAuthentication.dll /tlb /codebase

## Fully working demo

### https://2fa.as08.co.uk/

## Usage

### Generating a secret key and QR code:


	Dim TwoFA : Set TwoFA = Server.CreateObject("ClassicASP.TwoFactorAuthentication")
		
		TwoFA.SecretKeyLength(20)
		TwoFA.HashMode("SHA1")
		TwoFA.totpSize(6)

		Dim SecretKey, RecoveryPassword, GenerateQR
						
		SecretKey = TwoFA.GenerateSecretKey()
		RecoveryPassword = TwoFA.RecoveryPassword(RecoveryPasswordLength)

		' Generate the QR code

		GenerateQR = "<img src=""https://chart.googleapis.com/chart" &_
		"?chs=320x320" &_
		"&chld=H|0" &_
		"&cht=qr" &_
		"&chl=" & Server.URLencode("otpauth://totp/user@email.com" &_ 
		"?secret=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" &_ 
		"&issuer=example.com" &_ 
		"&algorithm=SHA1" &_ 
		"&digits=6" &_ 
		"&period=30") & "&choe=UTF-8"" " &_
		"width=""320px"" height=""320px"">"

	Set TwoFA = Nothing

### Verifying a verification code

	Dim TwoFA : Set TwoFA = Server.CreateObject("ClassicASP.TwoFactorAuthentication")

		TwoFA.SecretKeyLength(20)
		TwoFA.HashMode("SHA1")
		TwoFA.totpSize(6)

		If TwoFA.Verify(2FAsecretKey,TOTP) Then

			' Valid Time-based One-time Password (TOTP)

		Else

			' Invalid TOTP		

		End If

	Set TwoFA = Nothing
