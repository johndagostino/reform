require "active_model"
require "reform/form/active_model/errors"
require "uber/delegates"

module Reform::Form::ActiveModel
  # AM::Validations for your form.
  #
  # Note: The preferred way for validations should be Lotus::Validations, as ActiveModel::Validation's
  # implementation is old, very complex given that it needs to do a simple thing, is using
  # globals like @errors, and relies and more than 100 methods to be mixed into your form.
  #
  # What really sucks about AM:V, though, is how they infer the model_name. This always goes through
  # the object _class_ and makes it super hard to work with.
  #
  # Implements ::validates and friends, and #valid?.
  #
  module Validations
    def self.included(includer)
      includer.instance_eval do
        extend ClassMethods
        include Reform::Form::ActiveModel
        # extend Uber::InheritableAttr
        # inheritable_attr :validator
        # self.validator = Class.new(Validator)

        class << self
          extend Uber::Delegates
          # delegates :validator, :validates, :validate, :validates_with, :validate_with

          # Hooray! Delegate translation back to Reform's Validator class which contains AM::Validations.
          # delegates :validator, :human_attribute_name, :lookup_ancestors, :i18n_scope # Rails 3.1.
        end
      end
    end

    def build_errors
      Reform::Contract::Errors.new(self)
    end

    module ClassMethods
      def validation_group_class
        Group
      end
    end


    # The concept of "composition" has still not arrived in Rails core and they rely on 400 methods being
    # available in one object. This is why we need to provide parts of the I18N API in the form.
    def read_attribute_for_validation(name)
      send(name)
    end


    class Group
      def initialize
        @validations = Class.new(Reform::Form::ActiveModel::Validations::Validator)
      end

      def validates(*args)
        @validations.validates(*args)
      end

      def call(fields, errors, form) # FIXME.
        validator = @validations.new(form)
        validator.valid?

        validator.errors.each do |name, error| # TODO: handle with proper merge, or something. validator.errors is ALWAYS AM::Errors.
          errors.add(name, error)
        end
      end
    end


    # Validators is the validatable object. On the class level, we define validations,
    # on instance, it exposes #valid?.
    class Validator
      # current i18n scope: :activemodel.
      include ActiveModel::Validations

      class << self
        extend Uber::Delegates

        def form=(form)
          puts "@@@@@ #{form.inspect} on #{self}"
          @form = form
        end

        def model_name
          puts "~~~ #{@form} on #{self}"
          return Reform::Form.model_name unless @form # for some reasons, AM:V asks Validator.model_name sometimes.
          @form.model_name
        end

        def clone
          Class.new(self)
        end
      end

      def initialize(form)
        @form = form
        self.class.form = form # one of the many reasons why i will drop support for AM::V in 2.1.
      end

      def method_missing(method_name, *args, &block)
        @form.send(method_name, *args, &block)
      end
    end
  end
end
