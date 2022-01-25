/*
Simple logging class
*/
var Logger = function(log) {
  this.prefix = "[fakeplayer]"
  this.logMessages = log
}

Logger.prototype.log = function(message) {
  if (this.logMessages)
    console.log(this.prefix + " " + message)
}

Logger.prototype.warn = function(message) {
  if (this.logMessages)
    console.warn(this.prefix + " " + message)
}

Logger.prototype.error = function(message) {
  if (this.logMessages)
    console.error(this.prefix + " " + message)
}
