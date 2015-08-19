require "veto"
require "reform/validation"

# Implements ::validates and friends, and #valid?.
module Reform::Form::Veto
  module Validations
    def build_errors
      Errors.new
    end

    module ClassMethods
      def validation_group_class
        Group
      end
    end

    def self.included(includer)
      includer.extend(ClassMethods)
    end

    class Group
      def initialize
        @validator = Class.new(Validator)
      end

      def validates(*args, &block)
        @validator.validates(*args, &block)
      end
      def validate(*args, &block)
        @validator.validate(*args, &block)
      end

      def call(fields, errors, form) # FIXME.
        validator = @validator.new# TODO new(errors)

        validator.valid?(form) # TODO: OpenStruct.new(@fields)


        validator.errors.each do |name, error| # TODO: handle with proper merge, or something. validator.errors is ALWAYS AM::Errors.
          puts "@@@@@ #{error.inspect}"

          error.each { |message| errors.add(name, message) }
        end
      end
    end

    require "veto"
    class Validator
      include Veto.validator
    end
  end

  class Errors
    extend Uber::Delegates

    def initialize(*args)
      @lotus_errors = Veto::Errors.new(*args)
    end

    delegates :@lotus_errors, :clear, :add, :empty?

    def each(&block)
      @lotus_errors.each(&block)
    end

    def merge!(errors, prefix)
      errors.each do |name, err|
        field = (prefix+[name]).join(".").to_sym

        next if @lotus_errors[field].any?

        @lotus_errors.add(field, *err) # TODO: use namespace feature in Lotus here!
      end
    end

    def messages
      return @lotus_errors.full_messages
      errors = {}
      @lotus_errors.instance_variable_get(:@errors).each do |name, err|
        errors[name] ||= []
        errors[name] += err.map(&:to_s)
      end
      errors
    end

    # needed in simple_form, etc.
    def [](name)
      @lotus_errors.for(name)
    end
  end
end
