require 'tilt/template'
require 'sprockets/errors'

module Clementine
  class ClojureScriptTemplate < Tilt::Template
    self.default_mime_type = 'application/javascript'

    def self.engine_initialized?
      true
    end

    def initialize_engine; end

    def prepare
      @engine = ClojureScriptEngine.new(@file, options)
    end

    def our_file? context, file
      begin
        context.resolve(file)
      rescue Sprockets::FileNotFound => e
        nil
      end
    end

    def evaluate(context, locals, &block)
      @output ||= @engine.compile
      unless Clementine.options.include? ":optimizations"
        @output.each_line {
          |line|
          subline = line.slice("goog.addDependency(\"../".length..-1)
          dep = subline.slice(0...(subline.index('"')))
          resolved_dep = our_file?(context, dep)
          if resolved_dep
            context.depend_on resolved_dep
          end
        }
      end
      @output
    end
  end
end
