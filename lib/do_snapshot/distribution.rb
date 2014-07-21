# -*- encoding : utf-8 -*-
module DoSnapshot
  # Distributive files
  # Used part of Heroku script https://github.com/heroku/heroku
  #
  module Distribution
    def self.files
      Dir[File.expand_path('../../../{bin,lib}/**/*', __FILE__)].select do |file|
        File.file?(file)
      end
    end
  end
end
