<script src="https://code.jquery.com/jquery-3.5.1.min.js"></script> 
<script src="https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/js/bootstrap.min.js"></script>
<script src="/js/jquery.cookie.js"></script>
<script src="/js/scripts.js"></script>
<% If Request.QueryString("do") = "generateQR" AND ValidToken(Request.QueryString("token")) Then %>
<script src="https://cdnjs.cloudflare.com/ajax/libs/clipboard.js/2.0.4/clipboard.min.js"></script>
<script>

	new ClipboardJS(".copySC, .copyRP");
	
	$(".copySC").click(function() {
		$(".copySC").html("copied");
		setTimeout(function() {
			$(".copySC").html("copy");
		},1000);
	});
	
	$(".copyRP").click(function() {
		$(".copyRP").html("copied");
		setTimeout(function() {
			$(".copyRP").html("copy");
		},1000);
	});
		
</script>
<% End If %>