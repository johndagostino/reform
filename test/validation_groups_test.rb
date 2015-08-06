require "test_helper"
require "reform/form/lotus"

module Reform::Form::Validation
  # DSL object wrapping the ValidationSet.
  class Group
    def initialize
      @validations = Lotus::Validations::ValidationSet.new
    end

    def validates(*args)
      @validations.add(*args)
    end

    attr_reader :validations
  end

  module ClassMethods
    def validation(name, options={}, &block)
      @groups ||= {}
      @groups[name] = [group = Group.new, options]
      group.instance_exec(&block)
    end

    def validation_groups
      @groups
    end


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

  def self.included(includer)
    includer.extend(ClassMethods)
  end

  def valid?
    result = true

    self.class.validation_groups.each do |name, v|
      group, options = v

      validator = validator_for(group.validations)
      errs = validator.validate
      puts "@@@@@ #{result.inspect}"

      result &= errs.empty?

      result
    end
  end
end

class ValidationGroupsTest < MiniTest::Spec
  Session = Struct.new(:username, :email)
  Album = Struct.new(:name, :songs, :artist)
  Artist = Struct.new(:name)

  class SessionForm < Reform::Form
    include Reform::Form::Lotus

    include Validation

    property :username
    property :email

    validation :default do
      validates :username, presence: true
      validates :email, presence: true
    end

    validation :email, if: :default do
      # validate :email_ok? # FIXME: implement that.
      validates :email, size: 20
    end
  end

  let (:form) { SessionForm.new(Session.new) }

  # valid
  it do
    form.validate({}).must_equal false
    form.errors.messages.inspect.must_equal "{}"
  end
end