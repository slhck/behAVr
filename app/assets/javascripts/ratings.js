$(document).ready(function(){
  $('.star-rating label').click(function() {
    var rating = $(this).html()
    $(this).parent().prev('[data-answer-field=true]').val(rating)
  })
})
