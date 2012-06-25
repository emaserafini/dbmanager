require 'time'

module Dbmanager
  module Adapters
    module Mysql
      class Connection
        attr_reader :environment

        delegate :host, :adapter, :database, :username, :password, :ignoretables,
                 :encoding, :protected, :name, :port , :to => :environment

        def initialize(environment)
          @environment = environment
        end

        def params
          "-u#{username} #{flag :password, :p} #{flag :host, :h} #{flag :port, :P} #{database}"
        end

        def ignore_tables
          if ignoretables.present?
            ignoretables.inject('') do |s, view|
              s << " --ignore-table=#{database}.#{view}"
            end
          end
        end

        def flag(name, flag)
          send(name).present? ? "-#{flag}#{send(name)}" : ''
        end

        def protected?
          if name =~ /production/
            protected != false
          else
            protected == true
          end
        end
      end

      class Dumper
        attr_reader :source, :filename

        def initialize(source, filename)
          @source   = source
          @filename = filename
        end

        def run
          Dbmanager.execute! dump_command
        end

        def dump_command
          "mysqldump #{source.params} #{source.ignore_tables} > #{filename}"
        end
      end

      class Importer
        attr_reader :source, :target

        def initialize(source, target)
          @source = source
          @target = target
        end

        def run
          Dumper.new(source, temp_file).run
          Dbmanager.execute! import_command
          remove_temp_file
        end

        def import_command
          "mysql #{target.params} < #{temp_file}"
        end

        def remove_temp_file
          Dbmanager.execute "rm #{temp_file}"
        end

        def temp_file
          @temp_file ||= "/tmp/#{Time.now.strftime '%y%m%d%H%M%S'}"
        end
      end
    end
  end
end
