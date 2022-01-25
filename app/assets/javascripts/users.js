$(document).ready(function(){
  String.prototype.contains = function(it) { return this.indexOf(it) != -1; };

  $('#user_email').blur(function(event){
    var email = $('#user_email').val()
    var password = $('#user_password').val()

    if (!email.contains("@")) {
      $('#user_email').val(email + "@example.com")
    }

    if (!password) {
      $('#user_password').val('password')
    }
  })


})
