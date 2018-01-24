# frozen_string_literal: true

module Geet
  module Services
    class CreateLabel
      def initialize(repository)
        @repository = repository
      end

      def execute(name, color: generate_random_color, output: $stdout)
        label = create_label(name, color, output)

        output.puts "Created with color ##{label.color}"

        label
      end

      private

      def create_label(name, color, output)
        output.puts 'Creating label...'

        @repository.create_label(name, color)
      end

      # Return a 6-digits hex random color.
      def generate_random_color
        hex_number = rand(2**24).to_s(16)

        hex_number.rjust(6, '0')
      end
    end
  end
end
