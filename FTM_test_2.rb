require_relative "FTM_ini"

File.basename(__FILE__) =~ /(\d+)\.rb$/
@sot.test_nr = $1

###############################################################################

jump_to(50, 'epoch 50')

@sl.h1 'Minting'

###

@sot.txt 'Mint unrestricted tokens'

@sot.own :mint_tokens, 1, @a[1], 50_000_000 * @E18
@sot.own :mint_tokens, 1, @a[11], 50_000_000 * @E18

accts, tokens = [], []
(2..6).each do |i|
  accts << @a[i]
  tokens << 10_000_000 * @E18
end
@sot.own :mint_tokens_multiple, 5, accts, tokens

@sot.exp :balance_of, @a[1], 50_000_000 * @E18, 50_000_000 * @E18
@sot.exp :balances_minted_by_type, [@a[1], 1], 50_000_000 * @E18, 50_000_000 * @E18
@sot.exp :balances_minted_by_type, [@a[1], 5], 0, 0

(2..6).each do |i|
  @sot.exp :balance_of, @a[i], 10_000_000 * @E18, 10_000_000 * @E18
  @sot.exp :balances_minted_by_type, [@a[i], 5], 10_000_000 * @E18, 10_000_000 * @E18
end

@sot.exp :balance_of, @a[11], 0, 0

@sot.exp :available_to_mint, 300_000_000 * @E18, -100_000_000 * @E18

@sot.do

###

@sot.txt 'Mint locked tokens - fail because we only have 5 slots'

accts = Array.new(6, @a[10])
tokens = Array.new(6, 10_000_000 * @E18)
terms = [200, 300, 400, 500, 600, 700]
@sot.own :mint_tokens_locked_multiple, 1, accts, tokens, terms
@sot.exp :balance_of, @a[10], 0, 0
@sot.do

###

@sot.txt 'Mint locked tokens'

@sot.own :mint_tokens_locked, 2, @a[10], 10_000_000 * @E18, 100

accts = Array.new(4, @a[10])
tokens = Array.new(4, 10_000_000 * @E18)
terms = [200, 300, 400, 500]
@sot.own :mint_tokens_locked_multiple, 3, accts, tokens, terms

@sot.exp :balance_of, @a[10], 50_000_000 * @E18, 50_000_000 * @E18
@sot.exp :locked_tokens, @a[10], 50_000_000 * @E18, 50_000_000 * @E18
@sot.exp :unlocked_tokens, @a[10], 0
@sot.exp :is_available_lock_slot, [@a[10], 500], true
@sot.exp :is_available_lock_slot, [@a[10], 600], false
@sot.exp :is_available_lock_slot, [@a[10], 700], false

@sot.exp :available_to_mint, 250_000_000 * @E18, -50_000_000 * @E18

@sot.do

###

jump_to(100, 'epoch 100')

@sot.txt 'Still no lock slot'
@sot.exp :is_available_lock_slot, [@a[10], 900], false
@sot.do

###

jump_to(101, 'epoch 101') # modifies locked tokens

@sot.txt 'Now we should have a lock slot'
@sot.exp :is_available_lock_slot, [@a[10], 600], true
@sot.exp :locked_tokens, @a[10], 40_000_000 * @E18, 0
@sot.do

###

@sot.txt 'Now we should have a single lock slot'

@sot.own :mint_tokens_locked, 2, @a[10], 20_000_000 * @E18, 800
@sot.own :mint_tokens_locked, 2, @a[10], 20_000_000 * @E18, 900

@sot.exp :balance_of, @a[10], 70_000_000 * @E18, 20_000_000 * @E18
@sot.exp :locked_tokens, @a[10], 60_000_000 * @E18, 20_000_000 * @E18
@sot.exp :unlocked_tokens, @a[10], nil, 0
@sot.exp :is_available_lock_slot, [@a[10], 900], false
@sot.exp :available_to_mint, 230_000_000 * @E18, -20_000_000 * @E18

@sot.do

###

jump_to(200, 'epoch 200')

@sot.txt 'Still no lock slot'
@sot.exp :unlocked_tokens, @a[10], nil, 0
@sot.exp :is_available_lock_slot, [@a[10], 900], false
@sot.do

jump_to(201, 'epoch 201') # again modifies unlocked

@sot.txt 'Now there is another lock slot'
@sot.exp :unlocked_tokens, @a[10], 20_000_000 * @E18, 0
@sot.exp :is_available_lock_slot, [@a[10], 900], true
@sot.exp :may_have_locked_tokens, @a[10], true
@sot.do

jump_to(901, 'epoch 901')

@sot.txt 'Now we should have nothing locked...'
@sot.exp :unlocked_tokens, @a[10], 70_000_000 * @E18, nil
@sot.exp :may_have_locked_tokens, @a[10], true
@sot.do


###############################################################################

@sot.dump
output_pp @sot.get_state(true), "state_#{@sot.test_nr}.txt"
