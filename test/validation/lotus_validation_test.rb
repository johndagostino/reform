require "test_helper"
require "reform/form/lotus"

class ValidationGroupsTest < MiniTest::Spec
  Session = Struct.new(:username, :email, :password, :confirm_password)
  Album = Struct.new(:name, :songs, :artist)
  Artist = Struct.new(:name)

  class SessionForm < Reform::Form
    include Reform::Form::Lotus::Validations

    property :username
    property :email
    property :password
    property :confirm_password

    validation :default do
      validates :username, presence: true
      validates :email, presence: true
    end

    validation :email, if: :default do
      # validate :email_ok? # FIXME: implement that.
      validates :email, size: 3 # FIXME: two different errors, please!
    end

    validation :nested, if: :default do
      validates :password, presence: true, size: 1
    end

    validation :confirm, if: :default, after: :email do
      validates :confirm_password, size: 2
    end

    validation :accepted, if: :confirm do
      validates :confirm_password, inclusion: []
    end
  end

  let (:form) { SessionForm.new(Session.new) }

  # valid.
  it do
    form.validate({username: "Helloween", email: "yep", password: "9"}).must_equal true
    form.errors.messages.inspect.must_equal "{}"
  end

  # invalid.
  it do
    form.validate({}).must_equal false
    form.errors.messages.inspect.must_equal "{:username=>[\"username can't be blank\"], :email=>[\"email can't be blank\"]}"
  end

  # partially invalid.
  # 2nd group fails.
  it do
    form.validate(username: "Helloween", email: "yo", confirm_password:"").must_equal false
    form.errors.messages.inspect.must_equal "{:email=>[\"email is not proper size\"], :confirm_password=>[\"confirm_password is not proper size\"], :password=>[\"password can't be blank\"]}"
  end
  # 3rd group fails.
  it do
    form.validate(username: "Helloween", email: "yo!", confirm_password:"").must_equal false
    form.errors.messages.inspect.must_equal "{:confirm_password=>[\"confirm_password is not proper size\"], :password=>[\"password can't be blank\"]}"
  end
  # 4th group with after: fails.
  it do
    form.validate(username: "Helloween", email: "yo!", password: "", confirm_password: "9").must_equal false
    form.errors.messages.inspect.must_equal "{:confirm_password=>[\"confirm_password is not proper size\"], :password=>[\"password can't be blank\", \"password is not proper size\"]}"
  end


  describe "implicit :default group" do
    # implicit :default group.
    class LoginForm < Reform::Form
      include Reform::Form::Lotus::Validations


      property :username
      property :email
      property :password
      property :confirm_password

      validates :username, presence: true
      validates :email, presence: true
      validates :password, presence: true

      validation :after_default, if: :default do
        validates :confirm_password, presence: true
      end
    end

    let (:form) { LoginForm.new(Session.new) }

    # valid.
    it do
      form.validate({username: "Helloween", email: "yep", password: "9", confirm_password: 9}).must_equal true
      form.errors.messages.inspect.must_equal "{}"
    end

    # invalid, only :default run.
    it do
      form.validate({password: 9}).must_equal false
      form.errors.messages.inspect.must_equal "{:username=>[\"username can't be blank\"], :email=>[\"email can't be blank\"]}"
    end

    # partially invalid.
    # 2nd group fails.
    it do
      form.validate(password: 9).must_equal false
      form.errors.messages.inspect.must_equal "{:username=>[\"username can't be blank\"], :email=>[\"email can't be blank\"]}"
    end
  end


  # describe "same-named group" do
  #   class OverwritingForm < Reform::Form
  #     include Reform::Form::Lotus::Validations

  #     property :username
  #     property :email

  #     validation :email do
  #       validates :email, presence: true # is not considered, but overwritten.
  #     end

  #     validation :email do # just another group.
  #       validates :username, presence: true
  #     end
  #   end

  #   let (:form) { OverwritingForm.new(Session.new) }

  #   # valid.
  #   it do
  #     form.validate({username: "Helloween"}).must_equal true
  #   end

  #   # invalid.
  #   it "whoo" do
  #     form.validate({}).must_equal false
  #     form.errors.messages.inspect.must_equal "{:username=>[\"username can't be blank\"]}"
  #   end
  # end


# TODO: test multiple error messages for 1 property.

  describe "inherit: true in same group" do
    class InheritSameGroupForm < Reform::Form
      include Reform::Form::Lotus::Validations

      property :username
      property :email

      validation :email do
        validates :email, presence: true
      end

      validation :email, inherit: true do # extends the above.
        validates :username, presence: true
      end
    end

    let (:form) { InheritSameGroupForm.new(Session.new) }

    # valid.
    it do
      form.validate({username: "Helloween", email: 9}).must_equal true
    end

    # invalid.
    it do
      form.validate({}).must_equal false
      form.errors.messages.inspect.must_equal "{:email=>[\"email can't be blank\"], :username=>[\"username can't be blank\"]}"
    end
  end


  describe "if: with lambda" do
    class IfWithLambdaForm < Reform::Form
      include Reform::Form::Lotus::Validations # ::build_errors.

      property :username
      property :email
      property :password

      validation :email do
        validates :email, presence: true
      end

      # run this is :email group is true.
      validation :after_email, if: lambda { |results| results[:email]==true } do # extends the above.
        validates :username, presence: true
      end

      # block gets evaled in form instance context.
      validation :password, if: lambda { |results| email == "john@trb.org" } do
        validates :password, presence: true
      end
    end

    let (:form) { IfWithLambdaForm.new(Session.new) }

    # valid.
    it do
      form.validate({username: "Strung Out", email: 9}).must_equal true
    end

    # invalid.
    it do
      form.validate({email: 9}).must_equal false
      form.errors.messages.inspect.must_equal "{:username=>[\"username can't be blank\"]}"
    end
  end


  describe "multiple errors for property" do
    class MultipleErrorsForPropertyForm < Reform::Form
      include Reform::Form::Lotus::Validations

      property :username
      validates :username, presence: true, size: 2..3
    end

    let (:form) { MultipleErrorsForPropertyForm.new(Session.new) }

    # valid.
    it do
      form.validate({username: ""}).must_equal false
      form.errors.messages.inspect.must_equal "{:username=>[\"username can't be blank\", \"username is not proper size\"]}"
    end
  end
end