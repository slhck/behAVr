# behAVr

Contents:

- [behAVr](#behavr)
  - [Requirements](#requirements)
  - [Setup](#setup)
    - [Creating Videos](#creating-videos)
    - [Database Setup](#database-setup)
    - [PostgreSQL](#postgresql)
      - [MySQL](#mysql)
    - [Configuring](#configuring)
  - [Running](#running)
  - [Exporting Results](#exporting-results)
  - [License](#license)

Audiovisual quality and behavior measurement tool for subjective tests, written in Ruby on Rails.

:warning: This tool uses a modified version of the [Clappr player](https://github.com/clappr/clappr). It works with Flash only, since that was the technology chosen at the time of developing this tool.

## Requirements

* Ruby 2.7.5 (not tested with 3.x) via rbenv
* PostgreSQL 9.5.0 or above, or MySQL
* Google Chrome v46 or something older (to make Flash work reliably)

## Setup

### Creating Videos

Videos have to be placed in `public/videos/<srdId>`, where `<srcId>` is some alphanumeric key identifying the video uniquely. In that folder, there must be one file called `<srcId>.m3u8` – the HLS playlist.

To create videos, use ffmpeg's HLS segmenter. For example:

```bash
cat <<EOF > src01.m3u8
#EXTM3U
#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=500000,RESOLUTION=480x270
ts/480x270.m3u8
#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=1000000,RESOLUTION=640x360
ts/640x360.m3u8
#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=2000000,RESOLUTION=1280x720
ts/1280x720.m3u8
EOF

mkdir ts
ffmpeg -y -i input.mp4 -c:a aac -strict experimental -ac 2 -b:a 64k -ar 44100 -c:v libx264 -pix_fmt yuv420p -x264opts keyint=12:min-keyint=12:scenecut=-1 -profile:v baseline -level 21 -b:v 100K -r 12 -g 36 -f hls -hls_time 1 -hls_list_size 0 -s 480x270 ts/480x270.m3u8
ffmpeg -y -i input.mp4 -c:a aac -strict experimental -ac 2 -b:a 96k -ar 44100 -c:v libx264 -pix_fmt yuv420p -x264opts keyint=24:min-keyint=24:scenecut=-1 -profile:v baseline -level 31 -b:v 300K -r 24 -g 72 -f hls -hls_time 1 -hls_list_size 0 -s 640x360 ts/640x360.m3u8
ffmpeg -y -i input.mp4 -c:a aac -strict experimental -ac 2 -b:a 96k -ar 44100 -c:v libx264 -pix_fmt yuv420p -x264opts keyint=24:min-keyint=24:scenecut=-1 -profile:v main -level 32 -b:v 1000K -r 24 -g 72 -f hls -hls_time 1 -hls_list_size 0 -s 1280x720 ts/1280x720.m3u8
```

Thumbnails have to be put in `thumbnails`, a subfolder of each video folder. Thumbnails, e.g. every 10 seconds, can be generated with:

```bash
ffmpeg -i /path/to/input.mp4 -vf fps=1/10 thumbnails/%04d.png
```

### Database Setup

Depending on the database adapter used, change your settings in `config/database.yml`.

### PostgreSQL

After installing PostgreSQL, add a user with database creation rights:

```sql
create role behavr with createdb login password 'behavr';
```

Change the details as necessary in the command and in the `conig/database.yml` file.

#### MySQL

Run the following after installing MySQL from a root commandline:

```sql
CREATE USER 'behavr'@'localhost' IDENTIFIED BY 'behavr';
CREATE DATABASE IF NOT EXISTS behavr_development;
CREATE DATABASE IF NOT EXISTS behavr_production;
GRANT ALL ON behavr_development.* TO 'behavr'@'localhost';
GRANT ALL ON behavr_production.* TO 'behavr'@'localhost';
```

### Configuring

- To add experiments, modify the `config/experiments.yml` file.
- Add videos in the `config/videos.yml` file.
- Add conditions in the `config/conditions.yml` file.
- To add users, modify the `config/users.yml` file.

Some notes:

- With the `manual` condition assignment, you have to specify the test sequences manually. With `random`, every user will get a different set of test sequences assigned, by taking one HRC after the other and randomly assigning it to a SRC. In the latter case, you can specify a `reference_condition` that should be shown for all sequences.
- Each user will be assigned to each experiment automatically.

Then, when you run `rake db:seed`, the data from these files will be imported.

## Running

To start in dev mode:

- Install Ruby
- Install Bundler with `gem install bundler`
- Run `bundle install` in this folder
- Run the migrations with `rake db:migrate`
- Run the seeds with `rake db:seed`
- Run the server with `foreman start`
- Browse to `localhost:5000`

Log in with the email of the test users, as specified in the `users.yml` file.

If you are test user and you have been assigned experiments, you can join and run the experiments.

If you are an admin, you can navigate to `http://localhost:5001/admin/index` to see an overview of the results.

## Exporting Results

This creates CSV export files. Run:

```
bundle exec rake behavr:export_data 
```

## License

Copyright 2014-2022 Werner Robitza

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
