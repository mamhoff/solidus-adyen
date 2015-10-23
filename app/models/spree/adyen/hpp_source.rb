# This models the response that is received after a user is redirected from the
# Adyen Hosted Payment Pages. It's used as the the source for the Spree::Payment
# and keeps track of the messages received from the notifications end point.
#
# Attributes defined are dervived from the docs:
# https://docs.adyen.com/display/TD/HPP+payment+response
#
# Information about when certain action are valid:
# https://docs.adyen.com/display/TD/HPP+modifications
class Spree::Adyen::HppSource < ActiveRecord::Base
  # support updates from capital-cased responses, which is what adyen gives us
  alias_attribute :authResult, :auth_result
  alias_attribute :pspReference, :psp_reference
  alias_attribute :merchantReference, :merchant_reference
  alias_attribute :skinCode, :skin_code
  alias_attribute :merchantSig, :merchant_sig
  alias_attribute :paymentMethod, :payment_method
  alias_attribute :shopperLocale, :shopper_locale
  alias_attribute :merchantReturnData, :merchant_return_data

  belongs_to :order, class_name: 'Spree::Order',
    primary_key: :number,
    foreign_key: :merchant_reference

  has_one :payment, class_name: 'Spree::Payment', as: :source

  # FIXME should change this to find the auth notification by order number, then
  # all notification that have a original ref that matches it's psp
  has_many :notifications,
    class_name: 'AdyenNotification',
    foreign_key: :merchant_reference,
    primary_key: :merchant_reference

  def can_adyen_hpp_capture? payment
    payment.uncaptured_amount != 0.0
  end

  def actions
    if auth_notification
      auth_notification.
        actions.
        map { |action| "adyen_hpp_#{action}" }
    else
      []
    end
  end

  private
  def auth_notification
    self.notifications.processed.authorisation.last
  end
end
