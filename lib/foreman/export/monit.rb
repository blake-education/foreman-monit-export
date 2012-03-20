require 'foreman/export'
require 'foreman/cli'

module Foreman
  module Export
    class Monit < Foreman::Export::Base
      attr_reader :pid, :check

      def self.template_root
        @template_root ||= File.expand_path('../../data/templates', __FILE__)
      end

      def initialize(location, engine, options={})
        super
        @pid = options[:pid]
        @check = options[:check]
      end

      def export
        error("Must specify a location") unless location

        FileUtils.mkdir_p location

        @app ||= File.basename(engine.directory)
        @user ||= app
        @log = File.expand_path(@log || "/var/log/#{app}")
        @pid = File.expand_path(@pid || "/var/run/#{app}")
        @check = File.expand_path(@check || "/var/lock/subsys/#{app}")
        @location = File.expand_path(@location)

        engine.procfile.entries.each do |process|
          wrapper_template = export_template("monit", "wrapper.sh.erb", self.class.template_root)
          wrapper_config   = ERB.new(wrapper_template, 0, "-").result(binding)
          write_file wrapper_path_for(process), wrapper_config
          FileUtils.chmod 0755, wrapper_path_for(process)
        end

        monitrc_template = export_template("monit", "monitrc.erb", self.class.template_root)
        monitrc_config   = ERB.new(monitrc_template, 0, "-").result(binding)
        write_file "#{location}/#{app}.monitrc", monitrc_config
      end

      def wrapper_path_for(process)
        File.join(location, "#{app}-#{process.name}.sh")
      end

      def pid_file_for(process, num)
        File.join(pid, "#{process.name}-#{num}.pid")
      end

      def log_file_for(process, num)
        File.join(log, "#{process.name}-#{num}.log")
      end

      def check_file_for(process)
        File.join(check, "#{process.name}.restart")
      end
    end
  end
end