<!--#include file = "../../includes/config.asp" -->
<%
	
	' Redirect to the account page if the user is already logged in.
	
	If Session("LoggedIn") AND NOT Session("2FArequired") Then Response.Redirect "/account/"
	
	' Redirect to the login page if LoggedIn and 2FArequired are false.
	
	If NOT Session("LoggedIn") AND NOT Session("2FArequired") Then Response.Redirect "/login/"

%><!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
<meta name="description" content="Two Factor Authentication Demo coded in Classic ASP">
<meta name="author" content="2fa.as08.co.uk">
<link rel="icon" href="/img/favicon.png">
<title>Login</title>
<link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css">
</head>
<body class="bg-light">
<!--#include file = "../../includes/lib/JavaScriptWarning.asp" -->
<div class="container">
  <div class="py-5 text-center">
  <a href="/"><img src="/img/logo.png" class="mb-4"></a>
<!--#include file = "../../includes/lib/2FAform.asp" -->
</div>      
<!--#include file = "../../includes/lib/PayPalFooter.asp" -->
</div>
<!--#include file = "../../includes/lib/scripts.asp" -->
</body>
</html>