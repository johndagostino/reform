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

  # Set of Validation::Group objects.
  # This implements adding, iterating, and finding groups, including "inheritance" and insertions.
  class Groups < Array
    def add(name, options)
      if options[:inherit]
        return self[name] if self[name]
      end

      i = index_for(options)

      self.insert(i, [name, group = Group.new, options])
      group
    end

    def index_for(options)
      return find_index { |el| el.first == options[:after] } + 1 if options[:after]
      size # default index: append.
    end

    def [](name)
      cfg = find { |cfg| cfg.first == name }
      return unless cfg
      cfg[1]
    end
  end

  module ClassMethods
    def validation(name, options={}, &block)
      # if options[:inherit]

      # else
        group = validation_groups.add(name, options)
      # end

      group.instance_exec(&block)
    end

    def validation_groups
      @groups ||= Groups.new # TODO: inheritable_attr with Inheritable::Hash
    end


    def validates(name, options)
      validation(:default, inherit: true) { validates name, options }
    end

    def validate(name, *)
      # DISCUSS: lotus does not support that?
      # validations.add(name, options)
    end
  end

  def self.included(includer)
    includer.extend(ClassMethods)
  end

  def valid?
    result = true
    results = {}

    self.class.validation_groups.each do |cfg|
      name, group, options = cfg

      # validator = validator_for(group.validations)

      validator = Lotus::Validations::Validator.new(group.validations,
        @fields, errors)

      puts "@@@@@ #{name.inspect}, #{_errors.inspect}"

      depends_on = options[:if]
      if depends_on.nil? or results[depends_on].empty?
        results[name] = validator.validate
      end

      result &= _errors.empty?
    end

    result
  end
end
