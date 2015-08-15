require "test_helper"
require "reform/form/lotus"

class ValidationGroupsTest < MiniTest::Spec
  Session = Struct.new(:username, :email, :password, :confirm_password)
  Album = Struct.new(:name, :songs, :artist)
  Artist = Struct.new(:name)

  class SessionForm < Reform::Form
    include Reform::Form::Lotus

    include Validation

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
      validates :email, size: 3
    end

    validation :nested, if: :default do
      validates :password, presence: true, size: 1
    end

    validation :confirm, if: :default, after: :email do
      validates :confirm_password, size: 2
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
    form.errors.messages.inspect.must_equal %{["username", "email"]}
  end

  # partially invalid.
  # 2nd group fails.
  it do
    form.validate(username: "Helloween", email: "yo").must_equal false
    form.errors.messages.inspect.must_equal %{["email"]}
  end
  # 3rd group fails.
  it do
    form.validate(username: "Helloween", email: "yo!").must_equal false
    form.errors.messages.inspect.must_equal %{["password"]}
  end
  # 4th group with after: fails.
  it do
    form.validate(username: "Helloween", email: "yo!", password: "", confirm_password: "9").must_equal false
    form.errors.messages.inspect.must_equal %{["confirm_password"]}
  end


  describe "implicit :default group" do
    # implicit :default group.
    class LoginForm < Reform::Form
      include Reform::Form::Lotus

      include Validation

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

    # invalid.
    it do
      form.validate({password: 9}).must_equal false
      form.errors.messages.inspect.must_equal %{["username", "email"]}
    end

    # partially invalid.
    # 2nd group fails.
    it "bl" do
      form.validate(password: 9).must_equal false
      form.errors.messages.inspect.must_equal "{:username=>[\"username can't be blank\"], :email=>[\"email can't be blank\"]}"
    end
  end
end