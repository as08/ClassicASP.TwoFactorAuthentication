$(function() {

	"use strict";
	
	$.cookie("test_cookie", "1", { path: "/" });
	if ($.cookie("test_cookie") !== "1") {
		location.href = "/enable-cookies/";
	}else{
		$.removeCookie("test_cookie", { path: "/" });
	}
	
	$(".confirm").click(function(){
		return confirm("Are you sure?");
	});

	$(".TwoFA-validation").submit(function() {
		event.preventDefault();
		var form_serialized = $(this).serialize();
		$(".TwoFA-validation :input").prop("disabled",true);
		$("#error-message").hide();
		$("#success-message").hide();
		$.ajax({
			type: "POST",
			url: "/ajax/",
			cache: false,
			data: form_serialized,
			dataType: "json",
			success: function(data) {
				$(".TwoFA-validation :input").prop("disabled",false);
				if(data.error){
					$("#success-message").hide();
					$("#error-message").show();
					$("#error-description").html(data.description);
				} else if(data.success) {
					$("#error-message").hide();
					$("#success-message").show();
					$("#success-description").html(data.description);
				} else {
					$("#error-message").hide();
					location.href = data.redirect;
				}
			},
			error: function() {
				$(".TwoFA-validation :input").prop("disabled",false);
				$("#success-message").hide();
				$("#error-message").show();
				$("#error-description").html("Oops, something went wrong.<br>Please try again later.");
			}
		});
	});
	
});