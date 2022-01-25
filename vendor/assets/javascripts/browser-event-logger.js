/*
Browser Event Logging class
*/
var BrowserEventLogger = function(params) {
  this.params = Object.extend({
    prefix             : "[fakeplayer-event]",
    mouseMoveThreshold : 300,
    testId             : -1,
    log                : false,
    preventBack        : true,
    onEvent            : undefined
  }, params)

  this.validEvents = [
    'test.id',
    'video.src',
    'system.player.loaded',
    'system.player.playing',
    'system.player.stalling',
    'system.player.qualitychange',
    'system.player.ended',
    'system.player.stopped',
    'system.player.fullscreen',
    'user.player.play',
    'user.player.seek',
    'user.player.pause',
    'user.player.qualitychange',
    'user.fullscreen.requested',
    'user.fullscreen.exited',
    'user.mouse.moved',
    'user.mouse.clicked',
    'user.keyboard.keypress',
    'context.displaysize',
    'context.browser.windowsize',
    'context.browser.useragent',
  ]
  this.init()
}

// initialize the entire logger
BrowserEventLogger.prototype.init = function() {
  this.clickEvents = []

  // check if a new session was started; if not, continue with old
  if (this.isNewSession()) {
    this.log("new test detected, deleting old data")
    this.clearStorage()
  } else {
    this.log("continuing old test with ID " + this.params.testId)
    // assume that the browser page has been reloaded when the test ID stays the same
    this.saveEvent('context.browser.pagereloaded')
  }

  this.mouseTimeLast   = -1
  this.mouseTimeBegin  = -1
  this.mouseMoving     = false
  this.mouseEventBegin = undefined
  this.mouseEventLast  = undefined
  this.mouseDistance   = 0
  this.mouseDuration   = 0

  document.onclick      = this.onClick
  document.onmousemove  = this.onMouseMove
  document.onkeydown    = this.onKeyDown
  window.onresize       = this.onResize

  if (this.params.preventBack) {
    this.disableBackButton()
  }

  this.saveEvent('context.browser.useragent', navigator.userAgent)

}

// ---------------------------------------------------------------------------


// called from document when a click is made
BrowserEventLogger.prototype.onClick = function(e) {
  var self = window.fakePlayer.eventLogger
  var clickedElement = (window.event)
                      ? window.event.srcElement
                      : e.target,
      tags = document.getElementsByTagName(clickedElement.tagName);

  for (var i = 0; i < tags.length; ++i) {
    if (tags[i] == clickedElement) {
      clickEvent = {
        target    : elementToString(clickedElement),
        dataset   : JSON.parse(JSON.stringify(clickedElement.dataset)),
        index     : i,
        clientX   : e.clientX,
        clientY   : e.clientY,
        pageX     : e.pageX,
        pageY     : e.pageY,
      }
      self.clickEvents.push(clickEvent)
      self.saveEvent('user.mouse.clicked', clickEvent)
    }
  }
}

// called when a key is pressed
BrowserEventLogger.prototype.onKeyDown = function(e) {
  var self = window.fakePlayer.eventLogger
  var e = e || window.event
  self.saveEvent('user.keyboard.keypress', e.keyCode)
}

// Called from document when the mouse is moved.
// Saves mouse move events based on a threshold
BrowserEventLogger.prototype.onMouseMove = function(e) {
  var self = window.fakePlayer.eventLogger

  mouseEvent = {
    srcElement : elementToString(e.srcElement),
    target     : elementToString(e.target),
    clientX    : e.clientX,
    clientY    : e.clientY,
    timestamp  : new Date().getTime()
  }

  // initialization for first position
  if (self.mouseEventLast == undefined) {
    self.mouseEventLast = mouseEvent
  }
  if (self.mouseEventBegin == undefined) {
    self.mouseEventBegin = mouseEvent
  }

  var mouseTimeCurrent = new Date().getTime()
  var beginX           = self.mouseEventBegin.clientX
  var beginY           = self.mouseEventBegin.clientY
  var lastX            = self.mouseEventLast.clientX
  var lastY            = self.mouseEventLast.clientY
  var currentX         = mouseEvent.clientX
  var currentY         = mouseEvent.clientY

  // if the cursor has rested for more than 300ms, the event is complete
  if (mouseTimeCurrent - self.mouseTimeLast > self.params.mouseMoveThreshold) {
    mouseMoving = false
    // console.log("mouse move finished, from [" + beginX + "," + beginY + "] to [" + lastX + "," + lastY + "], distance: " + self.mouseDistance + ", duration: " + self.mouseDuration + "ms")

    self.saveEvent('user.mouse.moved', {
      begin    : self.mouseEventBegin,
      end      : self.mouseEventLast,
      distance : self.mouseDistance,
      duration : self.mouseDuration
    })

    // reset counters
    self.mouseDistance = 0
    self.mouseDuration = 0
  } else {
    // movement in progress
    self.mouseDistance += Math.sqrt(Math.pow(currentX - lastX, 2) + Math.pow(currentY - lastY, 2))
    self.mouseDuration += (mouseTimeCurrent - self.mouseTimeLast) / 1000
  }

  // if the mouse was not moving previously, we store the beginning
  // of the event and wait until the threshold is completed
  if (!self.mouseMoving) {
    // console.log("mouse begin set to [" + currentX + "," + currentY + "]")
    self.mouseEventBegin = mouseEvent
    self.mouseMoving = true
  }

  self.mouseEventLast = mouseEvent
  self.mouseTimeLast  = mouseTimeCurrent
}

BrowserEventLogger.prototype.onResize = function(e) {
  var self = window.fakePlayer.eventLogger
  var w  = window,
      d  = document,
      de = d.documentElement,
      g  = d.getElementsByTagName('body')[0],
      x  = w.innerWidth || de.clientWidth || g.clientWidth,
      y  = w.innerHeight|| de.clientHeight|| g.clientHeight

  self.saveEvent('context.browser.windowsize', '' + x + 'x' + y)
}

// when the user tries to go back
BrowserEventLogger.prototype.disableBackButton = function() {
  window.location.hash = "nob";
  window.location.hash = "anob";
  window.onhashchange = function() {
    window.location.hash="nob"
  }
}

BrowserEventLogger.prototype.isNewSession = function() {
  var localStorageTestId = window.localStorage.getItem('fakeplayer.test.id')
  if (localStorageTestId != undefined) {
    // local storage has something saved
    if (localStorageTestId == this.params.testId) {
      return false
    }
  }

  // new test: save new value
  window.localStorage.setItem('fakeplayer.test.id', this.params.testId)
  return true
}

// Serialize and save an event
BrowserEventLogger.prototype.saveEvent = function(eventCode, eventValue, eventTime) {
  if (eventTime == undefined) {
    var eventTime = new Date().getTime()
  }
  if (this.validEvents.indexOf(eventCode > -1)) {

    if (this.params.onEvent != undefined) {
      this.params.onEvent(eventCode, eventValue, eventTime)
    }

    if (this.params.log) {
      this.log("" + eventTime + ": saving " + eventCode + ", value: " + eventValue)
    }

    // if item already exists, get it and merge them into an array
    // FIXME: this may have a performance impact
    var eventToStore
    var previousData = window.localStorage.getItem("fakeplayer." + eventCode)
    // if there is pre-existing data
    if (previousData != undefined) {
      previousDataObj = JSON.parse(previousData)
      // if we don't have an array yet, make it one
      if (previousDataObj.constructor != Array) {
        previousDataObj = [ previousDataObj ]
      }
      // append to the end
      previousDataObj.push({
        timestamp : eventTime,
        value     : eventValue
      })
      eventToStore = previousDataObj
    } else {
      // just store it
      eventToStore = {
        timestamp : eventTime,
        value     : eventValue
      }
    }

    window.localStorage.setItem(
      "fakeplayer." + eventCode, JSON.stringify(eventToStore)
    )
  } else {
    console.error(this.params.prefix + " tried to save event " + eventCode + ", but I don't know this");
  }
}

// get all FakePlayer events from the localstorage and return them as a JS object
BrowserEventLogger.prototype.getEvents = function() {
  var ret = {}
  for (var key in window.localStorage) {
    if (key.startsWith("fakeplayer")) {
      val      = localStorage.getItem(key)
      value    = JSON.parse(val)
      ret[key] = value
    }
  }
  return(ret)
}

// delete all FakePlayer events
BrowserEventLogger.prototype.clearStorage = function() {
  var i = 0
  for (var key in window.localStorage) {
    if (key.startsWith("fakeplayer") && (key != "fakeplayer.test.id")) {
      localStorage.removeItem(key)
      i = i + 1
    }
  }
  this.log("deleted " + i + " entries from localstorage")
}

// just log a message to the console
BrowserEventLogger.prototype.log = function(message) {
  if (this.params.log)
    console.log(this.params.prefix + " " + message)
}

// sends all the stored data in form of a POST request to a certain URL
BrowserEventLogger.prototype.sendData = function(url, params) {
  var events = this.getEvents()
  var postParams = (params == undefined) ? {} : params
  postParams.events = events
  $.post(url, postParams, function(response, status, xhr) {

  })
}

// =============================================================================
// HELPERS

// converts a DOM element to a readable string, e.g.
// DIV#something.class1.class2
// BUTTON.class1.class2
function elementToString(domElement) {
  var tagName   = domElement.tagName
  var id        = domElement.id
  var classList = Array.prototype.slice.call(domElement.classList, 0)
  var outStr    = ""

  outStr = tagName
  if (id && (id != "")) {
    outStr += "#" + id
  }
  if (classList != undefined) {
    outStr += "." + classList.join(".")
  }

  // remove trailing dot
  if (outStr[outStr.length-1] === ".")
    outStr = outStr.slice(0,-1);

  return outStr
}


// Helper function to allow extending an object
Object.extend = function(destination, source) {
    for (var property in source) {
        if (source.hasOwnProperty(property)) {
            destination[property] = source[property]
        }
    }
    return destination
}
