require_relative "FTM_ini"

File.basename(__FILE__) =~ /(\d+)\.rb$/
@sot.test_nr = $1

###############################################################################

jump_to(50, 'epoch 50')

@date_limit = @sot.var :date_limit
puts @date_limit

_date_main_start    = @date_limit - 20*24*3600
_date_main_end      = @date_limit - 10*24*3600

###############################################################################


@sl.h1 'Reset dates'

@sot.txt 'Change dates'

@sot.own :set_date_main_end, _date_main_end
@sot.own :set_date_main_start, _date_main_start
@sot.exp :date_main_start, _date_main_start
@sot.exp :date_main_end, _date_main_end
@sot.do

###############################################################################

@sl.h1 'Before main sale'


###

@sot.txt 'Early contribution (fail)'
@sot.snd @k[1], 100
@sot.exp :balance_of, @a[1], nil, 0
@sot.exp :get_balance, @a[1], nil, 0
@sot.do

###

@sot.txt 'Token transfer attempt fails'
@sot.own :make_tradeable
@sot.add :transfer, @k[1], @a[19], 1 * @E18
@sot.exp :balance_of,  @a[1], nil, 0
@sot.exp :balance_of, @a[19], nil, 0
@sot.do

###

@sot.txt 'Modify tokens per ETH - ok'
@sot.own :update_tokens_per_eth, 10_000
@sot.exp :tokens_per_eth, 10_000, -10_000
@sot.do


###############################################################################

@sot.dump
output_pp @sot.get_state(true), "state_#{@sot.test_nr}.txt"
