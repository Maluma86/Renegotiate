class SupplierMailer < ApplicationMailer
  default from: "no-reply@renegotiate.com"

  # ← define a plain argument here
  def invite_to_renegotiation(renegotiation_id)
    @renegotiation = Renegotiation.find(renegotiation_id)
    @supplier      = @renegotiation.product.supplier
    @buyer         = @renegotiation.buyer

    mail(
      to:      @supplier.email,
      subject: "Invitation to renew contract for #{@renegotiation.product.name} with #{@buyer.company_name}"
    )
  end
end
