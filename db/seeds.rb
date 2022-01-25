# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Thumbnail.destroy_all

DatabaseCleaner.clean_with :truncation

%w( experiments videos conditions users ).each do |f|
    Settings.add_source! Rails.root.join("config/behavr/#{f}.yml").to_s
end
Settings.reload!

# Import experiments from YML file
def add_experiments
  puts "[info]\tImporting experiments from config/behavr/experiments.yml ..."
  Settings.experiments.each do |exp|
    e = Experiment.new(
      name:                  exp.name,
      active:                exp.active,
      access_key:            exp.access_key,
      finish_key:            exp.finish_key,
      test_sequence_mapping: exp.test_sequence_mapping,
      finish_condition:      exp.finish_condition
    )

    if exp.reference_condition
      e.reference_condition = exp.reference_condition
    end

    e.attributes = {
      locale:             :en,
      description:        exp.description_en,
      introduction:       exp.introduction_en,
      main_instructions:  exp.main_instructions_en,
      outro:              exp.outro_en
    }

    e.attributes = {
      locale:             :de,
      description:        exp.description_de,
      introduction:       exp.introduction_de,
      main_instructions:  exp.main_instructions_de,
      outro:              exp.outro_de
    }

    if e.save
      puts "[info]\t--> Experiment '#{exp.name}' imported"
    else
      puts "[error]\tExperiment '#{exp.name}' could not be saved because:".red
      e.errors.full_messages.each do |msg|
        puts "\t" + msg.red
      end
    end

    # Add rating prototypes to this experiment
    if exp.rating_prototypes
      exp.rating_prototypes.each do |rating_prototype|

        rp = RatingPrototype.new(
          answer_type: rating_prototype.answer_type,
          required: rating_prototype.required,
          order: rating_prototype.order,
          experiment: e
        )
        rp.attributes = {
          locale: :en,
          question: rating_prototype.question_en,
        }
        rp.attributes = {
          locale: :de,
          question: rating_prototype.question_de,
        }

        if rp.save
          puts "[info]\t--> Rating Prototype with type '#{rating_prototype.answer_type}' imported"
        else
          puts "[error]\t Rating Prototype could not be saved because:".red
          rp.errors.full_messages.each do |msg|
            puts "\t" + msg.red
          end
        end

      end
    end

  end
end

# Import SRC videos from YML file
def add_videos
  puts "[info]\tImporting videos from config/behavr/videos.yml ..."
  Settings.videos.each do |video|
    v = SourceVideo.new
    v.attributes = {
      src_id: video.src_id,
      duration: video.duration
    }
    v.attributes = {
      locale:           :en,
      name:             video.name_en,
      description:      video.description_en,
      content_question: video.content_question_en
    }
    v.attributes = {
      locale:           :de,
      name:             video.name_de,
      description:      video.description_de,
      content_question: video.content_question_de
    }
    if v.save
      puts "[info]\t--> Video '#{video.src_id}' imported with #{v.thumbnails.length} thumbnails"
    else
      puts "[error]\tVideo '#{video.src_id}' could not be saved because:".red
      v.errors.full_messages.each do |msg|
        puts "\t" + msg.red
      end
    end
  end
end

# Import conditions from YML file
def add_conditions
  puts "[info]\tImporting conditions from config/behavr/conditions.yml ..."
  Settings.conditions.each do |cond|
    c = Condition.new
    c.attributes = {
      cond_id: cond.cond_id,
      player_params: cond.player_params
    }
    if c.save
      puts "[info]\t--> Condition '#{c.cond_id}' imported"
    else
      puts "[error]\tCondition '#{c.cond_id}' could not be saved because:".red
      c.errors.full_messages.each do |msg|
        puts "\t" + msg.red
      end
    end
  end
end

# Import users from YML file
def add_users
  puts "[info]\tImporting users from config/behavr/users.yml ..."
  Settings.users.each do |user|
    u = User.new

    u.attributes = {
      name:     user.name,
      email:    user.email,
      password: user.password,
      admin:    user.admin,
      locale:   user.locale
    }

    if u.save
      puts "[info]\t--> User #{user.email} imported"
    else
      puts "[error]\tUser '#{user.email}' could not be saved because:".red
      u.errors.full_messages.each do |msg|
        puts "\t" + msg.red
      end
    end
  end
end

# Assign all the videos named in experiment descriptions via ActiveRecord
def assign_videos
  Settings.experiments.each do |exp|
    e = Experiment.find_by name: exp.name
    next if not e
    exp.source_videos.each do |srcid|
      v = SourceVideo.find_by src_id: srcid
      if v
        v.experiments << e
        v.save
      else
        puts "[error]\tExperiment '#{exp.name}' requires video with ID #{srcid} but none exists. Is it added to videos.yml?".red
      end
    end
  end
end

# Assign all the conditions named in experiment descriptions via ActiveRecord
def assign_conditions
  Settings.experiments.each do |exp|
    e = Experiment.find_by name: exp.name
    next if not e
    exp.conditions.each do |condid|
      c = Condition.find_by cond_id: condid
      if c
        c.experiments << e
        c.save
      else
        puts "[error]\tExperiment '#{exp.name}' requires condition with ID #{condid} but none exists. Is it added to conditions.yml?".red
      end
    end
  end
end

# Assign all the test sequences named in experiment descriptions via ActiveRecord
# or randomly assign them to every user.
def assign_test_sequences
  puts "[info]\tAdding sequences from config/behavr/experiments.yml ..."
  Settings.experiments.each do |exp|
    e = Experiment.find_by name: exp.name
    next if not e

    if exp.test_sequence_mapping == "manual"
      next if not exp.test_sequences

      # generate test sequences
      exp.test_sequences.each do |test_sequence|
        if test_sequence.length != 3
          puts "[error]\tNeed Sequence ID, Source ID and Condition ID in test sequence specification. #{test_sequence} does not conform.".red
          next
        end
        test_sequence_id, src_id, cond_id = test_sequence

        t              = TestSequence.new
        t.sequence_id  = test_sequence_id
        t.experiment   = e
        t.source_video = SourceVideo.find_by src_id: src_id
        t.condition    = Condition.find_by cond_id: cond_id

        if t.save
          puts "[info]\t--> Sequence '#{t.sequence_id}' (Source: '#{src_id}', Condition: '#{cond_id}') added"
        else
          puts "[error]\tSequence '#{t.sequence_id}' could not be saved because:".red
          t.errors.full_messages.each do |msg|
            puts "\t" + msg.red
          end
        end

        # add test sequence for every user in this experiment
        e.users.each do |user|
          user.test_sequences << t
          user.save
        end
      end

    elsif exp.test_sequence_mapping == "random"
      counter = 1
      if not exp.reference_condition
        raise "Experiment does not define reference condition"
      end

      # for every user, there's a new mapping
      e.users.each do |user|
        condition_ids       = exp.conditions.shuffle
        condition_ids.delete exp.reference_condition

        # run through randomized source list
        exp.source_videos.shuffle.each do |src_id|
          # assign random condition ID
          cond_id = condition_ids.shift
          # if nil, just use reference condition
          cond_id = exp.reference_condition if not cond_id

          test_sequence_id = "SEQ" + ("%05d" % counter)

          t = TestSequence.new
          t.sequence_id  = test_sequence_id
          t.experiment   = e
          t.source_video = SourceVideo.find_by src_id: src_id
          t.condition    = Condition.find_by cond_id: cond_id

          if t.save
            puts "[info]\t--> For user #{user.id}, sequence '#{t.sequence_id}' (Source: '#{src_id}', Condition: '#{cond_id}') added"
            counter += 1
          else
            puts "[error]\tSequence '#{t.sequence_id}' could not be saved because:".red
            t.errors.full_messages.each do |msg|
              puts "\t" + msg.red
            end
          end

          user.test_sequences << t
          user.save
        end
      end

    elsif exp.test_sequence_mapping == "random_live"
      counter = 1
      if not exp.reference_condition
        raise "Experiment does not define reference condition"
      end

      # for every user
      e.users.each do |user|
        # run through source list
        e.source_videos.each do |src|

          test_sequence_id = "SEQ" + ("%05d" % counter)

          t = TestSequence.new
          t.sequence_id  = test_sequence_id
          t.experiment   = e
          t.source_video = src

          # only add reference condition now, add them on-demand later
          t.condition    = Condition.find_by cond_id: exp.reference_condition

          if t.save
            puts "[info]\t--> For user #{user.id}, sequence '#{t.sequence_id}' (Source: '#{src.id}', Condition: '#{exp.reference_condition}') added"
            counter += 1
          else
            puts "[error]\tSequence '#{t.sequence_id}' could not be saved because:".red
            t.errors.full_messages.each do |msg|
              puts "\t" + msg.red
            end
          end

          user.test_sequences << t
          user.save
        end
      end

    else
     raise "I don't know what mapping '#{exp.test_sequence_mapping}' is"
    end
  end
end


add_videos
add_conditions
add_experiments
add_users
assign_videos
assign_conditions
assign_test_sequences

puts "[info]\tImporting data finished".green
