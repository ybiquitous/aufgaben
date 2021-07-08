module Aufgaben
  class Color
    def self.enabled?
      $stdout.tty?
    end

    def initialize(text)
      @text = text
    end

    def green
      if self.class.enabled?
        "\e[32m#{@text}\e[0m"
      else
        @text
      end
    end
  end
end
