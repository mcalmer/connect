require 'optparse'
require 'suse/connect'

module SUSE
  module Connect
    # Command line interface for interacting with SUSEConnect
    class Cli

      attr_reader :options

      def initialize(argv)
        @options = {}
        extract_options
      end

      def execute! # rubocop:disable MethodLength
        Logger.info(@options) if @options[:verbose]
        Client.new(@options).execute!
      rescue CannotBuildTokenAuth
        Logger.error 'no registration token provided'
        exit 1
      rescue TokenNotPresent
        puts @opts
      rescue ApiError => e
        Logger.error "ApiError with response: #{e.body} Code: #{e.code}"
        exit 1
      rescue Errno::ECONNREFUSED
        Logger.error 'connection refused by server'
        exit 1
      rescue JSON::ParserError
        Logger.error 'cannot parse response from server'
        exit 1
      rescue Errno::EACCES
        Logger.error 'access error - cannot create required folder/file'
        exit 1
      end

      private

      def extract_options # rubocop:disable MethodLength

        @opts = OptionParser.new

        @opts.banner = 'SUSEConnect is a command line tool for connecting a client system to the SUSE Customer Center.'
        @opts.separator 'It will connect the system to your product subscriptions and enable the product ' \
                        'repositories/services locally.'
        @opts.separator ''
        @opts.separator 'Please visit https://scc.suse.com to see and manage your subscriptions.'
        @opts.separator ''
        @opts.separator 'Usage: SUSEConnect [options]'

        @opts.on('-r', '--regcode [REGCODE]', 'Registration code. The repositories of the subscription with this ' \
                                              'registration code will get activated on this system.') do |opt|
          check_if_param(opt, 'Please provide a registration code parameter')
          @options[:token] = opt
        end

        @opts.on('-k', '--insecure', 'Skip SSL verification (insecure).') do |opt|
          @options[:insecure] = opt
        end

        @opts.on('--url [URL]', 'Connection base url (e.g. https://scc.suse.com).') do |opt|
          check_if_param(opt, 'Please provide url parameter')
          @options[:url] = opt
        end

        @opts.separator ''
        @opts.separator 'Common options:'

        @opts.on('-d', '--dry-mode', 'Dry mode. Does not make any changes to the system.') do |opt|
          @options[:dry] = opt
        end

        @opts.on('--version', 'Print version') do
          puts VERSION
          exit
        end

        @opts.on('-h', '--help', 'Show this message.') do
          puts @opts
          exit
        end

        @opts.on('-v', '--verbose', 'Run verbosely.') do |opt|
          @options[:verbose] = opt
        end

        @opts.parse!

      end

      def check_if_param(opt, message)
        unless opt
          puts message
          exit 1
        end
      end

    end
  end
end
