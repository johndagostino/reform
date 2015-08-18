require "lotus/validations"
require "reform/validation"

# Implements ::validates and friends, and #valid?.
module Reform::Form::Lotus
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
        @validations = ::Lotus::Validations::ValidationSet.new
      end

      def validates(*args)
        @validations.add(*args)
      end

      def call(fields, errors, form) # FIXME.
        private_errors = Reform::Form::Lotus::Errors.new # FIXME: damn, Lotus::Validator.validate does errors.clear.

        validator = ::Lotus::Validations::Validator.new(@validations, fields, private_errors)
        validator.validate

        # TODO: merge with AM.
        private_errors.each do |name, error| # TODO: handle with proper merge, or something. validator.errors is ALWAYS AM::Errors.
          errors.add(name, *error)
        end
      end
    end
  end

  class Errors
    extend Uber::Delegates

    def initialize(*args)
      @lotus_errors = Lotus::Validations::Errors.new(*args)
    end

    delegates :@lotus_errors, :clear, :add, :empty?

    def each(&block)
      @lotus_errors.instance_variable_get(:@errors).each(&block)
    end

    def merge!(errors, prefix)
      errors.each do |name, err|
        field = (prefix+[name]).join(".").to_sym

        next if @lotus_errors.for(field).any?

        @lotus_errors.add(field, *err) # TODO: use namespace feature in Lotus here!
      end
    end

    def messages
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
