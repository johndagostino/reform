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

    def add(*args)
      @lotus_errors.add(*args)
    end
    def empty?(*args)
      @lotus_errors.empty?(*args)
    end

    def merge!(errors, prefix)
      errs = []

      @lotus_errors.instance_variable_get(:@errors).each do |name, err|
        field = (prefix+[name]).join(".")
        errs << [field, *err]
      end

      errs.each do |err|
        @lotus_errors.add(*err) # TODO: use namespace feature in Lotus here!
      end
      #   next if messages[field] and messages[field].include?(msg)
    end

    def inspect
      @errors.to_s
    end

    def messages
      @lotus_errors
    end

    def [](name)
      # puts "@@@ #{name  },#{object_id}@@ #{@errors[name].inspect}"
      @lotus_errors.instance_variable_get(:@errors)[name] || []
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
  end
end
