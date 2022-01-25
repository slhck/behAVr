require 'csv'

# BEGIN: monkey patch
# https://gist.github.com/christiangenco/8acebde2025bf0891987
class Array
  def to_csv(csv_filename="hash.csv")
    require 'csv'
    CSV.open(csv_filename, "wb") do |csv|
      csv << first.keys # adds the attributes name on the first line
      self.each do |hash|
        csv << hash.values
      end
    end
  end
end
# END: monkey patch

namespace :behavr do
  desc "Export data to CSV files"
  task :export_data => :environment do
    Experiment.all.each do |exp|
      exp_name_prefix = exp.name.sub(' ', '_').downcase
      output_path = Rails.root.join('db', 'exports', exp_name_prefix)
      puts "Exporting data to #{output_path}"
      if not Dir.exists?(output_path)
        FileUtils.mkdir_p(output_path)
      end

      # collect data
      csv_data = {}
      csv_data["seq_results"] = []
      csv_data["events"]      = []
      csv_data["rating"]      = []

      exp.experiment_progresses.completed.order(:created_at).each do |experiment_progress|

        # iterate over all sequence results
        experiment_progress.sequence_results.order(:created_at).each do |sequence_result|

          # general data
          csv_data["seq_results"] << {
            experiment:           exp.id,
            subject:              experiment_progress.user.email.gsub("@example.com", ""),
            sequence_result_id:   sequence_result.id,
            created_at:           sequence_result.created_at.strftime('%Y-%m-%dT%H:%M:%S.%L%z'),
            cond_id:              sequence_result.test_sequence.condition.cond_id,
            src_id:               sequence_result.test_sequence.source_video.src_id,
            src_name:             sequence_result.test_sequence.source_video.name,
            params:               sequence_result.test_sequence.condition.player_params.to_json,
            ratings:              sequence_result.ratings.count,
            clicks:               sequence_result.behavior_events.where(type: 'user.mouse.clicked').count,
            seeks:                sequence_result.behavior_events.where(type: 'user.player.seek').count,
            fullscreen:           sequence_result.behavior_events.where(type: 'system.player.fullscreen').count,
            pauses:               sequence_result.behavior_events.where(type: 'user.player.pause').count,
            times_reloaded:       sequence_result.times_reloaded,
            behavior_events_list: sequence_result.behavior_events_list
          }

          # iterate over ratings
          sequence_result.ratings.includes(:rating_prototype).each do |rating|
            #ratings.order("rating_prototypes.order").each do |rating|
              csv_data["rating"] << {
                experiment:         exp.id,
                subject:            experiment_progress.user.email.gsub("@example.com", ""),
                sequence_result_id: sequence_result.id,
                created_at:         sequence_result.created_at.strftime('%Y-%m-%dT%H:%M:%S.%L%z'),
                question:           rating.rating_prototype.question,
                answer_type:        rating.rating_prototype.answer_type,
                answer:             rating.answer
              }
            #end
          end


          # iterate over all behavior events in that sequence shown
          sequence_result.behavior_events.order(:client_time).each do |behavior_event|

            # get previous event to calculate relative time
            previous = sequence_result.behavior_events.order(:client_time).previous(behavior_event.id)
            if previous.any?
              offset = (behavior_event.client_time - previous.last.client_time).round(3)
            else
              offset = 0.0
            end

            csv_data["events"] << {
              experiment:         exp.id,
              subject:            experiment_progress.user.email.gsub("@example.com", ""),
              sequence_result_id: sequence_result.id,
              timestamp:          behavior_event.client_time.strftime('%Y-%m-%dT%H:%M:%S.%L%z'),
              offset:             offset,
              type:               behavior_event.type,
              value:              behavior_event.value
            }
          end # each behavior event
        end # each sequence result
      end # each progress

      # write to CSV
      csv_data.each do |key, val|
        of = File.join(output_path, "#{exp_name_prefix}-#{key}.csv")
        val.to_csv(of)
        puts "Data written to #{of}"
      end

    end # each experiment

  end

  desc "Import fake-player and clappr JS files from fake-player repo"
  task :import_player => :environment do
    vendor_js_path     = Rails.root.join('vendor', 'assets', 'javascripts')
    public_assets_path = Rails.root.join('public', 'assets')
    if ARGV.length > 1
      root_dir = ARGV.pop
    else
      root_dir = "#{Dir.home}/Documents/Projects/fake-player"
    end
    if not Dir.exists? root_dir
      puts "Error: directory #{root_dir} does not exist"
    end
    puts "Importing fake-player from #{root_dir} ..."

    js_files = %w(
      clappr/dist/clappr.js
      clappr-level-selector-plugin/dist/level-selector.js
      fake-player/src/browser-event-logger.js
      fake-player/src/fake-player.js
      fake-player/src/logger.js
    )

    asset_path = "clappr/dist/assets"

    js_files.each do |f|
      src = File.join(root_dir, f)
      puts "Copying #{src}"
      FileUtils.copy(src, vendor_js_path)
    end

    Dir.glob(File.join(root_dir, asset_path, '/*')) do |src|
      puts "Copying #{src}"
      FileUtils.copy(src, public_assets_path)
    end
  end

  desc "Attach thumbnails"
  task :attach_thumbnails => :environment do
    SourceVideo.all.each_with_index do |s, index|
      puts "Adding thumbnails for source #{s.src_id} (#{index + 1}/#{SourceVideo.count})"
      s.attach_thumbnails
    end
  end

  desc "Add users manually to experiment"
  task :manually_add_users => :environment do

    # insert IDs here:
    # new_user_ids = [1855, 1567, 2977, 3457, 7928, 6728, 4971, 3742, 1418, 8120, 6065, 4666, 0350, 4176, 1611, 9572, 1505, 8699, 4406, 8675, 1630, 2873, 6162, 3067, 2915, 4442, 4704, 3429, 0464 ]
    new_user_ids = [9999]

    users = []

    new_user_ids.each do |id|
      begin
        u = User.create!({ email: id.to_s + "@example.com", password: "password", locale: "de" })
        users << u
        puts "[added subject:id}]"
      rescue Exception => e
        puts "error adding user #{id}: #{e}".red
      end
    end

    users.each do |user|
      Experiment.first.users << user
    end

    counter = /[a-z]?+(\d+)/.match(TestSequence.last.sequence_id).captures.first.to_i + 1

    users.each do |user|
      # run through source list
      Experiment.first.source_videos.each do |src|

        test_sequence_id = "SEQ" + ("%05d" % counter)

        t = TestSequence.new
        t.sequence_id  = test_sequence_id
        t.experiment   = Experiment.first
        t.source_video = src

        # only add reference condition now, add them on-demand later
        t.condition    = Condition.find_by cond_id: "HRC01"

        if t.save
          puts "[added sequence #{t.sequence_id}]"
          counter += 1
        else
          puts "[error]"
          t.errors.full_messages.each do |msg|
            puts "\t" + msg.red
          end
        end

        user.test_sequences << t
        user.save
      end
    end
  end
end
