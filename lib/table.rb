class Table
  attr_reader    :name
  attr_reader    :table_bets
  attr_reader    :bet_stats
  attr_reader    :table_state
  attr_reader    :config
  attr_reader    :dice_tray
  attr_reader    :players
  attr_reader    :shooter # one of the above players or nil
  attr_reader    :house   # dollar amount of chips the house has
  attr_accessor  :quiet_table # not verbose about all actions

  delegate :on?, :off?, to: :table_state
  delegate :dice, to: :shooter
  delegate :min_bet, :max_bet, to: :config

  DEFAULT_OPTIONS = {
    config:      TableConfig.new,
    die_seeder:  nil,
    quiet_table: false
  }

  BET_STATS_HEADERS = {
    master_count: 'total',
    occurred: 'won',
    consec_occurred: 'consec won',
    did_not_occur: 'lost',
    consec_did_not_occur: 'consec lost'
  }


  def initialize(name="craps table", options = DEFAULT_OPTIONS)
    @name = name
    @config = options[:config]

    @table_state = TableState.new(self)
    table_state.table_off

    @house = config.house_bank
    @quiet_table = options[:quiet_table]

    @dice_tray = DiceTray.new(self, options[:die_seeder])

    @bet_stats = TableStatsCollection.new("bet result", self)
    create_table_bets

    @players = []
    @shooter = Shooter.new(self)
  end

  def last_roll
    dice.value
  end

  def max_odds(number)
    config.max_odds(number)
  end

  def play(quiet_option=quiet_table)
    #
    # one roll of the dice, and the outcomes
    #
    quietly?(quiet_option) do
      # 1. shooter rolls dice
      # 2. set table_state if on
      # 3. table pay players on winning bets, takes losing bets
      # 4. if 7-out, shooter will return_dice
      #
      shooter_rolls
      settle_bets
      table_state.update
    end
    return
  end

  def play_points(number_of_points, quiet_option=quiet_table)
    #
    # roll as many times from as many shooters as it takes
    # to make and end number_of_points points
    #
    start_points = bet_stats.points
    while (bet_stats.points - start_points < number_of_points)
      play(quiet_option)
    end
    #
    # play until points_made or seven_outs
    #
    start_seven_out = bet_stats.seven_outs
    start_points_made = bet_stats.points_made
    while(bet_stats.seven_outs == start_seven_out &&
          bet_stats.points_made == start_points_made)
      play(quiet_option)
    end
    return
  end

  def new_player(name, start_amount)
    p = Player.new(name, self, start_amount)
    @players << p
    p # good luck
  end

  def find_player(name)
    players.find {|p| p.name == name}
  end

  def players_ready?
    #
    # return true if one or more @players are at the table and want to bet, else false
    #
    @players.each do |player|
      if player.out?
        player.leave_table
        players.delete(player)
      end
    end
    return !players.empty?
  end

  def settle_bets
    all_bets do |player_bet|
      player = player_bet.player
      table_bet = player_bet.table_bet

      outcome = player_bet.determine_outcome

      case outcome
        when TableBet::Outcome::RETURN
          #
          # 1. player moves bet amount from wagers to rail
          # 2. player removes bet
          #
          player.wagers_to_rail(player_bet.amount)
          player.remove_bet(player_bet)
          status "#{player.name} returned #{player_bet.amount} for #{player_bet}"
        when TableBet::Outcome::WIN
          #
          # 1. table credits player rails with winnings amount
          # 2. bet stays in place
          #
          pay_this, for_every = config.payoff_odds(table_bet, player_bet.number)
          winnings = (player_bet.amount/for_every) * pay_this
          debit(winnings)
          player.to_rail(winnings)
          status "#{player.name} wins $#{winnings} on #{player_bet}"
          player.take_down(player_bet) unless table_bet.bet_remains_after_win?
        when TableBet::Outcome::LOSE
          #
          # table takes bet amount from player's wagers to house
          # player removes bet
          #
          credit(player_bet.amount)
          player.loses(player_bet)
          status "#{player.name} loses $#{player_bet.amount} on #{player_bet}"
        when TableBet::Outcome::NONE
          # bet stays in place
      end
    end
  end

  def at_least_one_bet_made?
    players.any? {|p| p.bets.length > 0}
  end

  def all_bets
    players.each do |player|
       player.bets.each do |player_bet|
         yield player_bet
       end
    end
  end

  def reset_stats
    shooter.reset_stats
    bet_stats.reset
  end

  def credit(amount)
    # the sound of a player losing a bet
    @house += amount
  end

  def debit(amount)
    @house -= amount
  end

  def shooter_rolls
    shooter.set
    raise "place your bets" unless at_least_one_bet_made?
    shooter.roll
    announce_roll
  end

  def status(str)
    puts(str) unless quiet_table
  end

  def announce_roll
    status '%d: %s rolls: %2d %s %s' %
      [dice.num_rolls,
       shooter.player.name,
       last_roll,
       dice.inspect,
       table_state.stickman_calls_roll]
  end

  def find_table_bet(bet_class, number)
    table_bets.find {|bet| bet.class == bet_class && bet.number == number}
  end

  def inspect
    puts name unless name.nil?
    puts "ON (point is #{table_state.point})" if on? 
    puts "OFF" if off? 
    puts "total rolls: #{shooter.roll_stats.total_rolls}\n"
    bet_stats.print(BET_STATS_HEADERS)
  end

  private

  def create_table_bets
    @table_bets = []
    @table_bets << PassLineBet.new(self)
    @table_bets << ComeOutBet.new(self)
    @table_bets << CeBet.new(self)
    @table_bets << FieldBet.new(self)
    [PassOddsBet, ComeBet, ComeOddsBet, PlaceBet, HardwaysBet].each do |bet_class|
      @table_bets += bet_class.gen_number_bets(self)
    end
  end

  def quietly?(option)
    save_state = quiet_table
    @quiet_table = option
    yield
    @quiet_table = save_state
    return
  end

end
