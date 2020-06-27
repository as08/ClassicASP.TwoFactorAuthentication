<!--#include file = "includes/config.asp" -->
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
<meta name="description" content="Two Factor Authentication Demo coded in Classic ASP">
<meta name="author" content="2fa.as08.co.uk">
<link rel="icon" href="/img/favicon.png">
<title>Welcome</title>
<link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css">
</head>
<body class="bg-light">
<!--#include file = "includes/lib/JavaScriptWarning.asp" -->
<div class="container">
  <div class="py-5 text-center">
  <img src="/img/logo.png" alt="Two Factor Authentication">
    <h2>Two Factor Authentication Demo</h2>
    <p class="lead">This demo is written in Classic ASP and is available to <a href="https://github.com/as08/ClassicASP.TwoFactorAuthentication" target="_blank">download from GitHub</a></p>
    <% If Session("LoggedIn") AND NOT Session("2FArequired") Then %>
    <p><a class="btn btn-success btn-lg" style="width:150px;" href="/account/" role="button">My Account</a></p>
    <p><a href="?do=logout&token=<%=GetToken()%>">Logout</a></p>
	<% Else %>
    <p><a class="btn btn-primary" style="width:100px;" href="/login/" role="button">Login</a></p>
    <p><a class="btn btn-primary" style="width:100px;" href="/register/" role="button">Register</a></p>
    <% End If %>
    <% If NOT IsNull(Session("Username")) Then %><p><a href="?do=reset&token=<%=GetToken()%>" class="small font-weight-bold confirm">Reset the demo</a></p><% End If %>
  </div>
<!--#include file = "includes/lib/PayPalFooter.asp" -->
</div>
<!--#include file = "includes/lib/scripts.asp" -->
</body>
</html>