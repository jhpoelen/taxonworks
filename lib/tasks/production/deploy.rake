require 'rake'
require 'benchmark'

namespace :tw do
  namespace :production do
    namespace :deploy do

      task :foo do 
        raise TaxonWorks::Error, "asdf"
      end

      task :bar => [:environment] do
        begin 
          Rake::Task["tw:production:deploy:foo"].invoke
        rescue TaxonWorks::Error
          puts "REEEET REEEET REEET"
        end
      end

      # Called from within Dockerfile.  The database must exist before this point!
      desc 'A database deployment strategy for Docker/Kubernetes.'
      task :update_database => [:environment, :db_user, :backup_directory, :check_for_database] do

        # Result is 
        #   0 - full deploy passed 
        #   1 (non zero) - error, database is unchanged from prior attempt, triggered with raise()
        #

        # Stage 0 - test config, abort if something doesn't jive (subtask)

        # Stage 1, the backup 
        # Backup the database (always, regardless of whether there are migrations)
        # Aborts the whole process if data can not be dumped 
        Rake::Task["tw:db:dump"].invoke

        begin
          # Stage 2, the migrations
          Rake::Task["db:migrate"].invoke
        rescue
          # Stage 3, migration failed, restore from last.
          Rake::Task["db:restore_last"].invoke
          raise TaxonWorks::Error, "Unable to migrate, restored from #{ENV['file']}."
        end
      end

      # Stage 4, success
      puts Rainbow("Successfully updated database").green
      true 
    end
  end
end