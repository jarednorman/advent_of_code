#!/usr/bin/env ruby

$LOAD_PATH << File.dirname(__FILE__)

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'minitest/pride'

require 'fileutils'
require 'erb'
require 'net/http'

require 'zeitwerk'

module AoC
  class << self
    def run(year, day, part)
      setup_zeitwerk

      Runner.new(year, day, part).call
    end

    private

    def setup_zeitwerk
      loader = Zeitwerk::Loader.new
      loader.push_dir(__dir__)
      loader.inflector.inflect("aoc" => "AoC")
      loader.setup
    end
  end

  class Runner
    def initialize(year, day, part)
      @day = day
      @year = year
      @part = part
    end

    def call
      if File.exist?(day_path)
        # This loads both parts, assuming they are in the same file.
        mod = AoC.const_get(day_const_string)

        Minitest.run

        klass = mod.const_get("Part#{part}")
        puts "\n\u001b[34mSolution for year #{year} day #{day} part #{part}: \u001b[31;1m#{klass.new.solution}\u001b[0m\n"
      else
        puts "Generating year #{year} day #{day}!"

        FileUtils.mkdir_p File.dirname(day_directory_path)

        generate_file(
          path: year_path,
          contents: year_renderer.result(binding)
        )

        generate_file(
          path: day_path,
          contents: day_renderer.result(binding)
        )

        generate_file(
          path: input_path,
          contents: input_data
        )
      end

      0
    end

    private

    attr_reader :day, :year, :part

    def generate_file(contents:, path:)
      File.write(path, contents) unless File.exist?(input_path)
    end

    def day_renderer
      ERB.new(File.read("brand_new_day.erb"))
    end

    def year_renderer
      ERB.new(File.read("month.erb"))
    end

    def year_path
      "aoc/year#{year}.rb"
    end

    def day_path
      "#{day_directory_path}.rb"
    end

    def input_path
      "#{day_directory_path}.txt"
    end

    def day_directory_path
      "aoc/year#{year}/day#{day_string}"
    end

    def day_string
      "%d" % [day]
    end

    def day_const_string
      "#{year_const_string}::Day#{day_string}"
    end

    def year_const_string
      "Year#{year}"
    end

    def input_data
      uri = URI("https://adventofcode.com/#{year}/day/#{day}/input")
      http = Net::HTTP.new(uri.host, 443)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.request_uri)
      request['Cookie'] = ENV.fetch('AOC_SESSION_COOKIE')
      response = http.request(request)
      response.body
    end
  end
end

raise "errrrror" if ARGV.length != 3
AoC.run(*ARGV.map(&:to_i))
