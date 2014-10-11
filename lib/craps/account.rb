class Account
  attr_reader   :balance

  attr_reader   :name
  attr_reader   :start_balance
  attr_reader   :hi_balance
  attr_reader   :lo_balance
  attr_reader   :markers

  #
  # maintains money.  allows credit, debit, transfer between accounts
  # and maintains active money, reserves, and markers.  Both House and
  # players should be able to use this, at least as a base class
  #
  def initialize(name, start_capital)
    @name = name
    @start_balance = start_capital
    reset
  end

  def reset
    @balance = start_balance
    @hi_balance = balance
    @lo_balance = balance
    @markers = []
  end

  def debit(amount)
    zero_check(amount)
    @balance -= amount
    hi_lo_check
  end

  def transfer_from(from_account, amount)
    from_account.debit(amount)
    @balance += amount
    hi_lo_check
  end

  def credit(from_account, amount)
    markers << {account: from_account, amount: amount, time: Time.now}
    transfer_from(from_account, amount)
  end

  def total_borrowed
    markers.inject(0) {|total, info| total += info[:amount]}
  end
  
  def inspect
    to_s
  end

  def to_s
    "#{name} balance: #{balance}"
  end

  private

  def zero_check(amount)
    raise "#{name} overdrawn ($#@balance remains)" if balance - amount < 0
  end

  def hi_lo_check
    @hi_balance = balance if balance > hi_balance
    @lo_balance = balance if balance < lo_balance
  end

end
