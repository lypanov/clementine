module Clementine
  class ClementineRails < Rails::Engine
    initializer :register_clojurescript do |app|
      app.assets.register_engine '.cljs', ClojureScriptTemplate
    end
  end
end
