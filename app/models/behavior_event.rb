class BehaviorEvent < ActiveRecord::Base
  scope :next,      lambda {|id| where("id > ?",id).order("id ASC") } # this is the default ordering for AR
  scope :previous,  lambda {|id| where("id < ?",id).order("id DESC") }

  belongs_to :sequence_result

  serialize :value

  self.inheritance_column = nil

  ABBREVIATIONS = {
    # ignore for now:
    # "context.browser.windowsize" => "W",
    "user.mouse.clicked" => "C",
    "user.keyboard.keypress" => "K",
    "system.player.fullscreen" => "F",
    "user.player.seek" => "S",
    "context.browser.pagereloaded" => "R",
    "user.player.pause" => "P",
    "user.player.qualitychange" => "Q",
    "system.player.qualitychange" => "Qc",
    "system.player.stalling" => "St",
    "system.player.playing" => "Pl"
  }.freeze
end
