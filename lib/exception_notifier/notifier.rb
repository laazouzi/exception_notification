require 'pp'

class ExceptionNotifier
  class Notifier < ActionMailer::Base

    class << self
      attr_writer :default_sections
      attr_writer :default_background_sections
      

      def default_sections
        @default_sections || %w(request session environment backtrace)
      end

      def default_background_sections
        @default_background_sections || %w(backtrace data)
      end

      def default_options
        { :sections => default_sections,
          :background_sections => default_background_sections }
      end

    end

    class MissingController
      def method_missing(*args, &block)
      end
    end

    def exception_notification(env, exception, options={})
      #raise exception if Rails.env.development?

      @env        = env
      @exception  = exception
      @options    = (env['exception_notifier.options'] || {}).reverse_merge(self.class.default_options)
      @kontroller = env['action_controller.instance'] || MissingController.new
      @request    = ActionDispatch::Request.new(env)
      @backtrace  = exception.backtrace ? clean_backtrace(exception) : []
      @sections   = @options[:sections]
      @data       = (env['exception_notifier.exception_data'] || {}).merge(options[:data] || {})
      @sections   = @sections + %w(data) unless @data.empty?

      @data.each do |name, value|
        instance_variable_set("@#{name}", value)
      end
      
      log_exception(@exception, @backtrace, @kontroller)
    end

    def background_exception_notification(exception, options={})
      #raise exception if Rails.env.development?
      if @notifier = Rails.application.config.middleware.detect{ |x| x.klass == ExceptionNotifier }
        @options   = (@notifier.args.first || {}).reverse_merge(self.class.default_options)
        @exception = exception
        @backtrace = exception.backtrace || []
        @sections  = @options[:background_sections]
        @data      = options[:data] || {}

        @data.each do |name, value|
          instance_variable_set("@#{name}", value)
        end
        
        log_exception(@exception, @backtrace)
      end
    end

    private

    def log_exception(exception, backtrace, kontroller=nil)
      if kontroller.present?
        ExceptionLog.create(:controller => kontroller.controller_name, :action => kontroller.action_name, :name => exception.class.to_s, :message => exception.message, :backtrace => backtrace)
      else
        ExceptionLog.create(:name => exception.class.to_s, :message => exception.message, :backtrace => backtrace)
      end
    end

    def clean_backtrace(exception)
      if Rails.respond_to?(:backtrace_cleaner)
       Rails.backtrace_cleaner.send(:filter, exception.backtrace)
      else
       exception.backtrace
      end
    end

    helper_method :inspect_object

    def inspect_object(object)
      case object
      when Hash, Array
        object.inspect
      when ActionController::Base
        "#{object.controller_name}##{object.action_name}"
      else
        object.to_s
      end
    end
  end
end
