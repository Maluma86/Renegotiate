require "test_helper"

class SupplierMailerTest < ActionMailer::TestCase
  test "invite_to_renegotiation" do
    mail = SupplierMailer.invite_to_renegotiation
    assert_equal "Invite to renegotiation", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end
