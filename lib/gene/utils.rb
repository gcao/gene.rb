module Gene
  module Utils
    require 'stringio'

    def silence_warnings
      old_stderr = $stderr
      $stderr = StringIO.new
      yield
    ensure
      $stderr = old_stderr
    end
  end
end