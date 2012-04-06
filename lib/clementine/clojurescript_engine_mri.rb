module Clementine

  # example
  #   Clementine.options = ":optimizations :whitespace"
  module Options
    attr_accessor :options, :clojurescript_path
  end
  extend Options

  class Error < StandardError; end

  class ClojureScriptEngine
    def initialize(file, options)
      @file = file
      @options = options
      # FIXME - ugly hack to override options
      @options = "'{:output-dir \"public/assets\" #{Clementine.options || ""}}'"
      @classpath = CLASSPATH + (Clementine.clojurescript_path || []).map { |path| File.expand_path path }
    end

    def compile
      puts "Compiling #{@file}"
      begin
        cmd = "#{command} #{@file} #{@options} 2>&1"
        result = `#{cmd}`
      rescue Exception
        raise Error, "compression failed: #{result}"
      end
      unless $?.exitstatus.zero?
        raise Error, result
      end
      result
    end

    def nailgun_prefix
      server_address = Nailgun::NailgunConfig.options[:server_address]
      port_no  = Nailgun::NailgunConfig.options[:port_no]
      "#{Nailgun::NgCommand::NGPATH} --nailgun-port #{port_no} --nailgun-server #{server_address}"
    end

    def setup_classpath_for_ng
      current_cp = `#{nailgun_prefix} ng-cp`
      unless current_cp.include? "clojure.jar"
        puts "Initializing nailgun classpath, required clementine dependencies missing"
        `#{nailgun_prefix} ng-cp #{@classpath.join " "}`
      end
    end

    def command
      if defined? Nailgun
        setup_classpath_for_ng
        [nailgun_prefix, 'clojure.main', "#{CLOJURESCRIPT_HOME}/bin/cljsc.clj"].flatten.join(' ')
      else
        ["java", '-cp', "\"#{@classpath.join ":"}\"", 'clojure.main', "#{CLOJURESCRIPT_HOME}/bin/cljsc.clj"].flatten.join(' ')
      end
    end
  end
end
