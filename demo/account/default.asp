<!--#include file = "../includes/config.asp" -->
<%

	If NOT Session("LoggedIn") OR Session("2FArequired") Then Response.Redirect "/"
			
%><!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
<meta name="description" content="Two Factor Authentication Demo coded in Classic ASP">
<meta name="author" content="2fa.as08.co.uk">
<link rel="icon" href="/img/favicon.png">
<title>Your Account</title>
<link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css">
</head>
<body class="bg-light">
<!--#include file = "../includes/lib/JavaScriptWarning.asp" -->
<div class="container">  
  <div class="py-5 text-center">
  <a href="/"><img src="/img/logo.png" alt="Two Factor Authentication"></a>
    <h2>Welcome <%=Session("Username")%></h2>
    <p class="lead">This is an example of a user account page</p>
    <% If NOT Session("2FAenabled") Then %>
    <% If Request.QueryString("recovered") = "true" Then %>
    <p class="lead font-weight-bold">You successfully recovered your account<br>2FA has been disabled</p>
    <% End If %>
    <p>
      <a href="2FA/" class="btn btn-success btn-lg" role="button">Enable Two Factor Authentication</a>
    </p>
    <% ElseIf Request.QueryString("newLogin") = "true" Then %>
    <p class="lead font-weight-bold">You successfully logged in using Two Factor Authentication</p>
    <p>You can run 2FA tests by <a href="2FA/?do=testQR&token=<%=GetToken()%>">clicking here</a></p>
    <p><a href="?do=disable-2fa&token=<%=GetToken()%>" class="font-weight-bold confirm">Disable Two Factor Authentication</a></p>
    <% Else %>
    <p class="lead font-weight-bold">Two Factor Authentication is enabled on your account</p>
    <p>You can run 2FA tests by <a href="2FA/?do=testQR&token=<%=GetToken()%>">clicking here</a></p>
    <p><a href="?do=disable-2fa&token=<%=GetToken()%>" class="font-weight-bold confirm">Disable Two Factor Authentication</a></p>
	<% End If %>
    <% If NOT VariablesTbl = "" Then %>
    <p>
      <a class="btn btn-danger" href="/account/" role="button">Hide Session / Cookie Values</a>
    </p>
      <div class="m-auto col-md-7 text-left text-break">
		<%=VariablesTbl%>
      </div>
    <% Else %>
    <p>
      <a class="btn btn-primary" href="?do=DisplayVariables&token=<%=GetToken()%>" role="button">Display Session / Cookies Values</a>
    </p>
	<% End If %>
    <p><a href="?do=logout&token=<%=GetToken()%>">Logout</a></p>
    <p><a href="?do=reset&token=<%=GetToken()%>" class="small font-weight-bold confirm">Reset the demo</a></p>
  </div>
<!--#include file = "../includes/lib/PayPalFooter.asp" -->
</div>
<!--#include file = "../includes/lib/scripts.asp" -->
</body>
</html>