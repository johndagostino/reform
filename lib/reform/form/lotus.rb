require "lotus/validations"
require "reform/form/validation/group"

# Implements ::validates and friends, and #valid?.
module Reform::Form::Lotus
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


  def self.included(base)
    base.extend(ClassMethods)
  end


  module ClassMethods
    def validates(name, options)
      validations.add(name, options)
    end

    def validate(name, *)
      # DISCUSS: lotus does not support that?
      # validations.add(name, options)
    end

    def validations
      @validations ||= Lotus::Validations::ValidationSet.new
    end
  end

  def build_errors
    Errors.new
  end

private

  def valid?
    # DISCUSS: by using @fields here, we avoid setters being called. win!
    validator = validator_for
    validator.validate
    # TODO: shouldn't we return true/false here?
  end

  def validator_for(validations=self.class.validations)
    Lotus::Validations::Validator.new(validations, @fields, errors)
  end
end
