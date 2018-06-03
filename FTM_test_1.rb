require_relative "FTM_ini"

File.basename(__FILE__) =~ /(\d+)\.rb$/
@sot.test_nr = $1

###############################################################################

@sl.h1 'Preliminary actions'

###

@sot.txt 'Set wallet and admin account'

@sot.own :set_wallet, @wallet_account
@sot.own :add_admin,  @admin_account

@sot.exp :wallet,   @sot.strip0x(@wallet_account)
@sot.exp :is_admin, @admin_account, true

@sot.do

###############################################################################

@sl.h1 'Some whitelisting'

###

@sot.txt 'Some whitelisting'

@sot.own :add_to_whitelist, @a[1]

a = []
(2..10).each do |i|
  a << @a[i]
end

@sot.own :add_to_whitelist_multiple, a

(1..10).each do |i|
  @sot.exp :whitelist, @a[i], true
end

@sot.exp :whitelist, @a[11], false

@sot.exp :number_whitelisted, 10, 10

@sot.do

###

@sot.txt 'Modify tokens per ETH - ok'
@sot.own :update_tokens_per_eth, 20_000
@sot.exp :tokens_per_eth, 20_000, 10_000
@sot.do

###############################################################################

@sl.h1 'Date changes'

###

@sot.txt 'Change dates - ok'

@sot.own :set_date_main_start, 100
@sot.own :set_date_main_end, 150
@sot.own :set_date_main_end, 200

@sot.exp :date_main_start, 100
@sot.exp :date_main_end, 200

@sot.do

###

@sot.txt 'Wrong date order - too late - fail'
@sot.own :set_date_main_start, 200
@sot.exp :date_main_start, 100
@sot.do

###

@sot.txt 'Wrong date order - too early - fail'
@sot.own :set_date_main_end, 100
@sot.exp :date_main_end, 200
@sot.do

###

jump_to(50, 'epoch 50')

@sot.txt 'Change presale - fail: before now'
@sot.own :set_date_main_start, 20
@sot.exp :date_main_start, 100, 0
@sot.do

###

jump_to(150, 'epoch 150')

@sot.txt 'Change presale - fail: date passed'
@sot.own :set_date_main_start, 120
@sot.exp :date_main_start, 100, 0
@sot.do

###

@date_limit = @sot.var :date_limit

@sot.txt 'Change some dates - ok'
@sot.own :set_date_main_start, @date_limit # fail, before end
@sot.own :set_date_main_end, @date_limit + 1 # fail, after limit

@sot.exp :date_main_start, 100
@sot.exp :date_main_end, 200
@sot.do





###############################################################################

@sot.dump
output_pp @sot.get_state(true), "state_#{@sot.test_nr}.txt"
