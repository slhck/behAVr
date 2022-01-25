/*
FakePlayer class

Author: Werner Robitza
*/
var FakePlayer = function(params) {
  params = params || {}

  // default params
  this.params = Object.extend({
    testId                    : 0,
    initLevel                 : -1,
    initialBufferingTime      : 0,
    source                    : 'http://localhost:8000/example_html/hls_stream_sintel/sintel-trailer.m3u8',
    parentId                  : '#player',
    width                     : 1280,
    height                    : 720,
    fakeBufferUpdateInterval  : 2,
    fakeBufferLength          : 5,
    afterSeekDelay            : 5,
    afterLevelChangeDelayUp   : 5,
    afterLevelChangeDelayDown : 1,
    baseUrl                   : 'http://localhost:8000/clappr/dist/',
    hideMediaControl          : true,
    autoPlay                  : true,
    stallingEventList         : [],
    qualityChangeEventList    : [],
    log                       : true,
    preventClose              : false,
    preventBack               : false,
    onEvent                   : undefined
  }, params)

  this.logger      = new Logger(this.params.log)
  this.eventLogger = new BrowserEventLogger({
    testId      : this.params.testId,
    log         : this.params.log,
    preventBack : this.params.preventBack,
    onEvent     : this.params.onEvent
  })

  this.timers = {}

  if (this.params.preventClose) {
    window.onbeforeunload = function(e) {
      return 'Are you sure?'
    }
  }

  this.init()
}

// Create the player with parameters and trigger initial quality level
// as well as buffering time
FakePlayer.prototype.init = function() {

  self = this
  // start the Clappr player itself with some defaults
  this.player = new Clappr.Player({
    source          : this.params.source,
    parentId        : this.params.parentId,
    width           : this.params.width,
    height          : this.params.height,
    baseUrl         : this.params.baseUrl,
    autoPlay        : this.params.autoPlay,
    hideMediaControl: this.params.hideMediaControl,
    hlsLogEnabled   : false,
    mute            : false,
    plugins : {
      'core' : [LevelSelector]
    }
  })

  this.eventLogger.saveEvent('system.player.loaded')
  this.eventLogger.saveEvent('video.src', this.params.source)

  // assign future events
  this.plannedStallingEvents      = this.params.stallingEventList
  this.plannedQualityChangeEvents = this.params.qualityChangeEventList

  // for fake buffering simulation
  this.fakeBufferLastUpdated = 0
  this.maximumMediaTime      = 0

  // for initial level and initial loading
  this.initLevelChanged       = false
  this.initBufferingStarted = false
  this.playCount              = 0
  this.lastTimeUpdate         = 0

  // whenever a seek event occurs
  this.player.on(Clappr.Events.PLAYER_SEEK, function(e) {
    self.onPlayerSeek(e)
  })

  // when playback ended
  this.player.on(Clappr.Events.PLAYER_ENDED, function(e) {
    self.onPlayerEnded()
  })

  // when playback stops
  this.player.on(Clappr.Events.PLAYER_STOP, function(e) {
    self.onPlayerStopped()
  })

  // When user is pausing
  this.player.on(Clappr.Events.PLAYER_PAUSE, function(e) {
    self.onPlayerPause(e)
  })

  this.player.on(Clappr.Events.PLAYER_TIMEUPDATE, function(t) {
    self.onTimeUpdate(t)
  })

  this.player.on(Clappr.Events.PLAYER_PLAY, function() {
    self.onPlayerPlay()
  })

  this.player.on(Clappr.Events.MEDIACONTROL_FULLSCREEN, function() {
    self.onPlayerFullscreen()
  })

  this.player.on(Clappr.Events.CONTAINER_FULLSCREEN, function() {
    self.onPlayerFullscreen()
  })

  $(document).on('webkitfullscreenchange mozfullscreenchange fullscreenchange MSFullscreenChange', function(){
    self.onPlayerFullscreen()
  })
}

// ---------------------------------------------------------------------------


// Called whenever there is a play event
FakePlayer.prototype.onPlayerPlay = function() {
  self = this
  self.logger.log("on.PLAYER_PLAY called")
  self.eventLogger.saveEvent('system.player.playing')


  // start the wall clock
  self.startTime = Date.now() / 1000

  // the initial fake buffer will appear when the initial buffering
  // time is completed
  if (self.playCount == 0) {

    self.addTimer("FAKE_BUFFER_LEVEL_AFTER_INIT", function() {
      self.setFakeBufferLevel(self.params.fakeBufferLength)
    }, self.params.initialBufferingTime)

    // call onResize first
    // FIXME: this doesn't belong here, but it needs to be called after player is initialized
    // to window.fakePlayer
    self.eventLogger.onResize()
  }

  self.playCount += 1

  // change initial quality level if needed
  if ((self.params.initLevel >= 0) && !self.initLevelChanged) {
    self.logger.log("setting initial level to " + self.params.initLevel)
    self.setLevel(self.params.initLevel, immediately = true)
    self.initLevelChanged = true
  }

  // fake initial buffering time
  if (
    (self.playCount == 1) &&
    !self.initBufferingStarted &&
    (self.params.initialBufferingTime > 0)
  ) {
    self.stall(self.params.initialBufferingTime)
    self.initBufferingStarted = true
  }
}

// whenever the user pauses the playback
FakePlayer.prototype.onPlayerPause = function(e) {
  self = this
  self.logger.log("on.PLAYER_PAUSE called")
  self.eventLogger.saveEvent('user.player.pause')

  self.cancelAllTimers()
}

// Called when the player is seeking to a position
FakePlayer.prototype.onPlayerSeek = function(t) {
  self = this
  self.logger.log("on.PLAYER_SEEK called")

  var duration = self.flashPlayer.getDuration()
  var seekTargetTime = duration * (t / 100)
  self.eventLogger.saveEvent('user.player.seek', seekTargetTime)

  if (
    // removed for first test: users can forward while stalling to "break" out of it
    // !(this.isFakeBuffering) &&
    (seekTargetTime >= self.maximumMediaTime)
  ) {
    // OPTION 1: user seeked forward
    // force artificial stalling,
    // but only if we're not seeking backwards
    // or not fake buffering
    self.logger.log("User skipped forward")
    self.cancelAllTimers()

    // resume the playback only if the user didn't pause
    if (!(["PAUSED", "PAUSED_BUFFERING"].indexOf(self.hlsPlayback.currentState) >= 0)) {
      self.stall(self.params.afterSeekDelay)
    }

    // add artificial stalling
    self.addTimer("FAKE_BUFFER_LEVEL_AFTER_SEEK", function() {
      self.setFakeBufferTime(seekTargetTime + self.params.fakeBufferLength)
    }, self.params.afterSeekDelay)
  } else {
    // OPTION 2: user skipped backward
    // if the user skipped back, resume immediately
    if (self.playCount == 1) {
      // do nothing, user hasn't finished initial buffering yet
      self.logger.log("User skipped backward, not resuming because not started yet")
    } else {
      self.logger.log("User skipped backward into buffered area, resuming")
      self.cancelAllTimers()
      self.resume()
    }
  }
}

// Called when there is playback progress
FakePlayer.prototype.onTimeUpdate = function(t) {
  self = this
  self.currentMediaTime = t

  // the farthest we've played so far
  if (self.currentMediaTime > self.maximumMediaTime) {
    self.maximumMediaTime = self.currentMediaTime
  }

  // update fake buffer after interval, but only if playing, and if the last
  // update hasn't been so long ago
  if (
  ((self.getCurrentWallTime() - self.fakeBufferLastUpdated) > self.params.fakeBufferUpdateInterval) &&
  (self.hlsPlayback.currentState == "PLAYING")
  ) {
    // update the buffer at most to the time of the next planned stalling event,
    // but only if the stalling event is in the future
    var nextStallingEvent = self.getNextPlannedStallingEventTime()
    var newFakeBufferTime = self.currentMediaTime + self.params.fakeBufferLength
    if (
      (nextStallingEvent !== undefined) && (
       self.currentMediaTime < nextStallingEvent)
    ) {
      newFakeBufferTime = Math.min(nextStallingEvent, self.currentMediaTime + self.params.fakeBufferLength)
    }
    self.logger.log("setting fake buffer to " + newFakeBufferTime + ", media time: " + self.currentMediaTime)
    self.setFakeBufferTime(newFakeBufferTime)
  }

  // insert fake stalling events if necessary
  if (!self.isFakeBuffering) {
    for (i = 0; i < self.plannedStallingEvents.length; i++) {
      var plannedStallingEvent         = self.plannedStallingEvents[i]
      var plannedStallingEventTime     = plannedStallingEvent[0]
      var plannedStallingEventDuration = plannedStallingEvent[1]

      // check that the user hasn't been seeking over the event
      if ((self.currentMediaTime >= plannedStallingEventTime) &&
          ((plannedStallingEventTime + 1) >= self.currentMediaTime))
      {
        self.logger.log("planned stalling event for " + plannedStallingEventTime + "s started, media time: " + self.currentMediaTime)
        self.plannedStallingEvents.splice(i, 1)
        self.stall(plannedStallingEventDuration)
        self.addTimer("FAKE_BUFFER_LEVEL_AFTER_PLANNED_STALL", function() {
          self.setFakeBufferTime(self.currentMediaTime + self.params.fakeBufferLength)
        }, plannedStallingEventDuration)
      }
    }
  }

  for (i = 0; i < self.plannedQualityChangeEvents.length; i++) {
    var plannedQualityChangeEvent      = self.plannedQualityChangeEvents[i]
    var plannedQualityChangeEventTime  = plannedQualityChangeEvent[0]
    var plannedQualityChangeEventLevel = plannedQualityChangeEvent[1]
    if ((self.currentMediaTime >= plannedQualityChangeEventTime) &&
        ((plannedQualityChangeEventTime + 1) >= self.currentMediaTime))
    {
        self.logger.log("planned QL change event for " + plannedQualityChangeEventTime + "s started, media time: " + self.currentMediaTime)
        self.plannedQualityChangeEvents.splice(i, 1)
        self.setLevel(plannedQualityChangeEventLevel, immediately = true)
    }
  }
}

// Called when playback is ended
FakePlayer.prototype.onPlayerEnded = function() {
  var self = this
  self.eventLogger.saveEvent('system.player.ended')
}

// Called when playback is stopped
FakePlayer.prototype.onPlayerStopped = function() {
  var self = this
  self.eventLogger.saveEvent('system.player.stopped')
}

// Called when playback is stopped
FakePlayer.prototype.onPlayerFullscreen = function() {
  var self = this
  self.eventLogger.saveEvent('system.player.fullscreen')
}

// Add a specific timer with a name and a timeout in seconds
FakePlayer.prototype.addTimer = function(name, callback, timeout) {
  self = this
  // get the timeout ID, call the function
  var timeoutId = window.setTimeout(function() {
    callback()
  }, timeout * 1000)
  // and delete the timer when it's done (this has to be done outside,
  // otherwise we wouldn't know the ID
  window.setTimeout(function() {
    self.logger.log("Timer " + timeoutId + " (" + name + ") completed")
    delete self.timers[timeoutId]
  }, timeout * 1000)

  if (this.timers[timeoutId] !== undefined) {
    this.logger.error("Timer with ID " + timeoutId + "already exists")
  }
  this.timers[timeoutId] = {
    name : name,
    id   : timeoutId,
  }
  this.logger.log("Timer " + timeoutId + " (" + name + ") added, will complete in " + timeout + " seconds")
}

// Cancel currently running timers in case of user skipping
FakePlayer.prototype.cancelAllTimers = function() {
  for (var timeoutId in this.timers) {
      if (this.timers.hasOwnProperty(timeoutId)) {
        var timer = this.timers[timeoutId]
        window.clearTimeout(timer.id)
        this.logger.log("Timer " + timer.id + " (" + timer.name + ") cancelled")
        delete this.timers[timeoutId]
      }
  }
}

// Elapsed time since first playback (not considering initial buffering)
FakePlayer.prototype.getCurrentWallTime = function() {
  var now = Date.now() / 1000;
  return(now - this.startTime)
}

// Current media time
FakePlayer.prototype.getCurrentMediaTime = function() {
  return(this.currentMediaTime)
}

// Get the fake buffer level in percent
FakePlayer.prototype.getFakeBufferLevel = function() {
  var level = parseFloat(document.getElementsByClassName("bar-fill-fake")[0].style.width.replace('%',''))
  if (!level) {
    return(0)
  } else {
    return(level)
  }
}

// Get the fake buffer level in seconds
FakePlayer.prototype.getFakeBufferTime = function() {
  var perc = parseFloat(document.getElementsByClassName("bar-fill-fake")[0].style.width.replace('%','')) / 100
  if (!perc) {
    return(0)
  } else {
    var duration = this.flashPlayer.getDuration()
    return(duration * perc)
  }
}

// Set the fake buffering level to a specific percentage
FakePlayer.prototype.setFakeBufferLevel = function(perc) {
  document.getElementsByClassName("bar-fill-fake")[0].style.width = "" + perc + "%"
}

// Set the fake buffering level to a specific time
FakePlayer.prototype.setFakeBufferTime = function(time) {
  var duration = this.flashPlayer.getDuration()
  if (time > duration) {
    // cap at 100%
    time = duration
  }
  var perc = time / duration * 100
  document.getElementsByClassName("bar-fill-fake")[0].style.width = "" + perc + "%"
  this.fakeBufferLastUpdated = this.getCurrentWallTime()
}

// change to a specific QL with buffering or without if immediately == true
FakePlayer.prototype.setLevel = function(level, immediately) {
  if (immediately !== undefined) {
    immediately = true
  } else {
    immediately = false
  }
  this.levelSelector.setLevel(level, immediately)
}

// get the current QL
FakePlayer.prototype.getLevel = function() {
  return(this.levelSelector.getCurrentLevel)
}

// called when the level is changed
FakePlayer.prototype.onLevelChanged = function(level, previousLevel, immediately) {
  this.logger.log("Level changed from " + previousLevel + " to " + level + ", requesting immediately? " + immediately)

  var delay

  // immediate events are caused by predefined QL switches
  if (immediately) {
    self.eventLogger.saveEvent('system.player.qualitychange', level)
  } else {
    self.eventLogger.saveEvent('user.player.qualitychange', level)
  }

  // if a delay should be introduced
  if (!immediately) {
    // if changing to auto, treat like changing up
    if ((level == -1) || (level > previousLevel)) {
      delay = self.params.afterLevelChangeDelayUp
      self.stall(delay)
    } else if (level < previousLevel) {
      delay = self.params.afterLevelChangeDelayDown
      self.stall(delay)
    } else if (level == previousLevel) {
      // do nothing, level stays the same
    } else {
      this.logger.error("Can't figure out what to do with level change " + previousLevel + "->" + level)
    }
  }

  // reset fake buffer
  self.setFakeBufferTime(self.currentMediaTime)
  self.addTimer("FAKE_BUFFER_LEVEL_AFTER_LEVEL_CHANGE", function() {
    self.setFakeBufferTime(self.currentMediaTime + self.params.fakeBufferLength)
  }, delay)

}

// =============================================================================
// STALLING RELATED

// Create a fake stalling event for a given time (in seconds)
FakePlayer.prototype.stall = function(time, doNotResume) {
  //this.logger.log("stalling for " + time + " seconds")
  if (time <= 0) {
    return
  }
  this.buffer()
  self = this
  if (!doNotResume) {
    this.addTimer("RESUME_AFTER_STALLING", function() {
       self.resume()
    }, time)
  }
}

// Pause playback with buffering, indefinitely
FakePlayer.prototype.buffer = function() {
  this.isFakeBuffering = true
  this.hlsPlayback.setPlaybackState('FAKE_BUFFERING')
  self.eventLogger.saveEvent('system.player.stalling')
}

// Resume playback
FakePlayer.prototype.resume = function() {
  this.isFakeBuffering = false
  this.hlsPlayback.setPlaybackState('FAKE_RESUME')
  self.eventLogger.saveEvent('system.player.playing')
}

// get the media time for the next planned stalling event
FakePlayer.prototype.getNextPlannedStallingEventTime = function() {
  var sorted = this.plannedStallingEvents.sort(function(a, b) {
    return a[0] > b[0] ? 1 : -1
  })
  if (sorted.length > 0) {
    return sorted[0][0]
  } else {
    return undefined
  }
}


// =============================================================================
// HELPERS

// Helper function to allow extending an object
Object.extend = function(destination, source) {
    for (var property in source) {
        if (source.hasOwnProperty(property)) {
            destination[property] = source[property]
        }
    }
    return destination
};
