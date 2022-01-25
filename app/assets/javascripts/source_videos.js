$(document).ready(function(){
  // hide all others
  $(".video-thumbnail-slider .video-thumbnail:not(:first-child)").hide()

  // on hover
  var timeoutId
  $(".video-thumbnail-slider").hover(function() {
    // on hover in
    var self = this
    timeoutId = setInterval(function() {
      var current = $(self).find('.video-thumbnail:first-child')
      var next    = $(current).next()
      current.hide()
      next.show()
      current.appendTo($(self))
    }, 1000)
  }, function() {
    // on hover out
    window.clearTimeout(timeoutId)
    $(this).find('.video-thumbnail').hide()
    $(this).find('.video-thumbnail[data-index=0]').show()
  })
})
