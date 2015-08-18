require "active_model"
require "reform/form/active_model/errors"
require "uber/delegates"

# NOTE: This module is unsupported from 2.2 onwards as it is impossible to write sane software with ActiveModel in an
# environment that is not 100% Rails conform. Feel free to open tickets on rails/rails but never ever ask me to fix
# anything in combination with ActiveModel. Thank you.
module Reform::Form::ActiveModel
  # AM::Validations for your form.
  #
  # Note: The preferred way for validations should be Veto::Validations, as ActiveModel::Validation's
  # implementation is old, very complex given that it needs to do a simple thing, is using
  # globals like @errors, and relies and more than 100 methods to be mixed into your form.
  #
  # What really sucks about AM:V, though, is how they infer the model_name. This always goes through
  # the object _class_ and makes it super hard to work with.
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
          # Hooray! Delegate translation back to Reform's Validator class which contains AM::Validations.
          delegates :active_model_sucks, :human_attribute_name, :lookup_ancestors, :i18n_scope # Rails 3.1.
          # this is a total hack. please DO NOT BUG ME with error reports because I18N didn't work or whatever. use the veto
          # validation backend instead which has a sane implementation or i18n.
          def active_model_sucks
             Class.new(Reform::Form::ActiveModel::Validations::Validator).tap { |v| v.form = self }
          end
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

      extend Uber::Delegates
      delegates :@validations, :validates, :validate, :validates_with, :validate_with

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

        # we need a reference to the form so AM's messed up I18N implementation can infer the "correct" model_name, etc.
        def form=(form)
          @form = form
        end

        def model_name
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
