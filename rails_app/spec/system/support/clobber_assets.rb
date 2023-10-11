# frozen_string_literal: true

# Clobber assets after running system tests to ensure development environment
# dynamically generates assets
RSpec.configure do |config|
  config.after(:suite) do
    examples = RSpec.world.filtered_examples.values.flatten
    has_no_system_tests = examples.none? { |example| example.metadata[:type] == :system }

    if has_no_system_tests
      $stdout.puts "\n🚀️️  No system test selected. Skip clobbering assets.\n"
      next
    end

    $stdout.puts "\n🔨  Clobbering assets.\n"

    original_stdout = $stdout.clone

    start = Time.current
    begin
      $stdout.reopen(File.new('/dev/null', 'w'))

      require 'rake'
      Rails.application.load_tasks
      Rake::Task['assets:clobber'].invoke
    ensure
      $stdout.reopen(original_stdout)
      $stdout.puts "Finished in #{(Time.current - start).round(2)} seconds"
    end
  end
end
