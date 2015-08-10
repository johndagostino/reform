require "lotus/validations"

# Implements ::validates and friends, and #valid?.
module Reform::Form::Lotus
  class Errors < Lotus::Validations::Errors
    def merge!(errors, prefix)
      errors.instance_variable_get(:@errors).each do |name, err|
        field = (prefix+[name]).join(".")
        add(field, *err) # TODO: use namespace feature in Lotus here!
      end
      #   next if messages[field] and messages[field].include?(msg)
    end

    def inspect
      @errors.keys.to_s
    end

    def messages
      self
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
    validator = validator_for
    validator.validate
  end

  def validator_for(validations=self.class.validations)
    Lotus::Validations::Validator.new(validations, @fields, errors)
  end
end
