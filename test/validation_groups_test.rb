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
    @errors ||= Reform::Form::Lotus::Errors.new
    results = {}

    _errors = Reform::Form::Lotus::Errors.new

    self.class.validation_groups.each do |name, v|
      group, options = v

      # validator = validator_for(group.validations)

      validator = Lotus::Validations::Validator.new(group.validations,
        @fields, _errors)

      puts "@@@@@ #{name.inspect}, #{_errors.inspect}"

      depends_on = options[:if]
      if depends_on.nil? or results[depends_on].empty?
        results[name] = validator.validate
      end

      @errors.merge! _errors, [] # FIXME: merge with result set.

      result &= _errors.empty?
    end

    result
  end
end

class ValidationGroupsTest < MiniTest::Spec
  Session = Struct.new(:username, :email, :password)
  Album = Struct.new(:name, :songs, :artist)
  Artist = Struct.new(:name)

  class SessionForm < Reform::Form
    include Reform::Form::Lotus

    include Validation

    property :username
    property :email
    property :password

    validation :default do
      validates :username, presence: true
      validates :email, presence: true
    end

    validation :email, if: :default do
      # validate :email_ok? # FIXME: implement that.
      validates :email, size: 3
    end

    validation :nested, if: :default do
      validates :password, presence: true, size: 1
    end
  end

  let (:form) { SessionForm.new(Session.new) }

  # valid.
  it do
    form.validate({username: "Helloween", email: "yep", password: "9"}).must_equal true
    form.errors.messages.inspect.must_equal "[]"
  end

  # invalid.
  it do
    form.validate({}).must_equal false
    form.errors.messages.inspect.must_equal %{["username", "email"]}
  end

  # partially invalid.
  # 2nd group fails
  it do
    form.validate(username: "Helloween", email: "yo").must_equal false
    form.errors.messages.inspect.must_equal %{["email"]}
  end
end