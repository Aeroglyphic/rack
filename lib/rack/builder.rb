module Rack
  class Builder
    def initialize(&block)
      @ins = []
      instance_eval(&block)
    end

    def use(middleware, *args)
      @ins << lambda { |app| middleware.new(app, *args) }
    end

    def run(app)
      @ins << app #lambda { |nothing| app }
    end

    def map(path, &block)
      if @ins.last.kind_of? Hash
        @ins.last[path] = Rack::Builder.new(&block).to_app
      else
        @ins << {}
        map(path, &block)
      end
    end

    def to_app
      @ins[-1] = Rack::URLMap.new(@ins.last)  if Hash === @ins.last
      inner_app = @ins.pop
      @ins.reverse.inject(inner_app) { |a, e| e.call(a) }
    end

    def call(env)
      to_app.call(env)
    end
  end
end
