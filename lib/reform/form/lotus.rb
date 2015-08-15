require "lotus/validations"

# Implements ::validates and friends, and #valid?.
module Reform::Form::Lotus
  class Errors #< Lotus::Validations::Errors
    def initialize(*args)
      @lotus_errors = Lotus::Validations::Errors.new(*args)
    end

    def clear
      @lotus_errors.clear
    end
    def each(&block)
      @lotus_errors.each(&block)
    end

    def add(*args)
      @lotus_errors.add(*args)
    end
    def empty?(*args)
      @lotus_errors.empty?(*args)
    end

    def merge!(errors, prefix)
      errs = []

      errors.instance_variable_get(:@lotus_errors).instance_variable_get(:@errors).each do |name, err|
        # name = err.attribute

        field = (prefix+[name]).join(".")
        errs << [field, *err]
      end

      errs.each do |err|
        @lotus_errors.add(err.first, err.last) # TODO: use namespace feature in Lotus here!
      end
      #   next if messages[field] and messages[field].include?(msg)
    end

    # def inspect
    #   @errors.to_s
    # end

    def messages

      errors = {}
      @lotus_errors.instance_variable_get(:@errors).each do |name, err|
        errors[name] ||= []
        errors[name] += err.map(&:to_s)
      end
      errors
    end

    # needed in simple_form, etc.
    # FIXME: test!
    def [](name)
      @lotus_errors.for(name)
    end
  end


  def self.included(base)
    # base.send(:include, Lotus::Validations)
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
    validator = Lotus::Validations::Validator.new(self.class.validations, @fields, errors)
    validator.validate
    # TODO: shouldn't we return true/false here?
  end
end
