# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

APP_VERSION = `git describe --always` unless defined? APP_VERSION
APP_DATE = `git show -s --format=%ci`
