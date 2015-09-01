require "test_helper"

class SetterTest < BaseTest
  class Form < Reform::Form
    property :released_at, setter: -> (value, args) { self.released_at = Time.parse(value) }
  end

  subject do
    Form.new(album)
  end

  let (:album) {
    OpenStruct.new(released_at: "31/03/1981")
  }

  it { subject.released_at.must_equal Time.parse("31/03/1981") }
end
