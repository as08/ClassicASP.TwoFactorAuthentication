<!--#include file = "../includes/config.asp" -->
<%
	
	' Redirect to the account page if the user is already logged in.
	
	If Session("LoggedIn") AND NOT Session("2FArequired") Then Response.Redirect "/account/"
	
	' Remove the LoggedIn and 2FArequired session. This is incase 2FA is required but the 
	' user visits the login page again.
	
	Session.Contents.Remove("LoggedIn")
	Session.Contents.Remove("2FArequired")

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
<!--#include file = "../includes/lib/JavaScriptWarning.asp" -->
<div class="container">
  <div class="py-5 text-center">
  <a href="/"><img src="/img/logo.png" class="mb-4"></a>
  <div class="col-md-7 m-auto text-left">
    <div class="card fat">
      <div class="card-body">
        <h4 class="card-title">Login</h4>
        <form method="POST" class="TwoFA-validation">
          <div class="alert alert-danger mb-4 mt-4" style="display:none;" id="error-message" role="alert">
            <p class="m-0" id="error-description"></p>
          </div>
          <div class="form-group">
            <label for="email">Email Address</label>
            <input id="email" type="email" class="form-control" name="email" value="<% If Session("RememberMe") Then Response.Write Session("Email")%>" required autofocus>
          </div>
          <div class="form-group">
            <label for="password">Password</label>
            <input id="password" type="password" class="form-control" name="password" minlength="6" maxlength="50" required>
          </div>
          <div class="form-group">
            <div class="custom-checkbox custom-control">
              <input type="checkbox" name="remember" id="remember" class="custom-control-input"<% If Session("RememberMe") Then %> checked<% End If %>>
              <label for="remember" class="custom-control-label">Remember Me</label>
            </div>
          </div>
          <div class="form-group m-0">
            <button type="submit" class="btn btn-primary btn-block">Login</button>
          </div>
          <div class="mt-4 text-center">
            Don't have an account? <a href="/register/">Create One</a>
          </div>
          <input type="hidden" name="Token" value="<%=GetToken()%>">
          <input type="hidden" name="form-type" value="login">
        </form>
      </div>
    </div>
   </div>
</div>    
<!--#include file = "../includes/lib/PayPalFooter.asp" -->
</div>
<!--#include file = "../includes/lib/scripts.asp" -->
</body>
</html>