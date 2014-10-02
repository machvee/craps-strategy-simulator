class TrackingAccount < Account
  #
  # the tracking player making tracking bets doesn't 
  # use real money so don't credit or debit anything
  #
  def debit(amount); end
  def transfer_from(from_account, amount); end
end
