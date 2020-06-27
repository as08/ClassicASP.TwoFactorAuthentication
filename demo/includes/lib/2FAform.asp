<div class="col-md-5 m-auto text-left">
  <div class="card fat">
    <div class="card-body">
      <% If Request.QueryString("do") = "recovery" AND NOT Test2FA Then %>
      <h4 class="card-title">Recover Your Account</h4>
      <form method="POST" class="TwoFA-validation">
        <div class="alert alert-danger mb-4 mt-4" style="display:none;" id="error-message" role="alert">
          <p class="m-0" id="error-description"></p>
        </div>
        <div class="form-group">
          <label for="RecoveryPassword">Your 2FA recovery password</label>
          <input
              type="password"
              class="form-control"
              name="RecoveryPassword"
              id="RecoveryPassword"
              minlength="<%=RecoveryPasswordLength%>"
              maxlength="<%=RecoveryPasswordLength%>"
              autocomplete="off"
              required
          />
        </div>
        <div class="form-group m-0">
          <button type="submit" class="btn btn-primary btn-block">Recover</button>
        </div>
        <div class="mt-4 text-center">
          <p>This will log you into your account and disable 2FA</p>
          <p class="mb-0"><a href="/login/2FA/">&laquo; Back</a></p>
        </div>
        <input type="hidden" name="Token" value="<%=GetToken()%>">
        <input type="hidden" name="form-type" value="recover">
      </form>
      <% Else %>
      <h4 class="card-title">Two Factor Authentication<% If Test2FA Then %> Test<% End If %></h4>
      <form method="POST" class="TwoFA-validation">
		<% If Test2FA Then %>
        <div class="alert alert-success mb-4 mt-4" style="display:none;" id="success-message" role="alert">
          <p class="m-0" id="success-description"></p>
        </div>
        <% End If %>
        <div class="alert alert-danger mb-4 mt-4" style="display:none;" id="error-message" role="alert">
          <p class="m-0" id="error-description"></p>
        </div>
        <div class="form-group">
          <label for="totp">2FA <%=totpSize%> digit code</label>
          <input
              type="text"
              class="form-control"
              name="totp"
              id="totp"
              minlength="<%=totpSize%>"
              maxlength="<% Response.Write totpSize+1 ' Plus 1 to account for a space %>"
              inputmode="numeric"
              autocomplete="off"
              required
          />
        </div>
        <div class="form-group m-0">
          <button type="submit" class="btn btn-primary btn-block">Submit</button>
        </div>
        <% If NOT Test2FA Then %>
        <div class="mt-4 text-center">
          <p><a href="?do=recovery">Enter recorvery password</a></p>
          <p class="mb-0"><a href="?do=logout&token=<%=GetToken()%>">Cancel and return to the homepage</a></p>
        </div>
        <% End If %>
        <input type="hidden" name="Token" value="<%=GetToken()%>">
        <input type="hidden" name="form-type" value="2fa<% If Test2FA Then Response.Write "-test" %>">
      </form>
      <% End If %>
    </div>
  </div>
</div>