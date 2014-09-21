class Table

  attr_reader    :name
  attr_reader    :bet_boxes
  attr_reader    :dice_bet_stats   # based on outcome of dice
  attr_reader    :player_bet_stats # rolled up from player bet_stats
  attr_reader    :table_state
  attr_reader    :config
  attr_reader    :dice_tray
  attr_reader    :players
  attr_reader    :shooter # one of the above players or nil
  attr_reader    :house   # dollar amount of chips the house has
  attr_accessor  :quiet_table # not verbose about all actions

  delegate :on?, :off?,        to: :table_state
  delegate :dice,              to: :shooter
  delegate :min_bet, :max_bet, to: :config

  #
  # NO_NUMBER_BETS and NUMBER_BETS are all the types of bets on the table.  We
  # will create a BetBox for each NO_NUMBER_BET, and mulitple numbered BetBox for the
  # NUMBER_BETS
  #
  NO_NUMBER_BETS = [
    AceDeuceBet,
    AcesBet,
    AnyCrapsBet,
    AnySevenBet,
    CeBet,
    ComeOutBet,
    ElevenBet,
    FieldBet,
    PassLineBet,
    TwelveBet
  ]

  NUMBER_BETS = [
    ComeBet,
    ComeOddsBet,
    HardwaysBet,
    PassOddsBet,
    PassLinePointBet,
    PlaceBet
  ]

  DEFAULT_OPTIONS = {
    config:      TableConfig.new,
    die_seeder:  nil,
    quiet_table: false
  }

  BET_STATS_HEADERS = {
    count:         'total',
    won:           'won',
    win_streak:    'win streak',
    lost:          'lost',
    losing_streak: 'lost streak'
  }


  def initialize(name="craps table", options = DEFAULT_OPTIONS)
    @name = name
    @config = options[:config]

    @table_state = TableState.new(self)
    table_state.table_off

    @house = config.house_bank
    @quiet_table = options[:quiet_table]

    @dice_tray = DiceTray.new(self, options[:die_seeder])

    @dice_bet_stats = StatsCollection.new("dice outcome")
    @player_bet_stats = CountersStatsCollection.new(
                          "player bet results",
                          counters: [:made, :won, :lost]
                        )

    create_bet_boxes

    @players = []
    @shooter = Shooter.new(self)
  end

  def last_roll
    shooter.dice.value
  end

  def total_rolls
    shooter.total_rolls
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
      raise "no players" unless players_ready?
      players_make_your_bets
      raise "place your bets" unless at_least_one_bet_made?
      shooter_rolls
      settle_bets
      table_state.update
    end
    return
  end

  def players_make_your_bets
    players.each do |p|
      p.play_strategy
    end
  end

  def play_points(number_of_points, quiet_option=quiet_table)
    #
    # roll as many times from as many shooters as it takes
    # to make and end number_of_points points
    #
    start_points = point_outcomes
    while (point_outcomes - start_points < number_of_points)
      play(quiet_option)
    end
    return
  end

  def new_player(name, start_amount)
    Player.new(name, self, start_amount).tap do |p|
      @players << p
    end
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
    bet_boxes.each do |bet_box|
      bet_box.settle_player_bets do |player_bet, outcome, amount|
        case outcome
          when CrapsBet::WIN
            status "#{player_bet.player.name} wins $#{amount} on #{player_bet}"
            house_debit(amount)

          when CrapsBet::LOSE
            status "#{player_bet.player.name} loses $#{amount} on #{player_bet}"
            house_credit(amount)

          when CrapsBet::RETURN
            status "#{player_bet.player.name} returned $#{amount} for #{player_bet}"
        end
      end
    end
  end

  def at_least_one_bet_made?
    players.any? {|p| p.bets.length > 0}
  end

  def reset_stats
    shooter.reset_stats
    dice_bet_stats.reset
    player_bet_stats.reset
  end

  def house_credit(amount)
    # the sound of a player losing a bet
    @house += amount
  end

  def house_debit(amount)
    @house -= amount
  end

  def shooter_rolls
    shooter.set
    shooter.roll
    announce_roll
  end

  def status(str)
    puts(str) unless quiet_table
  end

  def announce_roll
    status '%d: %s rolls: %2d %s %s' %
      [shooter.dice.num_rolls,
       shooter.player.name,
       last_roll,
       shooter.dice.inspect,
       table_state.stickman_calls_roll]
  end

  def find_bet_box(bet_short_name, number)
    bet_boxes.find {|bet| bet.short_name == bet_short_name && bet.number == number} ||
      raise("#{bet_short_name}%s isn't a valid bet" % (number.nil? ? '' : " #{number}"))
  end

  def inspect
    puts name unless name.nil?
    puts "ON (point is #{table_state.point})" if on? 
    puts "OFF" if off? 
    puts "rolls: #{total_rolls}"
    dice_bet_stats.print(BET_STATS_HEADERS)
  end

  private

  def create_bet_boxes
    @bet_boxes = []
    NO_NUMBER_BETS.each do |bet_class|
      craps_bet = bet_class.new(self)
      @bet_boxes << BetBox.new(self, craps_bet)
    end

    NUMBER_BETS.each do |bet_class|
      craps_bets = bet_class.gen_number_bets(self)
      @bet_boxes += craps_bets.map {|b| BetBox.new(self, b)}
    end
  end

  def point_outcomes
    dice_bet_stats.pass_point.count # total won and lost
  end

  def quietly?(option)
    save_state = quiet_table
    @quiet_table = option
    yield
    @quiet_table = save_state
    return
  end
end
