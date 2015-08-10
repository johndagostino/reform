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
