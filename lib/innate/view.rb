module Innate

  # This is a container module for wrappers of templating engines and handles
  # lazy requiring of needed engines.

  module View
    ENGINE, TEMP = {}, {}

    module_function

    def exts_of(engine)
      name = engine.to_s
      ENGINE.reject{|k,v| v != name }.keys
    end

    def render(ext, action, string)
      get(ext).render(action, string)
    end

    # Try to obtain given engine by its registered name.
    def get(engine_or_ext)
      return unless engine_or_ext
      eoe = Array[*engine_or_ext].first.to_s

      if klass = TEMP[eoe]
        return klass
      elsif klass = ENGINE[eoe]
        TEMP[eoe] = obtain(klass)
      else
        TEMP[eoe] = const_get(eoe)
      end
    end

    # We need to put this in a Mutex because simultanous calls for the same
    # class will cause race conditions and one call may return the wrong class
    # on the first request (before TEMP is set).
    # No mutex is used in Fiber environment, see Innate::State and subclasses.
    def obtain(klass)
      STATE.sync do
        obj = Object
        klass.split('::').each{|e| obj = obj.const_get(e) }
        obj
      end
    end

    # Register given templating engine wrapper and extensions for later usage.
    #
    # +name+ : the class name of the templating engine wrapper
    # +exts+ : any number of arguments will be turned into strings via #to_s
    #          that indicate which filename-extensions the templates may have.

    def register(klass, *exts)
      exts.each do |ext|
        ext = ext.to_s
        k = ENGINE[ext]
        Log.warn("overwriting %p which is set to %p already" % [ext, k]) if k
        ENGINE[ext] = klass
      end
    end

    # Combine Kernel#autoload and Innate::View::register

    def auto_register(name, *exts)
      autoload(name, "innate/view/#{name}".downcase)
      register("#{self}::#{name}", *exts)
    end

    auto_register :None, :css, :html, :htm
    auto_register :ERB,  :erb
  end
end
